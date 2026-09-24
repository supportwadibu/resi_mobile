import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../../property/data/models/property_model.dart';

/// Grille de remises par durée du bien choisi, en lecture seule.
///
/// Distincte du choix du type de séjour, qui ne porte que sur la durée
/// d'occupation d'une journée : un palier ne se sélectionne pas, il s'atteint
/// en allongeant le séjour. Les afficher épargne au propriétaire de retenir la
/// grille de chaque bien au moment d'annoncer un prix au comptoir.
class StayTierHints extends StatelessWidget {
  const StayTierHints({
    required this.tiers,
    required this.activeDiscountPercent,
    super.key,
  });

  /// Paliers du bien, triés par durée croissante.
  final List<PriceTier> tiers;

  /// Remise qui s'applique aux dates saisies. `0` si aucun palier n'est atteint.
  final int activeDiscountPercent;

  @override
  Widget build(BuildContext context) {
    // Rien à montrer d'un bien sans grille — ceux enregistrés avant les
    // paliers, comme ceux qui n'en accordent aucun.
    if (tiers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Remises sur la durée',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tier in tiers)
                _TierChip(
                  tier: tier,
                  // Un seul palier s'applique à la fois : celui dont la remise
                  // est effectivement retenue pour les dates saisies.
                  active: tier.discountPercent == activeDiscountPercent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier, required this.active});

  final PriceTier tier;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.success : AppColors.grey200,
          width: active ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.success,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            'dès ${tier.minDays} j',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '−${tier.discountPercent} %',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
