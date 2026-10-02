import 'dart:convert';

import 'package:dio/dio.dart';

import '../error/failures.dart';
import 'cache_keys.dart';
import 'http_cache_store.dart';
import 'offline_status.dart';
import 'pending_overlay.dart';

/// Marque une requête que [RetryInterceptor] ne doit pas rejouer.
const noRetryExtra = 'no_retry';

/// Date du cache d'une réponse servie hors ligne, dans `Response.extra`.
const offlineCachedAtExtra = 'offline_cached_at';

const _keysExtra = 'offline_cache_keys';

/// Sert les lectures depuis le cache quand le réseau manque.
///
/// Réseau d'abord : une lecture part normalement, et sa réponse est gardée.
/// Le cache ne répond que si l'appareil est hors ligne, ou si la requête
/// échoue faute de réseau — un Wi-Fi sans Internet annonce une connexion, et
/// seul l'échec de la requête le révèle.
///
/// Placé **en tête** des intercepteurs : hors ligne, il répond avant que
/// l'intercepteur de connectivité ne rejette la requête.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({
    required HttpCacheStore store,
    required OfflineStatus status,
    required Future<bool> Function() isOffline,
    required Future<String?> Function() sessionOwner,
    Future<OverlaySnapshot> Function()? pendingSnapshot,
    this.onlineConnectTimeout = const Duration(seconds: 8),
  }) : _store = store,
       _status = status,
       _isOffline = isOffline,
       _sessionOwner = sessionOwner,
       _pendingSnapshot = pendingSnapshot;

  final HttpCacheStore _store;
  final OfflineStatus _status;
  final Future<bool> Function() _isOffline;
  final Future<String?> Function() _sessionOwner;

  /// Saisies en file à superposer à chaque lecture servie, du réseau comme du
  /// cache : sans elles, une liste rechargée après une saisie hors ligne ne la
  /// montrerait pas.
  final Future<OverlaySnapshot> Function()? _pendingSnapshot;

  /// Délai d'établissement de la connexion pour une lecture mise en cache.
  ///
  /// Raccourci : un Wi-Fi sans Internet laisse la connexion pendre, et
  /// l'écran restait près d'une minute sur son squelette avant le repli.
  /// Une réponse lente mais établie garde, elle, le délai de réception du
  /// client.
  final Duration onlineConnectTimeout;

  /// Lectures jamais servies depuis le cache.
  ///
  /// L'authentification et l'abonnement disent l'état du compte à l'instant,
  /// et l'aperçu d'un départ anticipé chiffre l'heure présente : rejouer une
  /// réponse ancienne afficherait un état qui n'existe plus.
  static final _excluded = RegExp(
    r'/auth/|/subscription|/check-out/preview|/reports',
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isCacheable(options)) return handler.next(options);

    final owner = await _sessionOwner();
    if (owner == null) return handler.next(options);

    final keys = cacheKeysFor(
      owner: owner,
      path: options.uri.path,
      query: options.queryParameters,
    );
    options.extra[_keysExtra] = keys;

    if (await _isOffline()) {
      final cached = await _readOrNull(keys);
      if (cached != null) {
        return handler.resolve(await _fromCache(options, cached));
      }
      return handler.reject(_unavailable(options));
    }

    options.connectTimeout = onlineConnectTimeout;
    // Le cache prend le relais d'un échec réseau : trois rejeux ne feraient
    // que repousser l'affichage de ce que l'appareil sait déjà montrer.
    options.extra[noRetryExtra] = true;
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final keys = response.requestOptions.extra[_keysExtra];
    final status = response.statusCode ?? 0;

    if (keys is CacheKeys &&
        status >= 200 &&
        status < 300 &&
        !response.extra.containsKey(offlineCachedAtExtra)) {
      _status.markFresh();
      try {
        await _store.write(
          keys,
          path: response.requestOptions.uri.path,
          body: jsonEncode(response.data),
        );
      } catch (_) {
        // Un cache qui ne s'écrit pas — disque plein — ne doit pas faire
        // échouer une lecture réussie.
      }

      // Après l'écriture : le cache garde la réponse du serveur telle quelle,
      // la superposition ne vaut que pour l'affichage.
      response.data = await _overlay(response.requestOptions, response.data);
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final keys = err.requestOptions.extra[_keysExtra];
    if (keys is! CacheKeys || !isNetworkFailure(err)) {
      return handler.next(err);
    }

    final cached = await _readOrNull(keys);
    if (cached != null) {
      return handler.resolve(await _fromCache(err.requestOptions, cached));
    }
    handler.next(_unavailable(err.requestOptions));
  }

  /// L'échec vient-il du transport et non d'une réponse du serveur ?
  ///
  /// Un 4xx n'est jamais masqué par le cache : le serveur a répondu, et sa
  /// réponse — session expirée, accès retiré — doit atteindre l'écran. Un 5xx
  /// est traité comme une panne : l'afficher plutôt que les dernières données
  /// connues ne servirait à rien.
  static bool isNetworkFailure(DioException err) {
    if (err.error is AppFailure) {
      return (err.error! as AppFailure).statusCode == null &&
          err.type == DioExceptionType.connectionError;
    }
    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.unknown => true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }

  bool _isCacheable(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' &&
      options.responseType == ResponseType.json &&
      !_excluded.hasMatch(options.uri.path);

  Future<CachedBody?> _readOrNull(CacheKeys keys) async {
    try {
      return await _store.read(keys);
    } catch (_) {
      return null;
    }
  }

  Future<Response<dynamic>> _fromCache(
    RequestOptions options,
    CachedBody cached,
  ) async {
    _status.markCached(cached.cachedAt);
    return Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: await _overlay(options, jsonDecode(cached.body)),
      extra: {offlineCachedAtExtra: cached.cachedAt},
    );
  }

  Future<dynamic> _overlay(RequestOptions options, dynamic data) async {
    final load = _pendingSnapshot;
    if (load == null) return data;
    try {
      return applyOverlay(
        path: options.uri.path,
        query: options.queryParameters,
        data: data,
        snapshot: await load(),
      );
    } catch (_) {
      // Une file illisible ne doit pas empêcher d'afficher la lecture.
      return data;
    }
  }

  DioException _unavailable(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
    error: AppFailure.offlineUnavailable(),
  );
}
