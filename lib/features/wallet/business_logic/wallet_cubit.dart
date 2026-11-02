import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/wallet_model.dart';
import '../data/repositories/wallet_repository.dart';
import 'wallet_state.dart';

/// Portefeuilles des résidences et dernières demandes de retrait.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repository) : super(const WalletInitial());

  final WalletRepository _repository;

  Future<void> load() async {
    // Au rechargement, l'écran garde ses chiffres : un indicateur plein écran
    // à chaque tirage vers le bas ferait clignoter les soldes.
    if (state is! WalletLoaded) emit(const WalletLoading());

    try {
      // En parallèle : les trois lectures sont indépendantes. Les réglages
      // de retrait se replient sur le minimum historique : un serveur qui ne
      // les sert pas encore ne doit pas masquer les soldes.
      final results = await Future.wait<Object>([
        _repository.getWallets(),
        _repository.getWithdrawals(),
        _repository.getPayoutSettings().catchError(
          (Object _) => PayoutSettings.fallback,
        ),
      ]);
      if (!isClosed) {
        emit(
          WalletLoaded(
            wallets: results[0] as List<WalletModel>,
            withdrawals: results[1] as List<WithdrawalModel>,
            payoutSettings: results[2] as PayoutSettings,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(WalletError(f.userMessage));
    }
  }
}

/// Envoie une demande de retrait depuis la feuille.
///
/// Sans file hors ligne : le solde se vérifie au serveur, au moment du débit.
class WithdrawalRequestCubit extends Cubit<WithdrawalRequestState> {
  WithdrawalRequestCubit(this._repository)
    : super(const WithdrawalRequestIdle());

  final WalletRepository _repository;

  Future<void> submit(
    String walletId, {
    required int amount,
    required int payoutSlot,
  }) async {
    emit(const WithdrawalRequestSubmitting());
    try {
      final withdrawal = await _repository.requestWithdrawal(
        walletId,
        amount: amount,
        payoutSlot: payoutSlot,
      );
      if (!isClosed) emit(WithdrawalRequestSuccess(withdrawal));
    } on AppFailure catch (f) {
      if (!isClosed) emit(WithdrawalRequestFailure(f.userMessage));
    }
  }
}

/// Enregistre les numéros Wave de retrait depuis leur feuille.
class PayoutNumbersCubit extends Cubit<PayoutNumbersState> {
  PayoutNumbersCubit(this._repository) : super(const PayoutNumbersIdle());

  final WalletRepository _repository;

  Future<void> save(List<PayoutNumber> numbers) async {
    emit(const PayoutNumbersSaving());
    try {
      final saved = await _repository.savePayoutNumbers(numbers);
      if (!isClosed) emit(PayoutNumbersSaved(saved));
    } on AppFailure catch (f) {
      if (!isClosed) emit(PayoutNumbersFailure(f.userMessage));
    }
  }
}
