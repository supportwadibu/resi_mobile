import '../data/models/expense_model.dart';

/// Filtres appliqués à l'historique.
///
/// Regroupés en un objet : ils voyagent ensemble du cubit à la feuille de
/// filtres, et les passer un par un multiplierait les signatures.
class ExpenseFilters {
  const ExpenseFilters({
    this.propertyId,
    this.residenceId,
    this.category,
    this.from,
    this.to,
  });

  final String? propertyId;

  /// Restreint aux charges communes d’une résidence.
  ///
  /// Ne se combine pas utilement avec [propertyId] : une dépense ne porte
  /// jamais les deux rattachements.
  final String? residenceId;
  final ExpenseCategory? category;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      propertyId == null &&
      residenceId == null &&
      category == null &&
      from == null &&
      to == null;

  int get activeCount => [
    propertyId,
    residenceId,
    category,
    // Une plage de dates compte pour un seul filtre : elle se règle d'un geste.
    from ?? to,
  ].where((value) => value != null).length;

  ExpenseFilters copyWith({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    bool clearProperty = false,
    bool clearResidence = false,
    bool clearCategory = false,
    bool clearRange = false,
  }) {
    return ExpenseFilters(
      propertyId: clearProperty ? null : propertyId ?? this.propertyId,
      residenceId: clearResidence ? null : residenceId ?? this.residenceId,
      category: clearCategory ? null : category ?? this.category,
      from: clearRange ? null : from ?? this.from,
      to: clearRange ? null : to ?? this.to,
    );
  }
}

sealed class ExpenseState {
  const ExpenseState();
}

final class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

final class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

final class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded(
    this.items, {
    this.summary = ExpenseSummary.empty,
    this.filters = const ExpenseFilters(),
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
  });

  final List<ExpenseModel> items;

  /// Total et ventilation servis par le serveur, qui reste la référence : les
  /// recalculer sur les pages chargées donnerait un total tronqué.
  final ExpenseSummary summary;

  final ExpenseFilters filters;
  final int currentPage;
  final int lastPage;

  /// Chargement d'une page supplémentaire, la liste restant affichée.
  final bool isLoadingMore;

  bool get hasMore => currentPage < lastPage;

  ExpenseLoaded copyWith({
    List<ExpenseModel>? items,
    ExpenseSummary? summary,
    ExpenseFilters? filters,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return ExpenseLoaded(
      items ?? this.items,
      summary: summary ?? this.summary,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);
  final String message;
}
