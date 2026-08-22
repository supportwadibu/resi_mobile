import '../../../../core/storage/secure_storage.dart';
import '../models/auth_model.dart';
import '../models/register_init_model.dart';
import '../models/subscription_status_model.dart';
import '../repositories/auth_repository.dart';
import 'google_auth_service.dart';

class AuthService {
  const AuthService(this._repository, this._storage, this._google);

  final AuthRepository _repository;
  final SecureStorage _storage;
  final GoogleAuthService _google;

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
      await _storage.clear();
      await _google.signOut();
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

  Future<void> _persist(AuthModel auth) {
    return _storage.saveTokens(
      access: auth.accessToken,
      refresh: auth.refreshToken,
    );
  }
}
