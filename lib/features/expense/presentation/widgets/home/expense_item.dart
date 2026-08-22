import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static final _dateFormat = DateFormat('d MMMM y', 'fr');

  @override
  Widget build(BuildContext context) {
    final category = expense.category;
    // Le bien peut avoir été supprimé depuis la saisie : la dépense reste,
    // mais son rattachement n'est plus résoluble.
    final propertyLabel = expense.property?.title ?? 'Bien supprimé';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, size: 18, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  propertyLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _dateFormat.format(expense.spentAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                if (expense.note case final note?
                    when note.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(expense.amount),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }
}
