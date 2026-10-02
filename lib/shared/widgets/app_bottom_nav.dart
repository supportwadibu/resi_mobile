import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'frosted_surface.dart';

/// Barre des onglets racines, flottante au-dessus du contenu, suivie du
/// bouton « Créer ». Les icônes sont celles des sections (`AppSectionIcons`),
/// reprises sur les tuiles et les en-têtes.
///
/// À poser en `bottomNavigationBar` d'un `Scaffold` en `extendBody` : le
/// contenu défile sous la barre, et le `Scaffold` en reporte la hauteur dans
/// `MediaQuery.paddingOf(context).bottom` pour que la dernière ligne reste
/// atteignable.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.isMenuOpen = false,
    this.onMenuToggle,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onTap;

  final bool isMenuOpen;

  final VoidCallback? onMenuToggle;

  static const barHeight = 64.0;

  static const _items = [
    (icon: AppSectionIcons.home, label: 'nav.home'),
    (icon: AppSectionIcons.bookings, label: 'nav.bookings'),
    (icon: AppSectionIcons.properties, label: 'nav.properties'),
    (icon: AppSectionIcons.stats, label: 'nav.stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FrostedSurface(
                borderRadius: FrostedSurface.pill,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: barHeight,
                    child: Row(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          Expanded(
                            child: _NavItem(
                              icon: _items[i].icon,
                              label: _items[i].label.tr(),
                              selected: i == currentIndex,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onMenuToggle != null) ...[
              const SizedBox(width: 8),
              _CreateButton(isOpen: isMenuOpen, onTap: onMenuToggle!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un onglet : indicateur en pilule derrière l'icône, libellé dessous.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.foreground : t.muted;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: 30,
                // Borné par la largeur de l'onglet : l'indicateur ne déborde
                // jamais sur son voisin ni sur le bord de la pilule.
                constraints: const BoxConstraints(maxWidth: 56),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selected
                      ? t.background
                      : t.background.withValues(alpha: 0),
                  border: Border.all(
                    color: selected ? t.border : t.border.withValues(alpha: 0),
                  ),
                  borderRadius: AppRadius.pill,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 4),
              // Une seule ligne, quitte à réduire un peu le corps : un
              // libellé coupé en deux décalait l'onglet entier.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: context.text.labelMedium!.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: isOpen ? 'common.close'.tr() : 'common.create'.tr(),
      child: SizedBox.square(
        dimension: AppBottomNav.barHeight,
        child: FrostedSurface(
          borderRadius: FrostedSurface.pill,
          color: isOpen ? t.primary : null,
          opacity: isOpen ? 1 : 0.72,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: AnimatedRotation(
                  turns: isOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    LucideIcons.plus,
                    size: 24,
                    color: isOpen ? t.primaryForeground : t.foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
