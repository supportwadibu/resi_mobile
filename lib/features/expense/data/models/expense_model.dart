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

/// Résidence à laquelle une charge commune est imputée, telle que jointe par
/// le serveur.
///
/// Distincte d’`ExpenseProperty` : une charge commune — électricité, gardien —
/// ne concerne aucun logement en particulier et se rattache au lieu.
class ExpenseResidence {
  const ExpenseResidence({
    required this.id,
    required this.name,
    required this.city,
  });

  final String id;
  final String name;
  final String city;

  factory ExpenseResidence.fromJson(Map<String, dynamic> json) {
    return ExpenseResidence(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }
}

/// Dépense engagée sur un bien ou sur une résidence, telle que servie par
/// `/proprio/expenses`.
///
/// **Exactement un** des deux rattachements est renseigné : `propertyId` pour
/// la charge d’un logement, `residenceId` pour une charge commune du lieu.
/// Aucun des deux n’est donc garanti non nul — s’appuyer sur `propertyId` seul
/// afficherait une charge commune sans libellé.
class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.propertyId,
    this.residenceId,
    this.property,
    this.residence,
    this.note,
  });

  final String id;

  /// `null` pour une charge commune de résidence.
  final String? propertyId;

  /// `null` pour une charge de logement.
  final String? residenceId;
  final ExpenseCategory category;
  final double amount;

  /// Date d'engagement de la dépense, distincte de celle de la saisie.
  final DateTime spentAt;

  /// `null` si le bien a été supprimé depuis la saisie, ou si la dépense est
  /// une charge commune.
  final ExpenseProperty? property;

  /// `null` si la résidence a été supprimée depuis, ou si la dépense porte sur
  /// un logement.
  final ExpenseResidence? residence;
  final String? note;

  /// Vrai pour une charge commune du lieu, réparties sur aucune unité.
  bool get isCommonCharge => residenceId != null;

  /// Libellé de la cible, quel que soit son type.
  ///
  /// Une cible supprimée depuis la saisie ne laisse qu’un identifiant : le
  /// repli évite d’afficher une ligne vide dans l’historique.
  String get targetLabel {
    if (residence != null) return residence!.name;
    if (property != null) return property!.title;
    return isCommonCharge ? 'Résidence supprimée' : 'Bien supprimé';
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String? ?? '',
      propertyId: json['property_id'] as String?,
      residenceId: json['residence_id'] as String?,
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
      residence: json['residence'] is Map<String, dynamic>
          ? ExpenseResidence.fromJson(json['residence'] as Map<String, dynamic>)
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
///
/// Les deux constructeurs nommés rendent l’exclusivité impossible à violer :
/// le serveur refuse en 422 une dépense sans cible ou portant les deux, et un
/// seul champ optionnel laisserait l’appelant construire les deux cas fautifs.
class CreateExpensePayload {
  /// Charge d’un logement : ménage, réparation.
  const CreateExpensePayload.forProperty({
    required String this.propertyId,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.note,
  }) : residenceId = null;

  /// Charge commune du lieu : électricité, gardien. Répartie sur aucune unité.
  const CreateExpensePayload.forResidence({
    required String this.residenceId,
    required this.category,
    required this.amount,
    required this.spentAt,
    this.note,
  }) : propertyId = null;

  final String? propertyId;
  final String? residenceId;
  final ExpenseCategory category;
  final double amount;
  final DateTime spentAt;
  final String? note;

  Map<String, dynamic> toJson() => {
    if (propertyId != null) 'property_id': propertyId,
    if (residenceId != null) 'residence_id': residenceId,
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
  /// Modification sans changer le rattachement.
  const UpdateExpensePayload({
    this.category,
    this.amount,
    this.spentAt,
    this.note,
    this.clearNote = false,
  }) : propertyId = null,
       residenceId = null,
       _switchesTarget = false;

  /// Bascule la dépense vers un logement.
  ///
  /// Les deux clés partent ensemble, celle de la résidence à `null` : le serveur
  /// valide le rattachement *résultant*, et poser la nouvelle cible sans
  /// effacer l’ancienne ferait coexister les deux — la dépense serait alors
  /// comptée deux fois dans un relevé de résidence.
  const UpdateExpensePayload.toProperty(
    String this.propertyId, {
    this.category,
    this.amount,
    this.spentAt,
    this.note,
    this.clearNote = false,
  }) : residenceId = null,
       _switchesTarget = true;

  /// Bascule la dépense vers une charge commune de résidence.
  const UpdateExpensePayload.toResidence(
    String this.residenceId, {
    this.category,
    this.amount,
    this.spentAt,
    this.note,
    this.clearNote = false,
  }) : propertyId = null,
       _switchesTarget = true;

  final String? propertyId;
  final String? residenceId;
  final ExpenseCategory? category;
  final double? amount;
  final DateTime? spentAt;
  final String? note;

  /// Efface la note existante. `note: null` signifiant « ne pas toucher », il
  /// faut un signal distinct pour la vider.
  final bool clearNote;

  /// Distingue « je ne touche pas au rattachement » de « je le change ».
  ///
  /// Sans ce drapeau, les deux constructeurs de bascule seraient
  /// indiscernables du constructeur simple : leurs champs non retenus valent
  /// `null`, qui signifie déjà « ne pas toucher ».
  final bool _switchesTarget;

  Map<String, dynamic> toJson() => {
    // Les deux clés voyagent ensemble, `null` compris : c’est ce `null` qui
    // efface l’ancien rattachement côté serveur.
    if (_switchesTarget) ...{
      'property_id': propertyId,
      'residence_id': residenceId,
    },
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
