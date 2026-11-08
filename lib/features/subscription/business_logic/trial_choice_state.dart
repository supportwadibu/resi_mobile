import '../data/models/plan_access.dart';
import '../data/models/subscription_plan_model.dart';

/// Choix du forfait de l'essai gratuit.
sealed class TrialChoiceState {
  const TrialChoiceState();
}

final class TrialChoiceInitial extends TrialChoiceState {
  const TrialChoiceInitial();
}

final class TrialChoiceLoading extends TrialChoiceState {
  const TrialChoiceLoading();
}

final class TrialChoiceLoaded extends TrialChoiceState {
  const TrialChoiceLoaded({required this.offers, this.starting, this.message});

  /// Un forfait par palier proposé à l'essai (Pro, puis Pro+) : le moins cher
  /// de chaque palier, dont le prix sert de repère.
  final List<SubscriptionPlanModel> offers;

  /// Palier dont l'essai est en cours d'ouverture : les boutons attendent.
  final PlanAccess? starting;

  /// Refus du serveur, affiché dans l'écran.
  final String? message;

  TrialChoiceLoaded copyWith({PlanAccess? starting, String? message}) =>
      TrialChoiceLoaded(offers: offers, starting: starting, message: message);
}

final class TrialChoiceError extends TrialChoiceState {
  const TrialChoiceError(this.message);

  final String message;
}

/// Essai ouvert : l'écran passe à l'accueil de l'essai.
final class TrialChoiceStarted extends TrialChoiceState {
  const TrialChoiceStarted(this.tier);

  final PlanAccess tier;
}
