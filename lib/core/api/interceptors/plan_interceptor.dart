import 'package:dio/dio.dart';

import '../../error/failures.dart';
import '../plan_signals.dart';

/// Signale les refus d'abonnement, sans les intercepter.
///
/// L'erreur poursuit son chemin jusqu'au repository appelant, qui la traduit
/// comme toute autre : ce relais ne fait que prévenir l'application que
/// l'accès a changé.
class PlanInterceptor extends Interceptor {
  PlanInterceptor(this._signals);

  final PlanSignals _signals;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 403) {
      _signals.report(parseErrorCode(err.response?.data));
    }
    handler.next(err);
  }
}
