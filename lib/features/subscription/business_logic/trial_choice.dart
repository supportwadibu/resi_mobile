import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/session/session_role.dart';

import 'plan_cubit.dart';
import 'plan_state.dart';

/// Relit l'accès auprès de l'API, puis dit si le propriétaire doit encore
/// choisir le forfait de son essai.
///
/// La relecture compte : le cache local ne garde que le niveau d'accès, pas
/// `trialChoiceRequired`. Sans elle, un forfait choisi lors d'une session
/// précédente serait ignoré et l'écran de choix reviendrait.
///
/// [whenUnknown] tranche quand l'API ne répond pas et qu'aucun état n'est
/// connu : juste après l'inscription, le choix reste à faire ; à une simple
/// réouverture, mieux vaut ouvrir l'accueil que bloquer hors réseau.
Future<bool> mustChooseTrialPlan({required bool whenUnknown}) async {
  if (sl<SessionRole>().value == 'gerant') return false;
  final plan = sl<PlanCubit>();
  await plan.refresh();
  final state = plan.state;
  if (state is! PlanKnown) return whenUnknown;
  return state.trialChoiceRequired;
}
