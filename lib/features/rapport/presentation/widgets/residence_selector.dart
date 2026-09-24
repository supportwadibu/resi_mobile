import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Entrée du sélecteur : un `id`/`name` suffisent à l'affichage.
///
/// Pas de dépendance au `ResidenceModel` de la feature `residence`, qui porte
/// adresse, équipements et médias : la sentinelle « Toutes mes résidences »
/// n'a pas de contrepartie côté API, et fabriquer un `ResidenceModel` fictif
/// pour elle serait plus trompeur qu'un type dédié et minimal.
class ReportResidenceOption {
  const ReportResidenceOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ResidenceSelector extends StatelessWidget {
  final List<ReportResidenceOption> residences;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const ResidenceSelector({
    super.key,
    required this.residences,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          style: AppTextStyles.valueSmall,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: residences.map((r) {
            return DropdownMenuItem(
              value: r.id,
              child: Text(r.name, style: AppTextStyles.valueSmall),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
