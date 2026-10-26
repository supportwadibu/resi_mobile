import '../data/models/wallet_model.dart';

/// États du journal d'un portefeuille.
sealed class WalletTransactionsState {
  const WalletTransactionsState();
}

final class WalletTransactionsInitial extends WalletTransactionsState {
  const WalletTransactionsInitial();
}

final class WalletTransactionsLoading extends WalletTransactionsState {
  const WalletTransactionsLoading();
}

final class WalletTransactionsLoaded extends WalletTransactionsState {
  const WalletTransactionsLoaded({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<WalletTransactionModel> items;
  final bool hasMore;
  final bool isLoadingMore;

  WalletTransactionsLoaded copyWith({
    List<WalletTransactionModel>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) => WalletTransactionsLoaded(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

final class WalletTransactionsError extends WalletTransactionsState {
  const WalletTransactionsError(this.message);

  final String message;
}
