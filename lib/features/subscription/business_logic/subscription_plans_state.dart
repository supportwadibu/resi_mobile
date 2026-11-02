import '../data/models/subscription_plan_model.dart';

/// Issue du dernier paiement lancé depuis l'écran.
enum CheckoutOutcome { none, waiting, paid, failed }

sealed class SubscriptionPlansState {
  const SubscriptionPlansState();
}

final class SubscriptionPlansInitial extends SubscriptionPlansState {
  const SubscriptionPlansInitial();
}

final class SubscriptionPlansLoading extends SubscriptionPlansState {
  const SubscriptionPlansLoading();
}

final class SubscriptionPlansLoaded extends SubscriptionPlansState {
  const SubscriptionPlansLoaded({
    required this.plans,
    this.options = SubscriptionOptionsModel.none,
    this.payingPlanId,
    this.pendingReference,
    this.outcome = CheckoutOutcome.none,
    this.message,
    this.isCancelling = false,
  });

  final List<SubscriptionPlanModel> plans;

  /// Renouvellement, résiliation et montées possibles du forfait en cours.
  final SubscriptionOptionsModel options;

  /// Forfait dont le paiement est en cours de lancement.
  final String? payingPlanId;

  /// Paiement ouvert chez Wave, à confirmer au retour dans l'application.
  final String? pendingReference;
  final CheckoutOutcome outcome;

  /// Refus du serveur ou issue du paiement, affichable tel quel.
  final String? message;

  /// Résiliation envoyée, réponse attendue.
  final bool isCancelling;

  SubscriptionPlansLoaded copyWith({
    SubscriptionOptionsModel? options,
    String? payingPlanId,
    bool clearPaying = false,
    String? pendingReference,
    bool clearPending = false,
    CheckoutOutcome? outcome,
    String? message,
    bool clearMessage = false,
    bool? isCancelling,
  }) {
    return SubscriptionPlansLoaded(
      plans: plans,
      options: options ?? this.options,
      payingPlanId: clearPaying ? null : (payingPlanId ?? this.payingPlanId),
      pendingReference: clearPending
          ? null
          : (pendingReference ?? this.pendingReference),
      outcome: outcome ?? this.outcome,
      message: clearMessage ? null : (message ?? this.message),
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }
}

final class SubscriptionPlansError extends SubscriptionPlansState {
  const SubscriptionPlansError(this.message);

  final String message;
}
