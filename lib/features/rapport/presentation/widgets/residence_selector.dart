import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

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
        color: context.tokens.background,
        border: Border.all(color: context.tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.zero,
          dropdownColor: context.tokens.surface,
          style: context.text.bodyMedium,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: context.tokens.muted,
          ),
          items: residences.map((r) {
            return DropdownMenuItem(
              value: r.id,
              child: Text(r.name, style: context.text.bodyMedium),
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
