import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_icons.dart';
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

  static const barHeight = 68.0;

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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: barHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < _items.length; i++) ...[
                          // « Créer » au milieu de la barre, comme sur les
                          // maquettes : l'action principale tombe sous le pouce.
                          if (i == _items.length ~/ 2 && onMenuToggle != null)
                            _CreateButton(
                              isOpen: isMenuOpen,
                              onTap: onMenuToggle!,
                            ),
                          _NavItem(
                            icon: _items[i].icon,
                            label: _items[i].label.tr(),
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un onglet : icône seule, sur disque plein quand il est actif. Le libellé
/// reste pour les lecteurs d'écran et l'infobulle.
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
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? t.primary : t.primary.withValues(alpha: 0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? t.primaryForeground : t.foreground,
            ),
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
        dimension: 54,
        child: FrostedSurface(
          borderRadius: FrostedSurface.pill,
          // Lavande au repos : le seul accent de la barre, qui désigne
          // l'action principale.
          color: isOpen ? t.primary : t.lavender,
          opacity: 1,
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
                    color: isOpen ? t.primaryForeground : t.onLavender,
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
