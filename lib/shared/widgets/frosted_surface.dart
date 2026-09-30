import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';

/// Surface translucide et floutée de ce qui flotte au-dessus du contenu :
/// barre des onglets, bouton « Créer », carte des créations.
///
/// Le fond `surface` reste en partie opaque : un flou seul laisserait
/// passer le texte d'une ligne en dessous et rendrait les libellés
/// illisibles. Le filet `border` sépare, sans ombre.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    required this.child,
    this.color,
    this.opacity = 0.72,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;

  /// Teinte du fond, `surface` par défaut.
  final Color? color;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Barre en pilule, bouton en disque.
  static const pill = AppRadius.pill;
  static const card = AppRadius.lg;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Le détourage borne le flou à la surface : sans lui, `BackdropFilter`
    // floute tout ce qui est peint avant, jusqu'aux bords de l'écran. Il
    // rogne aussi l'ondulation des `InkWell` à l'arrondi.
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (color ?? t.surface).withValues(alpha: opacity),
            border: Border.all(color: t.border),
            borderRadius: borderRadius,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
