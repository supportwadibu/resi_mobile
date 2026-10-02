import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Total des dépenses filtrées, en tête de l'historique.
///
/// Placé avant la liste et non sous elle : c'est le chiffre que le
/// propriétaire vient chercher, et le lire supposait auparavant de faire
/// défiler tout le relevé.
class ExpenseTotal extends StatelessWidget {
  const ExpenseTotal({
    super.key,
    required this.total,
    required this.count,
    this.periodLabel,
  });

  final double total;

  /// Nombre de dépenses retenues, qui donne son assise au montant : un total
  /// seul ne dit pas s'il résume trois lignes ou deux cents.
  final int count;

  /// Période couverte, quand un filtre de dates est posé. Sans elle, le total
  /// porte sur tout l'historique et le dire serait un bruit permanent.
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final countLabel = count == 0
        ? 'expense.none'.tr()
        : 'expense.count'.plural(count);
    return StatTile(
      label: 'expense.total_spent'.tr(),
      value: CurrencyFormatter.format(total),
      icon: AppSectionIcons.expenses,
      accent: AppAccent.red,
      note: periodLabel == null ? countLabel : '$countLabel · $periodLabel',
    );
  }
}
