import 'package:dio/dio.dart';
import 'failures.dart';

AppFailure mapDioExceptionToFailure(DioException e) {
  if (e.error is AppFailure) return e.error as AppFailure;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout    ||
    DioExceptionType.sendTimeout       => AppFailure.timeout(),
    DioExceptionType.connectionError   => AppFailure.noInternet(),
    DioExceptionType.badResponse       => _fromResponse(e.response),
    _                                  => AppFailure.unexpected(message: e.message),
  };
}

AppFailure _fromResponse(Response? response) {
  final status = response?.statusCode ?? 0;
  final data   = response?.data;
  return switch (status) {
    401 => AppFailure.unauthorized(),
    403 => AppFailure.forbidden(),
    404 => AppFailure.notFound(),
    422 => AppFailure.validation(errors: parseValidationErrors(data)),
    // `serverError` porte le code : la synchronisation hors ligne distingue un
    // 409 (periode deja reservee, a arbitrer) d'une panne a reessayer.
    _   => AppFailure.serverError(code: status, message: _parseMessage(data)),
  };
}

String? _parseMessage(dynamic d) =>
    d is Map<String, dynamic> ? d['message'] as String? : null;
