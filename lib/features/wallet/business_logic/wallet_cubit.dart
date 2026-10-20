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
      // En parallèle : les deux lectures sont indépendantes.
      final results = await Future.wait<Object>([
        _repository.getWallets(),
        _repository.getWithdrawals(),
      ]);
      if (!isClosed) {
        emit(
          WalletLoaded(
            wallets: results[0] as List<WalletModel>,
            withdrawals: results[1] as List<WithdrawalModel>,
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
    required String payoutPhone,
    String? payoutName,
  }) async {
    emit(const WithdrawalRequestSubmitting());
    try {
      final withdrawal = await _repository.requestWithdrawal(
        walletId,
        amount: amount,
        payoutPhone: payoutPhone,
        payoutName: payoutName,
      );
      if (!isClosed) emit(WithdrawalRequestSuccess(withdrawal));
    } on AppFailure catch (f) {
      if (!isClosed) emit(WithdrawalRequestFailure(f.userMessage));
    }
  }
}
