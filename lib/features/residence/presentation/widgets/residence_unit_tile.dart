import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

import '../../../property/data/models/property_model.dart';

/// Un logement de la résidence, dans la liste de sa fiche.
class ResidenceUnitTile extends StatelessWidget {
  const ResidenceUnitTile({super.key, required this.unit, this.onTap});

  final PropertyModel unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Le nom d'unité prime : dans une résidence, « Studio 1 »
                    // situe mieux qu'un titre d'annonce rédigé pour la
                    // vitrine publique.
                    unit.unitLabel?.trim().isNotEmpty == true
                        ? unit.unitLabel!
                        : unit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.valueSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.short(unit.pricing.dailyPrice),
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: unit.status),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// État du logement, coloré comme ailleurs dans l'application.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      PropertyStatus.published => (AppColors.success, AppColors.successBg),
      PropertyStatus.rented ||
      PropertyStatus.reserved => (AppColors.info, AppColors.infoBg),
      PropertyStatus.maintenance => (AppColors.warning, AppColors.warningBg),
      PropertyStatus.draft ||
      PropertyStatus.inactive => (AppColors.textSecondary, AppColors.grey100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
