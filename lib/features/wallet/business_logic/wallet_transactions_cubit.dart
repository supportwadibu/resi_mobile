import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/wallet_repository.dart';
import 'wallet_transactions_state.dart';

/// Journal d'un portefeuille : crédits des paiements Wave, retraits et
/// remboursements, page par page.
class WalletTransactionsCubit extends Cubit<WalletTransactionsState> {
  WalletTransactionsCubit(this._repository, this._walletId)
    : super(const WalletTransactionsInitial());

  final WalletRepository _repository;
  final String _walletId;

  int _page = 1;

  Future<void> load() async {
    // Au tirage vers le bas, la liste reste affichée pendant la relecture.
    if (state is! WalletTransactionsLoaded) {
      emit(const WalletTransactionsLoading());
    }

    try {
      final page = await _repository.getTransactions(_walletId);
      _page = page.page;
      if (!isClosed) {
        emit(
          WalletTransactionsLoaded(items: page.items, hasMore: page.hasMore),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(WalletTransactionsError(f.userMessage));
    }
  }

  /// Charge la page suivante et l'ajoute à la liste affichée.
  Future<void> loadMore() async {
    final current = state;
    if (current is! WalletTransactionsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getTransactions(
        _walletId,
        page: _page + 1,
      );
      _page = page.page;
      if (!isClosed) {
        emit(
          current.copyWith(
            items: [...current.items, ...page.items],
            hasMore: page.hasMore,
            isLoadingMore: false,
          ),
        );
      }
    } on AppFailure {
      // La page suivante a échoué : la liste déjà affichée reste plutôt que
      // d'être remplacée par une erreur pleine page ; le prochain défilement
      // retente.
      if (!isClosed) emit(current.copyWith(isLoadingMore: false));
    }
  }
}
