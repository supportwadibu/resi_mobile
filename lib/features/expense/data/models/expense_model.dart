import 'package:flutter/material.dart';

/// Catégorie de dépense, alignée sur `EXPENSE_CATEGORIES` du serveur.
///
/// Le code part à l'API, le libellé et l'icône restent côté client : traduire
/// côté serveur imposerait de redéployer pour corriger un intitulé.
enum ExpenseCategory {
  electricity('electricity', 'Électricité', Icons.bolt_outlined, Color(0xFFF39C12)),
  water('water', 'Eau / SODECI', Icons.water_drop_outlined, Color(0xFF3498DB)),
  internet('internet', 'Internet', Icons.wifi, Color(0xFF1ABC9C)),
  tv('tv', 'Canal+ / TV', Icons.tv_outlined, Color(0xFF34495E)),
  cleaning('cleaning', 'Ménage', Icons.cleaning_services_outlined, Color(0xFF2ECC71)),
  maintenance('maintenance', 'Maintenance', Icons.handyman_outlined, Color(0xFF9B59B6)),
  taxes('taxes', 'Taxes', Icons.receipt_long_outlined, Color(0xFFE74C3C)),
  other('other', 'Autre', Icons.more_horiz, Color(0xFF95A5A6));

  const ExpenseCategory(this.code, this.label, this.icon, this.color);

  final String code;
  final String label;
  final IconData icon;

  /// Couleur de la catégorie dans l'anneau et sa légende, fixée par catégorie
  /// pour qu'un poste garde la même teinte d'un écran à l'autre.
  final Color color;

  static ExpenseCategory? fromCode(String? code) {
    for (final value in ExpenseCategory.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Bien auquel une dépense est imputée, tel que joint par le serveur.
class ExpenseProperty {
  const ExpenseProperty({
    required this.id,
    required this.title,
    required this.city,
  });

  final String id;
  final String title;
  final String city;

  factory ExpenseProperty.fromJson(Map<String, dynamic> json) {
    return ExpenseProperty(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }
}

/// Dépense engagée sur un bien, telle que servie par `/proprio/expenses`.
class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.propertyId,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.property,
    this.note,
  });

  final String id;
  final String propertyId;
  final ExpenseCategory category;
  final double amount;

  /// Date d'engagement de la dépense, distincte de celle de la saisie.
  final DateTime spentAt;

  /// `null` si le bien a été supprimé depuis la saisie.
  final ExpenseProperty? property;
  final String? note;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      category:
          ExpenseCategory.fromCode(json['category'] as String?) ??
          ExpenseCategory.other,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      spentAt:
          DateTime.tryParse(json['spent_at'] as String? ?? '') ??
          DateTime.now(),
      property: json['property'] is Map<String, dynamic>
          ? ExpenseProperty.fromJson(json['property'] as Map<String, dynamic>)
          : null,
      note: json['note'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Date au format attendu par `vine.date()` : `YYYY-MM-DD`, sans heure.
String formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Charge utile de création, distincte du modèle de lecture.
class CreateExpensePayload {
  const CreateExpensePayload({
    required this.propertyId,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.note,
  });

  final String propertyId;
  final ExpenseCategory category;
  final double amount;
  final DateTime spentAt;
  final String? note;

  Map<String, dynamic> toJson() => {
    'property_id': propertyId,
    'category': category.code,
    'amount': amount,
    'spent_at': formatApiDate(spentAt),
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

/// Charge utile de modification.
///
/// Seules les clés fournies partent : l'API applique un patch partiel, et
/// envoyer un champ inchangé risquerait d'écraser une valeur modifiée ailleurs.
class UpdateExpensePayload {
  const UpdateExpensePayload({
    this.propertyId,
    this.category,
    this.amount,
    this.spentAt,
    this.note,
    this.clearNote = false,
  });

  final String? propertyId;
  final ExpenseCategory? category;
  final double? amount;
  final DateTime? spentAt;
  final String? note;

  /// Efface la note existante. `note: null` signifiant « ne pas toucher », il
  /// faut un signal distinct pour la vider.
  final bool clearNote;

  Map<String, dynamic> toJson() => {
    if (propertyId != null) 'property_id': propertyId,
    if (category != null) 'category': category!.code,
    if (amount != null) 'amount': amount,
    if (spentAt != null) 'spent_at': formatApiDate(spentAt!),
    if (clearNote) 'note': null
    else if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };

  bool get isEmpty => toJson().isEmpty;
}

/// Page de dépenses, avec de quoi savoir s'il en reste à charger.
class ExpensePage {
  const ExpensePage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<ExpenseModel> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory ExpensePage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return ExpensePage(
      items:
          (json['data'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ExpenseModel.fromJson)
              .toList() ??
          const [],
      currentPage: (meta['currentPage'] as num?)?.toInt() ?? 1,
      // À défaut de `meta`, on suppose une page unique plutôt que de boucler
      // indéfiniment sur un « il en reste » jamais démenti.
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Ventilation d'un poste de dépense, pour l'anneau et la légende.
class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({
    required this.category,
    required this.amount,
    required this.count,
    required this.sharePercent,
  });

  final ExpenseCategory category;
  final double amount;
  final int count;
  final int sharePercent;

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryBreakdown(
      category:
          ExpenseCategory.fromCode(json['category'] as String?) ??
          ExpenseCategory.other,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      sharePercent: (json['share_percent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Total et ventilation, servis par `/proprio/expenses/summary`.
class ExpenseSummary {
  const ExpenseSummary({
    required this.total,
    required this.count,
    this.byCategory = const [],
  });

  final double total;
  final int count;
  final List<ExpenseCategoryBreakdown> byCategory;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      byCategory:
          (json['by_category'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ExpenseCategoryBreakdown.fromJson)
              .toList() ??
          const [],
    );
  }

  static const empty = ExpenseSummary(total: 0, count: 0);
}
