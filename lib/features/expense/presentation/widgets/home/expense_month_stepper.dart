import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';

/// Mois affiché entre deux flèches, pour passer au mois voisin d'un geste.
///
/// Partagé par l'écran des dépenses et sa feuille de filtres : le même mois se
/// règle de la même façon aux deux endroits.
class ExpenseMonthStepper extends StatelessWidget {
  const ExpenseMonthStepper({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;

  /// Passage au mois suivant. Désactivé d'office sur le mois en cours : aucune
  /// dépense ne peut être datée d'un mois à venir.
  final VoidCallback onNext;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.background,
      shape: AppRadius.outlined(AppRadius.md, t.border),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            AppIconButton(
              icon: LucideIcons.chevronLeft,
              label: 'expense.previous_month'.tr(),
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(
                  DateFormat(
                    'MMMM yyyy',
                    context.locale.toString(),
                  ).format(month),
                ),
                textAlign: TextAlign.center,
                style: context.text.titleSmall,
              ),
            ),
            AppIconButton(
              icon: LucideIcons.chevronRight,
              label: 'expense.next_month'.tr(),
              onPressed: _isCurrentMonth ? null : onNext,
            ),
          ],
        ),
      ),
    );
  }
}
