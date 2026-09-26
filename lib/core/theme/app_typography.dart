import 'package:flutter/material.dart';

import 'resi_tokens.dart';

/// Échelle typographique, calée sur celle de Tailwind qu'emploie le
/// backoffice : un titre d'écran vaut `text-2xl font-semibold`, le corps
/// `text-sm`, une note `text-xs`. Geist est embarquée plutôt que chargée par
/// `google_fonts` : la saisie au comptoir fonctionne hors réseau, police
/// comprise.
abstract final class AppTypography {
  static const fontFamily = 'Geist';

  static TextTheme textTheme(ResiTokens t) {
    TextStyle style(double size, FontWeight weight, Color color, [double? h]) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: h,
          letterSpacing: 0,
        );

    return TextTheme(
      displayLarge: style(36, FontWeight.w600, t.foreground, 1.1),
      displayMedium: style(30, FontWeight.w600, t.foreground, 1.15),
      displaySmall: style(28, FontWeight.w600, t.foreground, 1.2),
      headlineLarge: style(28, FontWeight.w600, t.foreground, 1.2),
      headlineMedium: style(26, FontWeight.w600, t.foreground, 1.25),
      headlineSmall: style(24, FontWeight.w600, t.foreground, 1.3),
      titleLarge: style(18, FontWeight.w600, t.foreground, 1.35),
      titleMedium: style(16, FontWeight.w600, t.foreground, 1.4),
      titleSmall: style(14, FontWeight.w500, t.foreground, 1.4),
      bodyLarge: style(16, FontWeight.w400, t.foreground, 1.5),
      bodyMedium: style(14, FontWeight.w400, t.foreground, 1.45),
      bodySmall: style(12, FontWeight.w400, t.muted, 1.4),
      labelLarge: style(14, FontWeight.w500, t.foreground, 1.2),
      labelMedium: style(12, FontWeight.w500, t.foreground, 1.2),
      labelSmall: style(12, FontWeight.w500, t.muted, 1.2),
    );
  }
}

extension ResiTextContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  /// Corps de texte secondaire (`text-sm text-muted`) : description, ligne
  /// d'appoint sous un titre.
  TextStyle get mutedText =>
      text.bodyMedium!.copyWith(color: tokens.muted);
}

extension ResiTextTheme on TextTheme {
  /// Chiffre clé d'une tuile ou d'un total : chiffres tabulaires, pour que
  /// les montants restent alignés d'une ligne à l'autre.
  TextStyle get figure => headlineSmall!.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Montant dans une ligne de liste ou de détail.
  TextStyle get amount => titleSmall!.copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
