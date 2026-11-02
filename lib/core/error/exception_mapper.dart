import 'package:dio/dio.dart';
import 'failures.dart';

AppFailure mapDioExceptionToFailure(DioException e) {
  if (e.error is AppFailure) return e.error as AppFailure;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => AppFailure.timeout(),
    DioExceptionType.connectionError => AppFailure.noInternet(),
    DioExceptionType.badResponse => _fromResponse(e.response),
    _ => AppFailure.unexpected(message: e.message),
  };
}

AppFailure _fromResponse(Response? response) {
  final status = response?.statusCode ?? 0;
  final data = response?.data;

  // C'est ce chemin-ci, et non `AppFailure.fromDio`, qu'empruntent les
  // réservations : sans le code métier ici, la synchronisation ne pourrait pas
  // distinguer un logement sorti du périmètre d'un jeton expiré.
  final businessCode = parseErrorCode(data);

  return switch (status) {
    401 => AppFailure.unauthorized(),
    // Le message du serveur est repris tel quel : un refus métier indique
    // souvent la marche à suivre pour le lever.
    403 => AppFailure.forbidden(
      message: _parseMessage(data),
      code: businessCode,
    ),
    404 => AppFailure.notFound(code: businessCode),
    422 => AppFailure.validation(
      errors: parseValidationErrors(data),
      code: businessCode,
      message: _parseMessage(data),
    ),
    // `serverError` porte le code : la synchronisation hors ligne distingue un
    // 409 (periode deja reservee, a arbitrer) d'une panne a reessayer.
    _ => AppFailure.serverError(
      code: status,
      message: _parseMessage(data),
      businessCode: businessCode,
    ),
  };
}

String? _parseMessage(dynamic d) =>
    d is Map<String, dynamic> ? d['message'] as String? : null;
