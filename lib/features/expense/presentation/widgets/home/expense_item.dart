import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/sync_state_badge.dart';

/// Ligne d'une dépense : catégorie, bien concerné, note, montant et jour.
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
  static DateFormat get _dayFormat => DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final category = expense.category;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // L'icône porte la couleur de la catégorie, la même que dans
          // l'anneau de répartition.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: AppRadius.sm,
              border: Border.all(color: t.border),
            ),
            child: Icon(category.icon, size: 16, color: category.colorIn(t)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.label, style: context.text.titleSmall),
                if (expense.syncState case final syncState?) ...[
                  const SizedBox(height: 4),
                  SyncStateBadge(state: syncState),
                ],
                const SizedBox(height: 2),
                Text(
                  expense.targetLabel,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                if (expense.note case final note?
                    when note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.short(expense.amount),
                style: context.text.amount,
              ),
              const SizedBox(height: 2),
              Text(
                _dayFormat.format(expense.spentAt),
                style: context.text.bodySmall,
              ),
            ],
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: t.muted),
          ],
        ],
      ),
    );
  }
}
