import '../data/models/expense_model.dart';

/// Façon dont la période de l'historique est bornée.
enum ExpensePeriodKind {
  /// Un mois calendaire, du 1er au dernier jour.
  month,

  /// Deux dates choisies librement.
  range,

  /// Aucune borne : tout l'historique.
  all,
}

/// Filtres appliqués à l'historique.
///
/// Regroupés en un objet : ils voyagent ensemble du cubit à la feuille de
/// filtres, et les passer un par un multiplierait les signatures.
class ExpenseFilters {
  const ExpenseFilters({
    this.propertyId,
    this.residenceId,
    this.category,
    this.periodKind = ExpensePeriodKind.all,
    this.from,
    this.to,
  });

  /// Point de départ de l'écran : le mois en cours, sans autre filtre.
  ///
  /// Le total ouvre l'écran et se lit comme « ce que j'ai dépensé ce mois-ci » :
  /// le calculer sur tout l'historique en faisait un cumul sans repère.
  factory ExpenseFilters.initial([DateTime? now]) =>
      const ExpenseFilters().withMonth(now ?? DateTime.now());

  final String? propertyId;

  /// Restreint à une résidence : ses charges communes **et** celles de ses
  /// logements, que le serveur réunit.
  ///
  /// Exclusif de [propertyId] : la feuille de filtres n'en retient qu'un.
  final String? residenceId;
  final ExpenseCategory? category;

  final ExpensePeriodKind periodKind;

  /// Bornes envoyées au serveur, jours inclus. Toutes deux `null` sur
  /// [ExpensePeriodKind.all].
  final DateTime? from;
  final DateTime? to;

  /// Le mois affiché, quand la période est un mois.
  DateTime? get month => periodKind == ExpensePeriodKind.month ? from : null;

  /// Borne la période au mois de [reference].
  ///
  /// `DateTime(année, mois + 1, 0)` donne le dernier jour du mois : Dart
  /// normalise le jour zéro sur la veille du 1er, février et années
  /// bissextiles compris.
  ExpenseFilters withMonth(DateTime reference) => ExpenseFilters(
    propertyId: propertyId,
    residenceId: residenceId,
    category: category,
    periodKind: ExpensePeriodKind.month,
    from: DateTime(reference.year, reference.month),
    to: DateTime(reference.year, reference.month + 1, 0),
  );

  /// La période est-elle celle de l'ouverture de l'écran ?
  bool isCurrentMonth([DateTime? now]) {
    final current = now ?? DateTime.now();
    final shown = month;
    return shown != null &&
        shown.year == current.year &&
        shown.month == current.month;
  }

  /// Aucun filtre, période comprise : tout l'historique.
  bool get isEmpty =>
      propertyId == null &&
      residenceId == null &&
      category == null &&
      from == null &&
      to == null;

  /// Aucun filtre hors du mois en cours : l'état d'ouverture de l'écran.
  bool get isDefault =>
      propertyId == null &&
      residenceId == null &&
      category == null &&
      isCurrentMonth();

  /// Filtres posés au-delà de l'état d'ouverture. Le mois en cours n'en est
  /// pas un : il compterait un filtre que personne n'a choisi.
  int get activeCount => [
    propertyId,
    residenceId,
    category,
    // La période compte pour un seul filtre : elle se règle d'un geste.
    isCurrentMonth() || (from == null && to == null) ? null : periodKind,
  ].where((value) => value != null).length;

  /// Des bornes passées sans [periodKind] forment une plage libre : c'est ce
  /// que pose l'écran Finance, qui suit la fenêtre de son relevé.
  ExpenseFilters copyWith({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    ExpensePeriodKind? periodKind,
    DateTime? from,
    DateTime? to,
    bool clearProperty = false,
    bool clearResidence = false,
    bool clearCategory = false,
    bool clearRange = false,
  }) {
    final rangeChanged = from != null || to != null;
    return ExpenseFilters(
      propertyId: clearProperty ? null : propertyId ?? this.propertyId,
      residenceId: clearResidence ? null : residenceId ?? this.residenceId,
      category: clearCategory ? null : category ?? this.category,
      periodKind: clearRange
          ? ExpensePeriodKind.all
          : periodKind ??
                (rangeChanged ? ExpensePeriodKind.range : this.periodKind),
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
    required this.filters,
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
