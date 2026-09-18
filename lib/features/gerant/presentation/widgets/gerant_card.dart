import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

import '../../data/models/gerant_account_model.dart';

/// Un gérant dans la liste : sa coordonnée de connexion, son périmètre et son
/// état.
///
/// Calquée sur `ResidenceCard` — même gabarit, même badge, même bouton
/// d'action à droite : les deux listes se lisent de la même façon.
class GerantCard extends StatelessWidget {
  const GerantCard({
    super.key,
    required this.gerant,
    this.onTap,
    this.onToggleStatus,
  });

  final GerantAccountModel gerant;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

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
                // Un compte suspendu se reconnaît dès l'icône : le badge seul
                // se lit trop tard dans une liste parcourue du regard.
                color: gerant.isActive ? AppColors.infoBg : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 20,
                color: gerant.isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gerant.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.valueSmall,
                  ),
                  if (gerant.contact != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.alternate_email_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gerant.contact!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ScopeBadge(count: gerant.propertiesCount),
                      const SizedBox(width: 6),
                      _StatusBadge(isActive: gerant.isActive),
                    ],
                  ),
                ],
              ),
            ),
            if (onToggleStatus != null) ...[
              const SizedBox(width: 8),
              _StatusButton(
                isActive: gerant.isActive,
                onPressed: onToggleStatus!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Suspension ou réactivation, à la même échelle que le reste de la carte.
class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.isActive, required this.onPressed});

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isActive ? 'Suspendre' : 'Réactiver',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? AppColors.errorBg : AppColors.successBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
            size: 17,
            color: isActive ? AppColors.error : AppColors.success,
          ),
        ),
      ),
    );
  }
}

/// Nombre de logements confiés.
///
/// Un périmètre vide est signalé en clair : le compte existe mais le gérant ne
/// voit rien, et lui affecter des logements est la seule chose à faire ensuite.
class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.count});

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

/// Actif ou suspendu.
///
/// N'est affiché que pour un compte suspendu : marquer « Actif » sur chaque
/// ligne d'une liste où presque tout l'est n'apprend rien et charge la carte.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Suspendu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
