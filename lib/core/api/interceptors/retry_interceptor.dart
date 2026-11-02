import 'dart:math' as math;
import 'package:dio/dio.dart';

import '../../error/failures.dart';
import '../../offline/offline_cache_interceptor.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3, this.baseDelayMs = 500});
  final int maxRetries;
  final int baseDelayMs;

  Dio? _dio;

  /// Client par lequel rejouer : celui de l'application, délais et
  /// intercepteurs compris. Un `Dio()` nu rejouait sans délai de connexion —
  /// sur un Wi-Fi sans Internet, chaque rejeu pendait alors sans limite — et
  /// sans jeton.
  void attach(Dio dio) => _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!shouldRetry(err)) {
      handler.next(err);
      return;
    }
    final attempt = (err.requestOptions.extra['_retry'] as int?) ?? 0;
    if (attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(
      Duration(
        milliseconds:
            baseDelayMs * math.pow(2, attempt).toInt() +
            math.Random().nextInt(200),
      ),
    );
    err.requestOptions.extra['_retry'] = attempt + 1;
    try {
      handler.resolve(await (_dio ?? Dio()).fetch(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Une lecture servie par le cache hors ligne n'est pas rejouée — le cache
  /// prend le relais —, ni une requête rejetée faute de réseau par
  /// l'intercepteur de connectivité : la rejouer aussitôt échouerait de même.
  static bool shouldRetry(DioException e) {
    if (e.requestOptions.extra[noRetryExtra] == true) return false;
    if (e.error is AppFailure) return false;

    final s = e.response?.statusCode;
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        (s != null && s >= 500);
  }
}
