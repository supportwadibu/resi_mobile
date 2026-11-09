import 'package:dio/dio.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/phone_helper.dart';
import '../models/auth_model.dart';
import '../models/password_reset_model.dart';
import '../models/register_init_model.dart';
import '../models/subscription_status_model.dart';

class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  /// Pays présumé d'un numéro saisi sans indicatif à la connexion.
  ///
  /// Le champ de connexion n'a pas de sélecteur de pays, contrairement aux
  /// écrans de création de compte : il faut donc une présomption. La Côte
  /// d'Ivoire est le marché de la plateforme, et c'est déjà le pays que
  /// `AddGerantScreen` fixe en dur. Un numéro saisi avec son `+` est reconnu
  /// pour ce qu'il est, quel que soit ce réglage.
  static const _defaultCountryIso2 = 'CI';

  /// [identifier] est une adresse e-mail **ou** un numéro de téléphone : c'est
  /// le même champ à l'écran, et le serveur les distingue sur `@`.
  Future<AuthModel> login(String identifier, String password) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        // Mis en forme ici, et non dans l'écran : la connexion passe toute par
        // ce point, alors qu'un identifiant composé côté écran divergerait au
        // premier appelant qui l'oublierait — c'est exactement ce qui s'est
        // produit entre la création d'un gérant et sa connexion.
        data: {
          'identifier': PhoneHelper.normalizeLoginIdentifier(
            identifier,
            _defaultCountryIso2,
          ),
          'password': password,
        },
      );
      return AuthModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// [sponsorshipCode] : code du parrain, lu par l'API à la création du
  /// compte seulement — ignoré pour un compte qui existe déjà.
  Future<AuthModel> loginWithGoogle(
    String idToken, {
    String? sponsorshipCode,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken, 'sponsorship_code': ?sponsorshipCode},
      );
      return AuthModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<RegisterInitModel> initRegistration({
    required String fullName,
    required String password,
    required String authChannel,
    String? email,
    String? phone,
    String roleName = 'proprio',
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.registerInit,
        data: {
          'full_name': fullName,
          'auth_channel': authChannel,
          'password': password,
          'password_confirmation': password,
          'role_name': roleName,
          'email': ?email,
          'phone': ?phone,
        },
      );
      return RegisterInitModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<AuthModel> verifyRegistration({
    required String channel,
    required String target,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.registerVerify,
        data: {'channel': channel, 'target': target, 'code': code},
      );
      return AuthModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Demande un code de réinitialisation. [identifier] est mis en forme comme
  /// à la connexion : le code doit partir vers le numéro que le compte porte.
  ///
  /// L'API répond de la même façon qu'un compte existe ou non ; le code n'est
  /// donc pas une preuve que le numéro est inscrit.
  Future<PasswordResetRequest> requestPasswordReset(String identifier) async {
    final normalized = PhoneHelper.normalizeLoginIdentifier(
      identifier,
      _defaultCountryIso2,
    );
    try {
      final res = await _dio.post(
        ApiEndpoints.passwordForgot,
        data: {'identifier': normalized},
      );
      return PasswordResetRequest.fromJson(
        normalized,
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Remplace le mot de passe avec le code reçu ; l'API ouvre la session.
  /// [identifier] est celui que [requestPasswordReset] a rendu, déjà normalisé.
  Future<AuthModel> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.passwordReset,
        data: {
          'identifier': identifier,
          'code': code,
          'password': password,
          'password_confirmation': password,
        },
      );
      return AuthModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Compte de la session en cours, tel que l'API le connaît aujourd'hui.
  Future<AuthUser> fetchMe() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      final data = res.data as Map<String, dynamic>;
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// État d'abonnement du propriétaire connecté.
  ///
  /// Alimente l'écran affiché juste après l'inscription, puis le tableau de
  /// bord. Requiert un token valide : la route est protégée côté API.
  Future<SubscriptionStatusModel> fetchSubscriptionStatus() async {
    try {
      final res = await _dio.get(ApiEndpoints.proprioSubscription);
      final data = res.data as Map<String, dynamic>;
      return SubscriptionStatusModel.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }
}
