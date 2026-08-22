import 'package:flutter/material.dart';

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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: hasFilters ? Colors.black : const Color(0xffF5F5FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: hasFilters ? Colors.white : const Color(0xff1D2452),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasFilters
                        ? '$activeCount filtre${activeCount > 1 ? 's' : ''}'
                        : 'Filtrer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasFilters ? Colors.white : const Color(0xff1D2452),
                    ),
                  ),
                  if (onClear != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: hasFilters ? Colors.white : Colors.grey,
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xffF5F5FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 18,
                    // Grisé quand l'export n'a rien à produire.
                    color: onExport == null
                        ? Colors.grey.shade400
                        : const Color(0xff1D2452),
                  ),
          ),
        ),
      ],
    );
  }
}
