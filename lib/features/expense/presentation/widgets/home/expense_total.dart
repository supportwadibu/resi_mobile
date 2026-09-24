import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Total dépensé', style: AppTextStyles.labelMedium),
              const Spacer(),
              Text(
                count == 0
                    ? 'Aucune dépense'
                    : '$count dépense${count > 1 ? 's' : ''}',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total),
            style: AppTextStyles.valueMedium.copyWith(color: AppColors.red),
          ),
          if (periodLabel case final label?) ...[
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ],
      ),
    );
  }
}
