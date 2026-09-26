import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../residence/data/models/residence_model.dart';

class FinanceResidenceSheet extends StatelessWidget {
  const FinanceResidenceSheet({
    super.key,
    required this.residences,
    this.selectedId,
  });

  final List<ResidenceModel> residences;
  final String? selectedId;

  static Future<FinanceScopeSelection?> show(
    BuildContext context, {
    required List<ResidenceModel> residences,
    String? selectedId,
  }) {
    return showAppSheet<FinanceScopeSelection>(
      context: context,
      builder: (_) =>
          FinanceResidenceSheet(residences: residences, selectedId: selectedId),
    );
  }

  @override
  Widget build(BuildContext context) {
    void select(String? residenceId) =>
        Navigator.of(context).pop(FinanceScopeSelection(residenceId));

    return AppSheet(
      title: 'Périmètre du relevé',
      description:
          'Restreint à une résidence, le relevé retient le revenu de ses '
          'logements, ses charges communes et celles de ses logements.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // « Tout le parc » en tête, et non en fin de liste : c'est le choix
          // qui lève la restriction, on doit le trouver sans parcourir les
          // résidences.
          AppOptionTile(
            title: 'Tout le parc',
            description: 'Tous les biens et toutes les charges',
            icon: LucideIcons.building,
            selected: selectedId == null,
            onTap: () => select(null),
          ),
          const SizedBox(height: 8),
          // Aucune résidence : « Tout le parc » reste proposé au-dessus, le
          // relevé est consultable sans résidence, seule la restriction est
          // impossible.
          if (residences.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Aucune résidence enregistrée : il n’y a pas de périmètre '
                'plus restreint que le parc entier.',
                style: context.text.bodySmall,
              ),
            )
          else
            for (final residence in residences) ...[
              AppOptionTile(
                title: residence.name,
                description: switch (residence.unitsCount) {
                  0 => residence.address.city,
                  1 => '${residence.address.city} · 1 logement',
                  final count => '${residence.address.city} · $count logements',
                },
                icon: AppSectionIcons.residences,
                selected: selectedId == residence.id,
                onTap: () => select(residence.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Choix confirmé dans la feuille.
///
/// Enveloppe la valeur parce que `null` est un choix légitime — « tout le
/// parc » — qu'un `pop(null)` d'annulation rendrait indiscernable.
class FinanceScopeSelection {
  const FinanceScopeSelection(this.residenceId);

  final String? residenceId;
}
