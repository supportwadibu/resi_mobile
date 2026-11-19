import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'property_visibility_switch.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/frosted_surface.dart';

class PropertyBottomNavigationBar extends StatelessWidget {
  const PropertyBottomNavigationBar({
    super.key,
    required this.onEditPressed,
    required this.isPublished,
    required this.onVisibilityChanged,
    this.isTogglingVisibility = false,
    this.canChangeVisibility = true,
  });

  final VoidCallback onEditPressed;

  final bool isPublished;

  final ValueChanged<bool> onVisibilityChanged;

  final bool isTogglingVisibility;

  /// Faux quand le rôle ne met pas d'annonce en ligne : la bascule n'est alors
  /// pas construite. `publish` et `unpublish` n'ont pas d'équivalent gérant —
  /// le repository vise `/proprio/...` en dur et le serveur répond 403.
  final bool canChangeVisibility;

  @override
  Widget build(BuildContext context) {
    // Hauteur de son contenu, et non celle de l'écran : un `bottomNavigationBar`
    // reçoit toute la hauteur disponible, et la barre s'y étirait.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            // Liseré sombre très léger et ombre floue : on sent le cadre de la barre
            // sur la page, sans qu'il se lise comme un trait noir.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lg,
                border: Border.all(
                  color: context.tokens.foreground.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.tokens.overlay.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FrostedSurface(
                borderRadius: AppRadius.lg,
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                child: Row(
                  children: [
                    // Un bien est créé en brouillon : sans cette bascule, le
                    // propriétaire n'a aucun moyen de mettre son annonce en ligne.
                    if (canChangeVisibility)
                      Expanded(
                        child: PropertyVisibilitySwitch(
                          isPublished: isPublished,
                          isBusy: isTogglingVisibility,
                          onChanged: onVisibilityChanged,
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'property_detail.edit'.tr(),
                      icon: LucideIcons.pencil,
                      onPressed: onEditPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
