import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

/// Barre d'actions de l'historique : filtres et export.
class ExpenseFilterBar extends StatelessWidget {
  const ExpenseFilterBar({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.onClear,
    this.onExport,
    this.isExporting = false,
  });

  /// Nombre de filtres actifs, repris dans le libellé.
  final int activeCount;
  final VoidCallback onTap;

  /// `null` quand aucun filtre n'est posé — le bouton disparaît alors.
  final VoidCallback? onClear;

  /// `null` quand il n'y a rien à exporter.
  final VoidCallback? onExport;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final hasFilters = activeCount > 0;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: hasFilters
                ? 'expense.filters_count'.plural(activeCount)
                : 'expense.filter'.tr(),
            icon: LucideIcons.listFilter,
            // Filtres posés : le bouton passe en noir, pour qu'on lise d'un
            // coup d'œil que la liste n'est pas complète.
            variant: hasFilters
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            expand: true,
            onPressed: onTap,
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 8),
          AppIconButton(
            icon: LucideIcons.x,
            label: 'expense.clear_filters'.tr(),
            bordered: true,
            onPressed: onClear,
          ),
        ],
        const SizedBox(width: 8),
        isExporting
            ? const SizedBox.square(dimension: 40, child: AppLoader(size: 20))
            : AppIconButton(
                icon: LucideIcons.share,
                label: 'expense.export_pdf'.tr(),
                bordered: true,
                // Désactivé quand l'export n'a rien à produire.
                onPressed: onExport,
              ),
      ],
    );
  }
}
