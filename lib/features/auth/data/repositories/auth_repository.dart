import 'package:dio/dio.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../models/auth_model.dart';
import '../models/register_init_model.dart';
import '../models/subscription_status_model.dart';

class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  Future<AuthModel> login(String email, String password) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'identifier': email, 'password': password},
      );
      return AuthModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<AuthModel> loginWithGoogle(String idToken) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken},
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
