import 'package:dio/dio.dart';

import '../api/api_endpoints.dart';
import '../error/exception_mapper.dart';
import '../error/failures.dart';

/// Déclare au serveur l'appareil qui reçoit les notifications du compte.
///
/// Route commune à tous les rôles (`/auth/device-tokens`) : propriétaire,
/// gérant et client s'y enregistrent de la même façon, le serveur lisant le
/// rôle sur la session.
class DeviceTokenRepository {
  const DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> register(String token, {required String platform}) async {
    try {
      await _dio.post(
        ApiEndpoints.deviceTokens,
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<void> unregister(String token) async {
    try {
      await _dio.delete(ApiEndpoints.deviceTokens, data: {'token': token});
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
