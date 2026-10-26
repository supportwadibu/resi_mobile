import '../data/models/wallet_model.dart';

/// États de l'écran du portefeuille.
sealed class WalletState {
  const WalletState();
}

final class WalletInitial extends WalletState {
  const WalletInitial();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletLoaded extends WalletState {
  const WalletLoaded({
    required this.wallets,
    required this.withdrawals,
    this.payoutSettings = PayoutSettings.fallback,
  });

  final List<WalletModel> wallets;
  final List<WithdrawalModel> withdrawals;

  /// Retrait minimal et numéros Wave enregistrés.
  final PayoutSettings payoutSettings;

  /// Disponible au retrait, toutes résidences confondues.
  double get totalBalance =>
      wallets.fold(0, (sum, wallet) => sum + wallet.balance);
}

final class WalletError extends WalletState {
  const WalletError(this.message);

  final String message;
}

/// États d'une demande de retrait.
sealed class WithdrawalRequestState {
  const WithdrawalRequestState();
}

final class WithdrawalRequestIdle extends WithdrawalRequestState {
  const WithdrawalRequestIdle();
}

final class WithdrawalRequestSubmitting extends WithdrawalRequestState {
  const WithdrawalRequestSubmitting();
}

final class WithdrawalRequestSuccess extends WithdrawalRequestState {
  const WithdrawalRequestSuccess(this.withdrawal);

  final WithdrawalModel withdrawal;
}

/// Échec — réseau, solde insuffisant, montant trop faible. Affiché dans la
/// feuille, qui reste ouverte pour corriger.
final class WithdrawalRequestFailure extends WithdrawalRequestState {
  const WithdrawalRequestFailure(this.message);

  final String message;
}

/// États de l'enregistrement des numéros Wave.
sealed class PayoutNumbersState {
  const PayoutNumbersState();
}

final class PayoutNumbersIdle extends PayoutNumbersState {
  const PayoutNumbersIdle();
}

final class PayoutNumbersSaving extends PayoutNumbersState {
  const PayoutNumbersSaving();
}

final class PayoutNumbersSaved extends PayoutNumbersState {
  const PayoutNumbersSaved(this.numbers);

  final List<PayoutNumber> numbers;
}

/// Refus du serveur — format, doublon — ou réseau : affiché dans la feuille,
/// qui reste ouverte pour corriger.
final class PayoutNumbersFailure extends PayoutNumbersState {
  const PayoutNumbersFailure(this.message);

  final String message;
}
