import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

/// Variantes du bouton, miroir de `Button` du backoffice.
enum AppButtonVariant {
  /// Action principale de l'écran : noir en clair, blanc en sombre.
  primary,

  /// Action d'appoint : fond de surface, filet.
  secondary,

  /// Action destructrice confirmée : suppression, annulation d'un séjour.
  danger,

  /// Action discrète, sans fond : « Voir tout », « Passer ».
  ghost,
}

/// Taille en paramètre plutôt qu'en `padding` libre : deux boutons de même
/// rôle gardent ainsi la même hauteur d'un écran à l'autre.
enum AppButtonSize { md, sm }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Icône placée avant le libellé : `plus` créer, `pencil` modifier…
  final IconData? icon;

  /// Icône après le libellé, réservée à la navigation (`chevronRight`).
  final IconData? trailingIcon;

  final bool isLoading;

  /// Pleine largeur : bouton d'une barre d'actions ou d'un formulaire.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg, side) = switch (variant) {
      AppButtonVariant.primary => (t.primary, t.primaryForeground, null),
      AppButtonVariant.secondary => (
        t.surface,
        t.foreground,
        BorderSide(color: t.border),
      ),
      AppButtonVariant.danger => (t.danger, t.surface, null),
      AppButtonVariant.ghost => (Colors.transparent, t.muted, null),
    };
    final isSmall = size == AppButtonSize.sm;
    final iconSize = isSmall ? 14.0 : 16.0;
    final textStyle = isSmall
        ? context.text.labelMedium!
        : context.text.labelLarge!;

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(bg),
      foregroundColor: WidgetStatePropertyAll(fg),
      iconColor: WidgetStatePropertyAll(fg),
      overlayColor: WidgetStatePropertyAll(
        (variant == AppButtonVariant.primary ||
                variant == AppButtonVariant.danger)
            ? fg.withValues(alpha: 0.1)
            : t.foreground.withValues(alpha: 0.05),
      ),
      side: side == null ? null : WidgetStatePropertyAll(side),
      elevation: const WidgetStatePropertyAll(0),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
      padding: WidgetStatePropertyAll(
        isSmall
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      minimumSize: WidgetStatePropertyAll(Size(0, isSmall ? 32 : 44)),
      tapTargetSize: isSmall
          ? MaterialTapTargetSize.shrinkWrap
          : MaterialTapTargetSize.padded,
      textStyle: WidgetStatePropertyAll(textStyle),
    );

    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                SizedBox(width: isSmall ? 6 : 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: isSmall ? 4 : 6),
                Icon(trailingIcon, size: iconSize),
              ],
            ],
          );

    final button = Opacity(
      // Même rendu désactivé que le web (`disabled:opacity-60`) : le bouton
      // garde sa couleur, on lit qu'il est inerte sans changer de variante.
      opacity: enabled || isLoading ? 1 : 0.6,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
