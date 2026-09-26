import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';

import '../../data/models/gerant_account_model.dart';

/// Un gérant dans la liste : sa coordonnée de connexion, son périmètre et son
/// état.
///
/// Calquée sur `ResidenceCard` — même gabarit, même badge, même bouton
/// d'action à droite : les deux listes se lisent de la même façon. Le statut
/// suspendu suit la grammaire commune : rouge, arrêté par une décision.
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
    final count = gerant.propertiesCount;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Un compte suspendu se reconnaît dès la pastille : le badge seul
          // se lit trop tard dans une liste parcourue du regard.
          IconChip(
            icon: AppSectionIcons.managers,
            accent: gerant.isActive ? AppAccent.neutral : AppAccent.red,
            size: 40,
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
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (gerant.contact != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // `contact` rend l'e-mail ou le téléphone : l'icône
                      // suit, sans quoi un gérant inscrit par téléphone voit
                      // son numéro précédé d'une arobase.
                      Icon(
                        gerant.email != null
                            ? LucideIcons.atSign
                            : LucideIcons.phone,
                        size: 12,
                        color: context.tokens.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gerant.contact!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Un périmètre vide est signalé en clair, en ambre : le
                    // compte existe mais le gérant ne voit rien.
                    AppBadge(
                      label: switch (count) {
                        0 => 'Aucun logement',
                        1 => '1 logement',
                        _ => '$count logements',
                      },
                      icon: count == 0 ? LucideIcons.info : LucideIcons.doorOpen,
                      tone: count == 0 ? AppAccent.amber : AppAccent.neutral,
                    ),
                    // N'est affiché que pour un compte suspendu : marquer
                    // « Actif » sur chaque ligne d'une liste où presque tout
                    // l'est n'apprend rien et charge la carte.
                    if (!gerant.isActive)
                      StatusBadge(label: 'Suspendu', tone: StatusTone.stopped),
                  ],
                ),
              ],
            ),
          ),
          if (onToggleStatus != null)
            AppIconButton(
              icon: gerant.isActive ? LucideIcons.ban : LucideIcons.circleCheck,
              label: gerant.isActive ? 'Suspendre' : 'Réactiver',
              danger: gerant.isActive,
              onPressed: onToggleStatus,
            ),
        ],
      ),
    );
  }
}
