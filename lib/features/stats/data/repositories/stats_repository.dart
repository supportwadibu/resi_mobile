import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/stats_model.dart';

class StatsRepository {
  const StatsRepository(this._dio);
  final Dio _dio;

  Future<List<StatsModel>> getStatsList() async {
    try {
      final response = await _dio.get(ApiEndpoints.stats);
      return (response.data as List)
          .map((e) => StatsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
