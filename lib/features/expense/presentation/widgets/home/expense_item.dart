import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

class ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;

  /// Chevron d'ouverture, affiché quand la ligne mène à l'écran d'édition.
  final bool showChevron;

  const ExpenseItem({
    super.key,
    required this.expense,
    this.showChevron = false,
  });

  /// Jour seul : le mois et l'année sont portés par l'en-tête du groupe, les
  /// répéter sur chaque ligne noierait la date utile.
  static final _dayFormat = DateFormat('d MMM', 'fr');

  @override
  Widget build(BuildContext context) {
    final category = expense.category;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, size: 19, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.label, style: AppTextStyles.valueSmall),
                const SizedBox(height: 3),
                Text(
                  expense.targetLabel,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall,
                ),
                if (expense.note case final note?
                    when note.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(expense.amount),
                style: AppTextStyles.valueSmall.copyWith(color: AppColors.red),
              ),
              const SizedBox(height: 3),
              Text(
                _dayFormat.format(expense.spentAt),
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          if (showChevron) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textLight,
            ),
          ],
        ],
      ),
    );
  }
}
