import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/feedback_model.dart';

/// Avis et suggestions du propriétaire connecté sur l'application.
class FeedbackRepository {
  const FeedbackRepository(this._dio);

  final Dio _dio;

  /// Envoie un avis et renvoie celui qui a été enregistré.
  Future<FeedbackModel> create(CreateFeedbackPayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioFeedbacks,
        data: payload.toJson(),
      );

      final data = (response.data as Map<String, dynamic>)['data'];
      return FeedbackModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Ses propres avis, le plus récent d'abord.
  Future<List<FeedbackModel>> getMyFeedbacks({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioFeedbacks,
        queryParameters: {'page': page, 'per_page': perPage},
      );

      final data = (response.data as Map<String, dynamic>)['data'] as List?;
      return (data ?? [])
          .map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
