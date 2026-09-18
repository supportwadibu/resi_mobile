import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:resi_africa/core/storage/secure_storage.dart';
import 'package:resi_africa/features/auth/data/models/auth_model.dart';
import 'package:resi_africa/features/auth/data/models/register_init_model.dart';
import 'package:resi_africa/features/auth/data/models/subscription_status_model.dart';
import 'package:resi_africa/features/auth/data/repositories/auth_repository.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/auth/data/services/google_auth_service.dart';
import 'package:resi_africa/features/auth/data/models/property_manager_model.dart';
import '../../support/session_role_fixture.dart';
import '../../support/spy_database.dart';

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

/// Seul `logout` est exercé ici : les autres appels lèvent plutôt que de
/// rendre une valeur factice qu'un test futur prendrait pour un contrat.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.failLogout = false});

  final bool failLogout;
  bool logoutCalled = false;

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalled = true;
    if (failLogout) throw StateError('serveur injoignable');
  }

  @override
  Future<AuthModel> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthModel> loginWithGoogle(String idToken) =>
      throw UnimplementedError();

  @override
  Future<RegisterInitModel> initRegistration({
    required String fullName,
    required String password,
    required String authChannel,
    String? email,
    String? phone,
    String roleName = 'proprio',
  }) => throw UnimplementedError();

  @override
  Future<AuthModel> verifyRegistration({
    required String channel,
    required String target,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<SubscriptionStatusModel> fetchSubscriptionStatus() =>
      throw UnimplementedError();
}

/// Le SDK Google exige le binding natif : seul `signOut` est simulé.
class _StubGoogleAuthService implements GoogleAuthService {
  bool signedOut = false;

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<String> obtainIdToken() => throw UnimplementedError();

  @override
  Future<GoogleSignInAccount?> getCurrentUser() => throw UnimplementedError();

  @override
  PropertyManagerModel createPropertyManagerFromGoogle(
    GoogleSignInAccount googleUser,
    String phoneNumber,
  ) => throw UnimplementedError();
}

void main() {
  group('purge locale à la déconnexion', () {
    test('la base locale est vidée en entier', () async {
      // Le téléphone du comptoir passe de main en main : sans cette purge, le
      // carnet clients du propriétaire — pièces d'identité comprises — reste
      // lisible par le gérant qui se connecte ensuite.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final repository = _StubAuthRepository();
      final google = _StubGoogleAuthService();
      final database = SpyDatabase();
      final service = AuthService(
        repository,
        storage,
        google,
        sessionRoleFixture('gerant'),
        database,
      );

      await service.logout();

      expect(repository.logoutCalled, isTrue);
      expect(storage.cleared, isTrue);
      expect(google.signedOut, isTrue);
      // La file part avec le reste : la déconnexion est volontaire, donc le
      // moment convenu pour tout effacer.
      expect(database.clearedAll, isTrue);
    });

    test('la purge a lieu même si l’appel réseau de déconnexion échoue',
        () async {
      // Une révocation serveur impossible — hors réseau, API en panne — ne
      // doit pas laisser les données du précédent utilisateur sur l'appareil.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final database = SpyDatabase();
      final service = AuthService(
        _StubAuthRepository(failLogout: true),
        storage,
        _StubGoogleAuthService(),
        sessionRoleFixture('gerant'),
        database,
      );

      await expectLater(service.logout(), throwsA(isA<StateError>()));

      expect(storage.cleared, isTrue);
      expect(database.clearedAll, isTrue);
    });

    test('une purge locale impossible ne laisse pas les jetons en place',
        () async {
      // L'ordre du `finally` est délibéré : les jetons partent avant la base.
      // Si l'inverse était vrai, un disque plein ou un fichier verrouillé
      // laisserait une session valide derrière l'exception, et l'appareil
      // rouvrirait la porte au précédent utilisateur.
      final storage = _MemorySecureStorage(refresh: 'rt-valide');
      final session = sessionRoleFixture('gerant');
      final google = _StubGoogleAuthService();
      final service = AuthService(
        _StubAuthRepository(),
        storage,
        google,
        session,
        SpyDatabase(throwOnClear: true),
      );

      await expectLater(service.logout(), throwsA(isA<StateError>()));

      expect(storage.cleared, isTrue);
      expect(session.value, 'proprio');
      expect(google.signedOut, isTrue);
    });
  });
}
