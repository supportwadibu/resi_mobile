import 'package:dio/dio.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/home_model.dart';

class HomeRepository {
  const HomeRepository(this._dio);
  final Dio _dio;

  Future<List<HomeModel>> getHomeList() async {
    try {
      final response = await _dio.get(ApiEndpoints.homes);
      return (response.data as List)
          .map((e) => HomeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
