import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../offline/offline_cache_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/plan_interceptor.dart';
import 'interceptors/redacting_log_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

Dio buildDioClient(
  AppConfig config,
  AuthInterceptor auth,
  RetryInterceptor retry,
  ConnectivityInterceptor connectivity,
  PlanInterceptor plan,
  OfflineCacheInterceptor offlineCache,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    // En tête : hors ligne, il sert la lecture depuis le cache avant que
    // l'intercepteur de connectivité ne la rejette.
    offlineCache,
    connectivity,
    auth,
    retry,
    // Après le rafraîchissement du jeton : un 403 qui atteint ce point est un
    // refus métier définitif pour cette requête, pas une session à relancer.
    plan,
    // En dernier : il voit ainsi la requête telle qu'elle part réellement,
    // en-tête d'authentification et rejeu compris. Muet en production, et les
    // mots de passe, jetons et OTP y sont masqués.
    if (kDebugMode && config.enableLogging) const RedactingLogInterceptor(),
  ]);

  retry.attach(dio);

  return dio;
}
