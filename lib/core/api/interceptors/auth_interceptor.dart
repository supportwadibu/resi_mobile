import 'package:dio/dio.dart';
import '../../session/session_role.dart';
import '../../storage/app_database.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._sessionRole, this._database);
  final SecureStorage _storage;

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

    try {
      final refresh = await _storage.refreshToken;
      if (refresh == null) {
        await _storage.clear();
        await _sessionRole.clear();
        await _database.clearCaches();
        handler.next(err);
        return;
      }

      final freshDio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
      final res = await freshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refresh},
      );
      final newAccess = res.data['access_token'] as String;
      final newRefresh = res.data['refresh_token'] as String? ?? refresh;

      await _storage.saveTokens(access: newAccess, refresh: newRefresh);
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      handler.resolve(await freshDio.fetch(err.requestOptions));

      for (final p in _queue) {
        p.options.headers['Authorization'] = 'Bearer $newAccess';
        p.handler.resolve(await freshDio.fetch(p.options));
      }
    } catch (_) {
      await _storage.clear();
      await _sessionRole.clear();
      await _database.clearCaches();
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _queue.clear();
    }
  }
}
