import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.tag, size: 14, color: context.tokens.muted),
              const SizedBox(width: 8),
              Text('Remises sur la durée', style: context.text.bodySmall),
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
    // Le palier atteint prend le vert « acquis » de la grammaire des
    // statuts ; les autres restent neutres.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? context.tokens.accentGreenSoft : null,
        borderRadius: AppRadius.pill,
        border: active ? null : Border.all(color: context.tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            Icon(
              LucideIcons.circleCheck,
              size: 12,
              color: context.tokens.accentGreen,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'dès ${tier.minDays} j',
            style: context.text.labelMedium!.copyWith(
              color: active
                  ? context.tokens.accentGreen
                  : context.tokens.foreground,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '−${tier.discountPercent} %',
            style: context.text.labelMedium!.copyWith(
              color: active ? context.tokens.accentGreen : context.tokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
