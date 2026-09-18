import '../../../../core/session/session_role.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_model.dart';
import '../models/register_init_model.dart';
import '../models/subscription_status_model.dart';
import '../repositories/auth_repository.dart';
import 'google_auth_service.dart';

class AuthService {
  const AuthService(
    this._repository,
    this._storage,
    this._google,
    this._sessionRole,
    this._database,
  );

  final AuthRepository _repository;
  final SecureStorage _storage;
  final GoogleAuthService _google;

  /// Le rôle est retenu ici, avec les jetons, et non dans l'`AuthCubit` : la
  /// déconnexion de l'écran profil appelle ce service directement, et un rôle
  /// gérant qui survivrait ferait appeler `/gerant/*` par le propriétaire qui
  /// se connecte ensuite.
  final SessionRole _sessionRole;

  /// Injectée plutôt que prise sur `AppDatabase.instance` : la purge de la
  /// base locale est le point que la déconnexion doit garantir, et un
  /// singleton pris en dur la rendrait invérifiable.
  final AppDatabase _database;

  Future<AuthModel> login(String email, String password) async {
    final auth = await _repository.login(email, password);
    await _persist(auth);
    return auth;
  }

  Future<RegisterInitModel> initRegistration({
    required String fullName,
    required String password,
    required String authChannel,
    String? email,
    String? phone,
  }) {
    return _repository.initRegistration(
      fullName: fullName,
      password: password,
      authChannel: authChannel,
      email: email,
      phone: phone,
    );
  }

  Future<AuthModel> verifyRegistration({
    required String channel,
    required String target,
    required String code,
  }) async {
    final auth = await _repository.verifyRegistration(
      channel: channel,
      target: target,
      code: code,
    );
    await _persist(auth);
    return auth;
  }

  Future<AuthModel> loginWithGoogle() async {
    final idToken = await _google.obtainIdToken();
    final auth = await _repository.loginWithGoogle(idToken);
    await _persist(auth);
    return auth;
  }

  Future<void> logout() async {
    final refresh = await _storage.refreshToken;

    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _repository.logout(refresh);
      }
    } finally {
      // Les jetons d'abord : si la purge de la base échoue — disque plein,
      // fichier verrouillé —, la session est déjà close et l'appareil ne
      // rouvre pas la porte. L'inverse laisserait un jeton valide derrière
      // une exception.
      await _storage.clear();
      await _sessionRole.clear();
      await _google.signOut();

      // Purge complète, file d'envoi comprise : la déconnexion est un acte
      // volontaire, donc le moment convenu pour tout effacer. Le carnet
      // clients — pièces d'identité comprises — ne doit pas rester lisible
      // par la personne qui prend l'appareil ensuite.
      await _database.clear();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.accessToken;
    return token != null && token.isNotEmpty;
  }

  /// État d'abonnement du propriétaire connecté (essai en cours, jours
  /// restants, statut du dossier de validation).
  Future<SubscriptionStatusModel> subscriptionStatus() {
    return _repository.fetchSubscriptionStatus();
  }

  /// Point de passage unique des trois entrées en session — mot de passe,
  /// inscription vérifiée, Google : le rôle y est retenu avec les jetons
  /// plutôt qu'à chacune d'elles, où il finirait par être oublié.
  Future<void> _persist(AuthModel auth) async {
    await _storage.saveTokens(
      access: auth.accessToken,
      refresh: auth.refreshToken,
    );
    await _sessionRole.set(auth.user.role);
  }
}
