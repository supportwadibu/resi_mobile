import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

import '../../data/models/residence_model.dart';

/// Une résidence dans la liste, avec son nombre de logements.
class ResidenceCard extends StatelessWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.onDelete,
  });

  final ResidenceModel residence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    residence.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.valueSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          residence.address.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _UnitsBadge(count: residence.unitsCount),
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              _DeleteButton(onPressed: onDelete!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Suppression, à la même échelle que le reste de la carte.
///
/// Un `IconButton` imposerait sa zone tactile de 48px et déséquilibrerait la
/// ligne : la cible reste confortable ici sans dominer le titre.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Supprimer',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 17,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

/// Nombre de logements rattachés.
///
/// Une résidence vide est signalée en clair : elle n'est pas encore louable, et
/// c'est la seule chose à faire ensuite.
class _UnitsBadge extends StatelessWidget {
  const _UnitsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;

    final color = isEmpty ? AppColors.warning : AppColors.success;
    final background = isEmpty ? AppColors.warningBg : AppColors.successBg;
    final label = switch (count) {
      0 => 'Aucun logement',
      1 => '1 logement',
      _ => '$count logements',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty ? Icons.info_outline_rounded : Icons.meeting_room_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
