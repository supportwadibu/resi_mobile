import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/interceptors/auth_interceptor.dart';
import 'package:resi_africa/core/storage/secure_storage.dart';
import '../../support/session_role_fixture.dart';

/// Stockage sécurisé en mémoire : aucun test unitaire ne touche le trousseau
/// de la plateforme, qui exigerait le binding natif.
class _MemorySecureStorage implements SecureStorage {
  _MemorySecureStorage({this.refresh});

  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<String?> get accessToken async => access;

  @override
  Future<String?> get refreshToken async => refresh;

  @override
  Future<void> saveTokens({
    required String? access,
    required String? refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    cleared = true;
  }
}

/// Rejoue le 401 que l'intercepteur doit traiter, sans réseau.
DioException _unauthorized() {
  final options = RequestOptions(path: '/api/v1/gerant/bookings');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 401,
      data: const {'message': 'jeton expiré'},
    ),
    type: DioExceptionType.badResponse,
  );
}

/// Recueille l'issue laissée par l'intercepteur, qui ne rend pas la main
/// autrement qu'en appelant le handler.
class _RecordingHandler extends ErrorInterceptorHandler {
  bool passedThrough = false;

  @override
  void next(DioException err) => passedThrough = true;
}

void main() {
  group('déconnexion forcée par l’intercepteur', () {
    test('un refresh token absent efface le rôle', () async {
      // Sans ce nettoyage, un gérant éjecté garde `session_role = 'gerant'`
      // en préférences : `restore()` le ressusciterait au redémarrage, et la
      // file hors ligne se viderait sur `/api/v1/gerant/*` sans session.
      final storage = _MemorySecureStorage();
      final session = sessionRoleFixture('gerant');
      final interceptor = AuthInterceptor(storage, session);
      final handler = _RecordingHandler();

      interceptor.onError(_unauthorized(), handler);
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isTrue);
      expect(session.value, 'proprio');
    });

    test('un rafraîchissement échoué efface le rôle', () async {
      // Le refresh token est présent : l'intercepteur tente l'appel réseau,
      // qui échoue faute d'hôte joignable, et part dans la branche `catch`.
      final storage = _MemorySecureStorage(refresh: 'rt-expire');
      final session = sessionRoleFixture('gerant');
      final interceptor = AuthInterceptor(storage, session);
      final handler = _RecordingHandler();

      interceptor.onError(_unauthorized(), handler);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(storage.cleared, isTrue);
      expect(session.value, 'proprio');
    });

    test('une erreur qui n’est pas un 401 laisse la session intacte', () async {
      // Un 500 n'est pas une session perdue : effacer le rôle déconnecterait
      // l'utilisateur sur une panne serveur passagère.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final session = sessionRoleFixture('gerant');
      final interceptor = AuthInterceptor(storage, session);
      final handler = _RecordingHandler();

      final options = RequestOptions(path: '/api/v1/gerant/bookings');
      interceptor.onError(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
          type: DioExceptionType.badResponse,
        ),
        handler,
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isFalse);
      expect(session.value, 'gerant');
    });
  });
}
