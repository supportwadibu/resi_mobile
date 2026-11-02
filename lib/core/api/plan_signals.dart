import 'dart:async';

/// Refus d'abonnement renvoyé par l'API.
enum PlanRefusal {
  /// `subscription_required` : compte rejeté ou suspendu.
  inactive,

  /// `plan_upgrade_required` : la fonction exige un palier supérieur à celui
  /// du propriétaire — lequel, le code ne le dit pas.
  upgradeRequired,
}

/// Relais des refus d'abonnement renvoyés par l'API.
///
/// Un 403 `subscription_required` ou `plan_upgrade_required` peut survenir sur
/// n'importe quel écran — l'abonnement a expiré depuis le dernier chargement,
/// ou le palier a changé. L'intercepteur le signale ici, sans rien connaître
/// de l'état de l'application ; le `PlanCubit` écoute et réagit. Passer par ce
/// relais évite une dépendance circulaire : le cubit dépend de Dio, qui
/// dépend de l'intercepteur.
class PlanSignals {
  final _controller = StreamController<PlanRefusal>.broadcast();

  Stream<PlanRefusal> get stream => _controller.stream;

  /// Traduit un code métier de refus. Ignore tout autre code.
  void report(String? code) {
    final refusal = switch (code) {
      'subscription_required' => PlanRefusal.inactive,
      'plan_upgrade_required' => PlanRefusal.upgradeRequired,
      _ => null,
    };
    if (refusal != null) _controller.add(refusal);
  }
}
