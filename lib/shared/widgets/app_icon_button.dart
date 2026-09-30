import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';

/// Bouton à icône seule, miroir de `IconButton` du backoffice. Le `label` sert
/// d'infobulle et de libellé pour les lecteurs d'écran : une icône seule n'a
/// pas de nom sans lui.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.bordered = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Action destructrice : l'icône passe au rouge.
  final bool danger;

  /// Filet autour du bouton, pour une action posée sur une photo ou isolée
  /// dans un en-tête.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          color: danger ? t.danger : t.foreground,
          disabledColor: t.muted.withValues(alpha: 0.5),
          style: IconButton.styleFrom(
            shape: AppRadius.smShape,
            backgroundColor: bordered ? t.surface : null,
            side: bordered ? BorderSide(color: t.border) : null,
            minimumSize: const Size.square(40),
          ),
        ),
      ),
    );
  }
}
