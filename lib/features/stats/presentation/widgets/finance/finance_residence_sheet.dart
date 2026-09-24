import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
    return showModalBottomSheet<FinanceScopeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          FinanceResidenceSheet(residences: residences, selectedId: selectedId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Périmètre du relevé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Restreint à une résidence, le relevé retient le revenu '
                      'de ses logements, ses charges communes et celles de ses '
                      'logements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Flexible(child: _body(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    void select(String? residenceId) =>
        Navigator.of(context).pop(FinanceScopeSelection(residenceId));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // « Tout le parc » en tête, et non en fin de liste : c'est le choix
          // qui lève la restriction, on doit le trouver sans parcourir les
          // résidences.
          _ScopeOption(
            title: 'Tout le parc',
            subtitle: 'Tous les biens et toutes les charges',
            icon: Icons.home_work_outlined,
            isSelected: selectedId == null,
            onTap: () => select(null),
          ),
          const SizedBox(height: 8),

          if (residences.isEmpty)
            const _EmptyView()
          else
            for (final residence in residences) ...[
              _ScopeOption(
                title: residence.name,
                subtitle: switch (residence.unitsCount) {
                  0 => residence.address.city,
                  1 => '${residence.address.city} · 1 logement',
                  final count => '${residence.address.city} · $count logements',
                },
                icon: Icons.apartment_rounded,
                isSelected: selectedId == residence.id,
                onTap: () => select(residence.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Un périmètre — une résidence, ou tout le parc — tel qu'on le choisit.
///
/// Reprend l'option de la feuille de rattachement : les deux listent des
/// résidences avec un choix « sans restriction » en tête.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : AppColors.surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.black : AppColors.grey500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.black : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Aucune résidence à proposer.
///
/// « Tout le parc » reste affiché au-dessus : le relevé est consultable sans
/// résidence, seule la restriction est impossible.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Text(
        'Aucune résidence enregistrée : il n’y a pas de périmètre plus '
        'restreint que le parc entier.',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
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
