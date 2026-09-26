import 'dart:async';

import '../../features/subscription/data/models/plan_access.dart';

/// Relais des refus d'abonnement renvoyés par l'API.
///
/// Un 403 `subscription_required` ou `plan_upgrade_required` peut survenir sur
/// n'importe quel écran — l'abonnement a expiré depuis le dernier chargement,
/// ou le palier a changé. L'intercepteur le signale ici, sans rien connaître
/// de l'état de l'application ; le `PlanCubit` écoute et réagit. Passer par ce
/// relais évite une dépendance circulaire : le cubit dépend de Dio, qui
/// dépend de l'intercepteur.
class PlanSignals {
  final _controller = StreamController<PlanAccess>.broadcast();

  Stream<PlanAccess> get stream => _controller.stream;

  /// Traduit un code métier de refus en accès constaté. Ignore tout autre code.
  void report(String? code) {
    final access = switch (code) {
      'subscription_required' => PlanAccess.inactive,
      'plan_upgrade_required' => PlanAccess.basic,
      _ => null,
    };
    if (access != null) _controller.add(access);
  }
}
