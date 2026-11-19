import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_state.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

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

/// Résidences en puces : noire pour la choisie, bordées sinon. Elles
/// passent à la ligne plutôt que de défiler, pour tout voir d'un coup.
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in residences)
          AppChoiceChip(
            icon: r.id == allResidencesOption.id
                ? LucideIcons.layers
                : LucideIcons.building2,
            label: r.id == allResidencesOption.id ? r.name.tr() : r.name,
            selected: r.id == selectedId,
            onTap: () => onChanged(r.id),
          ),
      ],
    );
  }
}
