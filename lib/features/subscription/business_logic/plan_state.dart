import '../data/models/plan_access.dart';

/// Accès de l'abonnement, tel que l'application le connaît.
sealed class PlanState {
  const PlanState();

  /// Accès à retenir pour décider d'un verrou.
  ///
  /// Tant que rien n'est connu, l'accès complet : verrouiller par défaut
  /// fermerait l'application à tout abonné le temps du premier chargement —
  /// et hors ligne, jusqu'au retour du réseau. L'API reste l'autorité, et le
  /// moindre refus corrige l'état aussitôt.
  PlanAccess get access => PlanAccess.full;
}

/// Rien de connu : ni réponse de l'API, ni valeur en cache.
final class PlanUnknown extends PlanState {
  const PlanUnknown();
}

final class PlanKnown extends PlanState {
  const PlanKnown(
    this._access, {
    this.daysRemaining,
    this.isTrial = false,
    this.endDate,
  });

  final PlanAccess _access;

  @override
  PlanAccess get access => _access;

  /// Jours avant l'échéance. `null` quand l'accès vient du cache ou d'un refus
  /// de l'API, qui ne le disent pas.
  final int? daysRemaining;
  final bool isTrial;

  /// Échéance de la période en cours ; `null` dans les mêmes cas.
  final DateTime? endDate;
}
