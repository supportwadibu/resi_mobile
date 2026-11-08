import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/plan_access.dart';
import '../data/models/subscription_plan_model.dart';
import '../data/repositories/subscription_repository.dart';
import 'plan_cubit.dart';
import 'trial_choice_state.dart';

/// Choix du forfait de l'essai gratuit : le propriétaire essaie RESI Pro ou
/// RESI Pro+, l'essai n'ouvre que ce qu'ouvre le palier choisi.
class TrialChoiceCubit extends Cubit<TrialChoiceState> {
  TrialChoiceCubit(this._repository, this._plan)
    : super(const TrialChoiceInitial());

  final SubscriptionRepository _repository;
  final PlanCubit _plan;

  Future<void> load() async {
    emit(const TrialChoiceLoading());
    try {
      final plans = await _repository.fetchPlans();
      if (!isClosed) emit(TrialChoiceLoaded(offers: trialOffers(plans)));
    } on AppFailure catch (f) {
      if (!isClosed) emit(TrialChoiceError(f.userMessage));
    }
  }

  Future<void> choose(PlanAccess tier) async {
    final current = state;
    if (current is! TrialChoiceLoaded || current.starting != null) return;

    emit(current.copyWith(starting: tier));
    try {
      await _repository.startTrial(tier);
      // Relu avant de quitter l'écran : le garde global retient sur le choix
      // tant que l'accès connu dit qu'aucun essai n'est ouvert.
      await _plan.refresh();
      if (!isClosed) emit(TrialChoiceStarted(tier));
    } on AppFailure catch (f) {
      if (!isClosed) emit(current.copyWith(message: f.userMessage));
    }
  }
}

/// Un forfait par palier payant, le moins cher, Pro avant Pro+.
///
/// L'administrateur peut proposer plusieurs durées d'un même palier ; l'essai
/// porte sur le palier, pas sur une durée, et le prix le plus bas sert de
/// repère.
List<SubscriptionPlanModel> trialOffers(List<SubscriptionPlanModel> plans) {
  final cheapest = <PlanAccess, SubscriptionPlanModel>{};
  for (final plan in plans) {
    if (plan.access != PlanAccess.pro && plan.access != PlanAccess.proPlus) {
      continue;
    }
    final known = cheapest[plan.access];
    if (known == null || plan.price < known.price) cheapest[plan.access] = plan;
  }
  return [?cheapest[PlanAccess.pro], ?cheapest[PlanAccess.proPlus]];
}
