import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/rapport_model.dart';

class RapportRepository {
  const RapportRepository(this._dio);
  final Dio _dio;

  Future<List<RapportModel>> getRapportList() async {
    try {
      final response = await _dio.get(ApiEndpoints.rapports);
      return (response.data as List)
          .map((e) => RapportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
