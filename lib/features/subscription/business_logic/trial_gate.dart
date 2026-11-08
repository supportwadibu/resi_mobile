import 'plan_state.dart';

/// Écran que l'essai impose au propriétaire, par-dessus toute l'application.
enum TrialGate {
  /// Rien à imposer.
  none,

  /// Aucun forfait choisi pour l'essai : l'écran de choix remplace tout.
  choose,

  /// L'essai vient de se terminer : l'écran de fin d'essai s'affiche une fois.
  ended,
}

/// Décide de l'écran imposé par l'essai.
///
/// Un gérant n'a ni essai ni forfait à choisir : il dépend de l'abonnement
/// de son propriétaire. [endedSeen] : l'écran de fin d'essai a déjà été
/// montré sur cet appareil.
TrialGate trialGate(
  PlanState state, {
  required String? role,
  required bool endedSeen,
}) {
  if (role == 'gerant' || state is! PlanKnown) return TrialGate.none;
  if (state.trialChoiceRequired) return TrialGate.choose;
  if (state.endedTrialTier != null && !endedSeen) return TrialGate.ended;
  return TrialGate.none;
}
