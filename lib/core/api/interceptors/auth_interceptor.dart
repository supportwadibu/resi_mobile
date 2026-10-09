import 'package:dio/dio.dart';
import '../../error/failures.dart';
import '../../session/session_role.dart';
import '../../storage/app_database.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage,
    this._sessionRole,
    this._database, {
    Dio Function(String baseUrl)? refreshClient,
  }) : _refreshClient =
           refreshClient ?? ((baseUrl) => Dio(BaseOptions(baseUrl: baseUrl)));
  final SecureStorage _storage;

  /// Client du rafraîchissement, sans intercepteur : un 401 sur
  /// `/auth/refresh` ne doit pas relancer un rafraîchissement. Injectable pour
  /// que les tests distinguent un refus du serveur d'une coupure réseau.
  final Dio Function(String baseUrl) _refreshClient;

  /// Purgé avec les jetons : une session perdue ici ne repasse pas par
  /// `AuthService.logout`, et un rôle gérant qui survivrait serait ressuscité
  /// par `restore()` au redémarrage — la file hors ligne posterait alors sur
  /// `/api/v1/gerant/*` sans session.
  final SessionRole _sessionRole;

  /// Seuls les **caches** sont purgés ici, jamais la file d'envoi.
  ///
  /// Une session perdue sur ce chemin est une expiration subie, pas une
  /// déconnexion : elle survient d'elle-même après une nuit d'inactivité ou
  /// une coupure réseau prolongée — le contexte même pour lequel la file
  /// existe. `pending_bookings` porte alors de l'argent encaissé en espèces
  /// au comptoir : le détruire ici le perdrait sans trace. Voir
  /// [AppDatabase.clearCaches].
  final AppDatabase _database;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _queue = [];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _queue.add((options: err.requestOptions, handler: handler));
      return;
    }
    _isRefreshing = true;

    final Dio freshDio;
    final String newAccess;
    try {
      final refresh = await _storage.refreshToken;
      if (refresh == null) {
        await _endSession();
        _finish(err, handler);
        return;
      }

      freshDio = _refreshClient(err.requestOptions.baseUrl);
      final res = await freshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refresh},
      );
      newAccess = res.data['access_token'] as String;
      final newRefresh = res.data['refresh_token'] as String? ?? refresh;

      await _storage.saveTokens(access: newAccess, refresh: newRefresh);
    } catch (e) {
      // Seul un refus du serveur clôt la session. Une coupure pendant le
      // rafraîchissement — le contexte même du mode hors ligne — laissait
      // l'utilisateur déconnecté sur un simple aller-retour perdu, alors que
      // son refresh token restait valide.
      if (e is DioException && e.response != null) {
        await _endSession();
        _finish(err, handler);
      } else {
        _finish(
          DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.connectionError,
            error: AppFailure.noInternet(),
          ),
          handler,
        );
      }
      return;
    }

    // Rejeu hors du bloc du rafraîchissement : un refus métier de la requête
    // rejouée (409 période prise, 422…) remonte tel quel. Dans le même bloc,
    // il passait pour un refus du rafraîchissement et déconnectait.
    final pending = [
      (options: err.requestOptions, handler: handler),
      ..._queue,
    ];
    _isRefreshing = false;
    _queue.clear();
    for (final request in pending) {
      request.options.headers['Authorization'] = 'Bearer $newAccess';
      try {
        request.handler.resolve(await freshDio.fetch(request.options));
      } on DioException catch (e) {
        request.handler.next(e);
      }
    }
  }

  /// Termine la requête en échec avec la file mise en attente : vidée sans
  /// réponse, la file laissait ses écrans attendre indéfiniment.
  void _finish(DioException err, ErrorInterceptorHandler handler) {
    for (final pending in _queue) {
      pending.handler.next(err.copyWith(requestOptions: pending.options));
    }
    _isRefreshing = false;
    _queue.clear();
    handler.next(err);
  }

  Future<void> _endSession() async {
    await _storage.clear();
    await _sessionRole.clear();
    await _database.clearCaches();
  }
}
