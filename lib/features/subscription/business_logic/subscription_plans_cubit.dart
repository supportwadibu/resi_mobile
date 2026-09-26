import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/subscription_plan_model.dart';
import '../data/repositories/subscription_repository.dart';
import 'plan_cubit.dart';
import 'subscription_plans_state.dart';

/// Choix d'un forfait et paiement Wave.
///
/// Le paiement se fait hors de l'application : le lien Wave ouvre l'application
/// Wave, et le propriétaire revient ensuite. Au retour, [confirmPending]
/// demande au serveur de constater l'issue chez Wave, sans attendre le
/// webhook — qui peut tarder ou se perdre.
class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  SubscriptionPlansCubit(this._repository, this._plan)
    : super(const SubscriptionPlansInitial());

  final SubscriptionRepository _repository;
  final PlanCubit _plan;

  Future<void> load() async {
    emit(const SubscriptionPlansLoading());
    try {
      final plans = await _repository.fetchPlans();
      if (!isClosed) emit(SubscriptionPlansLoaded(plans: plans));
    } on AppFailure catch (f) {
      if (!isClosed) emit(SubscriptionPlansError(f.userMessage));
    }
  }

  /// Lance le paiement d'un forfait et rend le lien Wave à ouvrir.
  ///
  /// `null` si le serveur refuse — renouvellement trop tôt, changement de
  /// palier en cours de période — : le motif est alors dans l'état.
  Future<String?> pay(SubscriptionPlanModel plan) async {
    final current = state;
    if (current is! SubscriptionPlansLoaded || current.payingPlanId != null) {
      return null;
    }

    emit(current.copyWith(payingPlanId: plan.id, clearMessage: true));
    try {
      final checkout = await _repository.startCheckout(plan.id);
      if (isClosed) return null;

      emit(
        current.copyWith(
          clearPaying: true,
          pendingReference: checkout.reference,
          outcome: CheckoutOutcome.waiting,
          clearMessage: true,
        ),
      );
      return checkout.paymentUrl;
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(current.copyWith(clearPaying: true, message: f.userMessage));
      }
      // Un paiement précédent vient peut-être d'être constaté par le
      // serveur (`subscription_payment_received`) : l'accès est à relire.
      await _plan.refresh();
      return null;
    }
  }

  /// Constate l'issue du paiement ouvert chez Wave.
  Future<void> confirmPending() async {
    final current = state;
    if (current is! SubscriptionPlansLoaded) return;
    final reference = current.pendingReference;
    if (reference == null) return;

    try {
      final status = await _repository.confirm(reference);
      if (isClosed) return;

      switch (status) {
        case SubscriptionPaymentStatus.success:
          await _plan.refresh();
          if (!isClosed) {
            emit(
              current.copyWith(
                clearPending: true,
                outcome: CheckoutOutcome.paid,
              ),
            );
          }
        case SubscriptionPaymentStatus.pending:
          emit(current.copyWith(outcome: CheckoutOutcome.waiting));
        case SubscriptionPaymentStatus.failed ||
            SubscriptionPaymentStatus.expired:
          emit(
            current.copyWith(
              clearPending: true,
              outcome: CheckoutOutcome.failed,
            ),
          );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(current.copyWith(message: f.userMessage));
    }
  }
}
