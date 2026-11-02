import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/property_stats_model.dart';

/// État du parc du propriétaire connecté : unités publiées, louées, libres.
class PropertyStatsRepository {
  const PropertyStatsRepository(this._dio);
  final Dio _dio;

  Future<PropertyStatsModel> getStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioPropertyStats);
      final data = (response.data as Map<String, dynamic>)['data'];
      return PropertyStatsModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
