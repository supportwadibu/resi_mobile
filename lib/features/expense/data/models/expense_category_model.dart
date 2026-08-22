import 'package:flutter/material.dart';

import 'expense_model.dart';

/// Poste de dépense tel que dessiné par l'anneau et sa légende.
///
/// Vue de présentation, distincte de [ExpenseCategoryBreakdown] : le graphique
/// n'a besoin que d'un libellé, d'un montant et d'une couleur.
class ExpenseCategoryModel {
  final String label;
  final double amount;
  final Color color;

  const ExpenseCategoryModel({
    required this.label,
    required this.amount,
    required this.color,
  });

  /// Convertit la ventilation servie par l'API en données de graphique.
  factory ExpenseCategoryModel.fromBreakdown(
    ExpenseCategoryBreakdown breakdown,
  ) {
    return ExpenseCategoryModel(
      label: breakdown.category.label,
      amount: breakdown.amount,
      color: breakdown.category.color,
    );
  }

  static List<ExpenseCategoryModel> fromSummary(ExpenseSummary summary) => [
    for (final bucket in summary.byCategory)
      ExpenseCategoryModel.fromBreakdown(bucket),
  ];
}
