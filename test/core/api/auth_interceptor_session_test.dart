import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/interceptors/auth_interceptor.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/storage/secure_storage.dart';
import '../../support/session_role_fixture.dart';
import '../../support/spy_database.dart';
import '../../support/translations_fixture.dart';

/// Serveur de rafraîchissement simulé : refuse le jeton, ou reste injoignable.
class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({required this.reachable});

  final bool reachable;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!reachable) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'hôte injoignable',
      );
    }
    return ResponseBody.fromString(
      '{"code":"expired_refresh","message":"Refresh token expiré."}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Intercepteur dont le rafraîchissement tombe sur [_RefreshAdapter].
AuthInterceptor _interceptor(
  SecureStorage storage,
  SpyDatabase database, {
  String role = 'gerant',
  bool serverReachable = true,
}) => AuthInterceptor(
  storage,
  sessionRoleFixture(role),
  database,
  refreshClient: (baseUrl) =>
      Dio(BaseOptions(baseUrl: baseUrl))
        ..httpClientAdapter = _RefreshAdapter(reachable: serverReachable),
);

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

class _CapturingHandler extends ErrorInterceptorHandler {
  _CapturingHandler(this.onNext);

  final void Function(DioException) onNext;

  @override
  void next(DioException err) => onNext(err);
}

void main() {
  setUpAll(loadTestTranslations);

  group('déconnexion forcée par l’intercepteur', () {
    test('un refresh token absent efface le rôle', () async {
      // Sans ce nettoyage, un gérant éjecté garde `session_role = 'gerant'`
      // en préférences : `restore()` le ressusciterait au redémarrage, et la
      // file hors ligne se viderait sur `/api/v1/gerant/*` sans session.
      final storage = _MemorySecureStorage();
      final session = sessionRoleFixture('gerant');
      final database = SpyDatabase();
      final interceptor = AuthInterceptor(storage, session, database);
      final handler = _RecordingHandler();

      interceptor.onError(_unauthorized(), handler);
      await Future<void>.delayed(Duration.zero);

      expect(storage.cleared, isTrue);
      expect(session.value, 'proprio');
    });

    test('un rafraîchissement refusé par le serveur efface le rôle', () async {
      final storage = _MemorySecureStorage(refresh: 'rt-expire');
      final session = sessionRoleFixture('gerant');
      final interceptor = AuthInterceptor(
        storage,
        session,
        SpyDatabase(),
        refreshClient: (baseUrl) =>
            Dio(BaseOptions(baseUrl: baseUrl))
              ..httpClientAdapter = _RefreshAdapter(reachable: true),
      );

      interceptor.onError(_unauthorized(), _RecordingHandler());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(storage.cleared, isTrue);
      expect(session.value, 'proprio');
    });

    test('une coupure pendant le rafraîchissement garde la session', () async {
      // Le contexte même du mode hors ligne : le refresh token reste valide,
      // seul l'aller-retour s'est perdu. Déconnecter ici renvoyait au login
      // un propriétaire qui travaillait sans réseau.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final database = SpyDatabase();
      final interceptor = _interceptor(
        storage,
        database,
        serverReachable: false,
      );
      DioException? passed;
      final handler = _CapturingHandler((e) => passed = e);

      interceptor.onError(_unauthorized(), handler);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(storage.cleared, isFalse);
      expect(database.cachesCleared, isFalse);
      expect(passed?.error, isA<AppFailure>());
      expect((passed!.error! as AppFailure).statusCode, isNull);
    });

    test('une erreur qui n’est pas un 401 laisse la session intacte', () async {
      // Un 500 n'est pas une session perdue : effacer le rôle déconnecterait
      // l'utilisateur sur une panne serveur passagère.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final session = sessionRoleFixture('gerant');
      final database = SpyDatabase();
      final interceptor = AuthInterceptor(storage, session, database);
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
      expect(database.cachesCleared, isFalse);
    });
  });

  group('purge locale sur expiration subie', () {
    test(
      'un refresh token absent purge les caches sans toucher la file',
      () async {
        // Le carnet clients — pièces d'identité comprises — ne doit pas rester
        // lisible par la personne qui reprend l'appareil.
        final storage = _MemorySecureStorage();
        final database = SpyDatabase();
        final interceptor = AuthInterceptor(
          storage,
          sessionRoleFixture('gerant'),
          database,
        );

        interceptor.onError(_unauthorized(), _RecordingHandler());
        await Future<void>.delayed(Duration.zero);

        expect(database.cachesCleared, isTrue);
        // Le point capital : `pending_bookings` porte des réservations
        // encaissées en espèces et pas encore envoyées. Une expiration de jeton
        // survient toute seule — après une nuit, après une coupure réseau : les
        // détruire là perdrait de l'argent réel que rien ne retrace.
        expect(database.clearedAll, isFalse);
      },
    );

    test(
      'un rafraîchissement échoué purge les caches sans toucher la file',
      () async {
        final storage = _MemorySecureStorage(refresh: 'rt-expire');
        final database = SpyDatabase();
        final interceptor = _interceptor(storage, database);

        interceptor.onError(_unauthorized(), _RecordingHandler());
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(database.cachesCleared, isTrue);
        expect(database.clearedAll, isFalse);
      },
    );
  });
}
