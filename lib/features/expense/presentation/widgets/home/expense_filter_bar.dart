import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

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

  /// Nombre de filtres actifs, affiché en pastille.
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
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: hasFilters ? AppColors.black : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: hasFilters
                        ? AppColors.white
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasFilters
                        ? '$activeCount filtre${activeCount > 1 ? 's' : ''}'
                        : 'Filtrer',
                    style: AppTextStyles.valueSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: hasFilters
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (onClear != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: hasFilters
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: isExporting ? null : onExport,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.ios_share_outlined,
                    size: 19,
                    // Estompé quand l'export n'a rien à produire.
                    color: onExport == null
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                  ),
          ),
        ),
      ],
    );
  }
}
