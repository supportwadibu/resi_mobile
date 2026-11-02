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
      final results = await Future.wait([
        _repository.fetchPlans(),
        _safeOptions(),
      ]);
      if (!isClosed) {
        emit(
          SubscriptionPlansLoaded(
            plans: results[0] as List<SubscriptionPlanModel>,
            options: results[1] as SubscriptionOptionsModel,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(SubscriptionPlansError(f.userMessage));
    }
  }

  /// Options du forfait, sans faire échouer l'écran : sans elles, il reste
  /// possible de payer — seuls la résiliation et le chiffrage des montées
  /// manquent.
  Future<SubscriptionOptionsModel> _safeOptions() async {
    try {
      return await _repository.fetchOptions();
    } on AppFailure {
      return SubscriptionOptionsModel.none;
    }
  }

  /// Relit les options après un changement : paiement constaté, résiliation.
  Future<void> _reloadOptions() async {
    final options = await _safeOptions();
    final current = state;
    if (!isClosed && current is SubscriptionPlansLoaded) {
      emit(current.copyWith(options: options));
    }
  }

  /// Résilie le forfait en cours et rend le montant crédité au portefeuille.
  ///
  /// Lève l'[AppFailure] plutôt que de l'émettre : la résiliation part d'un
  /// dialogue de confirmation, qui affiche l'erreur et reste ouvert.
  Future<double> cancel() async {
    final current = state;
    if (current is! SubscriptionPlansLoaded || current.isCancelling) return 0;

    emit(current.copyWith(isCancelling: true, clearMessage: true));
    try {
      final refunded = await _repository.cancel();
      await _plan.refresh();
      if (!isClosed) {
        emit((state as SubscriptionPlansLoaded).copyWith(isCancelling: false));
      }
      await _reloadOptions();
      return refunded;
    } on AppFailure {
      if (!isClosed && state is SubscriptionPlansLoaded) {
        emit((state as SubscriptionPlansLoaded).copyWith(isCancelling: false));
      }
      rethrow;
    }
  }

  /// Lance le paiement d'un forfait et rend le lien Wave à ouvrir.
  ///
  /// `null` si le serveur refuse — renouvellement trop tôt, passage à un
  /// palier inférieur avant l'échéance — : le motif est alors dans l'état.
  /// Un palier supérieur est une montée : le serveur en réduit le prix des
  /// jours restants.
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
          await _reloadOptions();
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
