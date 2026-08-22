import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this._repository) : super(const ExpenseInitial());
  final ExpenseRepository _repository;

  /// Filtres courants, conservés hors de l'état : un rechargement après
  /// suppression ou création doit les réappliquer, y compris depuis un état
  /// d'erreur où aucun `ExpenseLoaded` ne les porte plus.
  ExpenseFilters _filters = const ExpenseFilters();

  ExpenseFilters get filters => _filters;

  Future<void> load({ExpenseFilters? filters}) async {
    if (filters != null) _filters = filters;

    emit(const ExpenseLoading());
    await _fetchFirstPage();
  }

  /// Applique un nouveau jeu de filtres et recharge depuis la première page.
  Future<void> applyFilters(ExpenseFilters filters) => load(filters: filters);

  Future<void> clearFilters() => load(filters: const ExpenseFilters());

  /// Réapplique les filtres en place — après une création ou une modification.
  Future<void> refresh() => _fetchFirstPage();

  Future<void> _fetchFirstPage() async {
    try {
      // Liste et total en parallèle : deux requêtes indépendantes, dont
      // l'enchaînement doublerait l'attente affichée.
      final results = await Future.wait([
        _repository.getExpensePage(
          propertyId: _filters.propertyId,
          category: _filters.category,
          from: _filters.from,
          to: _filters.to,
        ),
        _repository.getSummary(
          propertyId: _filters.propertyId,
          category: _filters.category,
          from: _filters.from,
          to: _filters.to,
        ),
      ]);

      if (isClosed) return;

      final page = results[0] as ExpensePage;
      emit(
        ExpenseLoaded(
          page.items,
          summary: results[1] as ExpenseSummary,
          filters: _filters,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) emit(ExpenseError(f.userMessage));
    }
  }

  /// Charge la page suivante et l'ajoute à la liste affichée.
  ///
  /// Sans effet si une page est déjà en cours de chargement ou si la dernière
  /// est atteinte : le défilement déclenche l'appel plusieurs fois de suite.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ExpenseLoaded) return;
    if (current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getExpensePage(
        propertyId: _filters.propertyId,
        category: _filters.category,
        from: _filters.from,
        to: _filters.to,
        page: current.currentPage + 1,
      );

      if (isClosed) return;

      emit(
        current.copyWith(
          items: [...current.items, ...page.items],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          isLoadingMore: false,
        ),
      );
    } on AppFailure {
      // La liste déjà chargée reste à l'écran : signaler l'échec en la vidant
      // serait une régression pire que l'absence de page suivante.
      if (!isClosed) emit(current.copyWith(isLoadingMore: false));
    }
  }

  /// Supprime une dépense, puis recharge la liste et le total.
  ///
  /// Retourne `null` en cas de succès, le message d'erreur sinon : l'écran
  /// affiche ainsi l'échec sans perdre la liste déjà à l'écran.
  Future<String?> delete(String id) async {
    try {
      await _repository.delete(id);
      await _fetchFirstPage();
      return null;
    } on AppFailure catch (f) {
      return f.userMessage;
    }
  }
}
