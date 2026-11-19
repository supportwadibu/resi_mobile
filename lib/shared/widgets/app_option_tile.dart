import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';
import '../motion/motion.dart';

/// Option d'un choix unique présenté en cartes (type de pièce, mode de
/// réservation, forfait) : icône, titre, description. L'option retenue prend
/// un filet `primary` et une coche ; les autres restent bordées de `border`.
///
/// Préférée à un menu déroulant quand les options sont peu nombreuses et que
/// leur description doit se lire avant de choisir.
class AppOptionTile extends StatelessWidget {
  const AppOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
    this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  /// Élément affiché à droite à la place de la coche (prix, badge).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tile = Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? t.accentVioletSoft : t.surface,
        shape: AppRadius.outlined(
          AppRadius.lg,
          selected ? t.accentViolet : t.border,
          selected ? 1.5 : 1,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? t.surface : t.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: t.foreground),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(description!, style: context.text.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                // La coche se substitue au cercle en grossissant : le choix
                // se confirme sous le doigt.
                if (trailing == null)
                  AnimatedSwitcher(
                    duration: AppMotion.base,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: AppMotion.pop,
                      ),
                      child: child,
                    ),
                    child: Icon(
                      selected ? LucideIcons.circleCheck : LucideIcons.circle,
                      key: ValueKey(selected),
                      size: 18,
                      color: selected ? t.foreground : t.border,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return PressScale(scale: 0.98, enabled: onTap != null, child: tile);
  }
}
