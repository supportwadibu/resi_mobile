import 'package:flutter/material.dart';

import 'resi_tokens.dart';

/// Échelle typographique, calée sur celle de Tailwind qu'emploie le
/// backoffice : un titre d'écran vaut `text-2xl font-semibold`, le corps
/// `text-sm`, une note `text-xs`. Urbanist est embarquée plutôt que chargée par
/// `google_fonts` : la saisie au comptoir fonctionne hors réseau, police
/// comprise.
abstract final class AppTypography {
  static const fontFamily = 'Urbanist';

  static TextTheme textTheme(ResiTokens t) {
    TextStyle style(
      double size,
      FontWeight weight,
      Color color, [
      double? h,
      double spacing = 0,
    ]) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: h,
      letterSpacing: spacing,
    );

    // Urbanist dessine plus petit que Geist à corps égal : le texte courant
    // monte d'un point. Les grands titres se resserrent, comme sur les
    // maquettes.
    return TextTheme(
      displayLarge: style(38, FontWeight.w600, t.foreground, 1.05, -0.8),
      displayMedium: style(34, FontWeight.w600, t.foreground, 1.06, -0.6),
      displaySmall: style(30, FontWeight.w600, t.foreground, 1.1, -0.5),
      headlineLarge: style(30, FontWeight.w600, t.foreground, 1.1, -0.5),
      headlineMedium: style(28, FontWeight.w600, t.foreground, 1.15, -0.4),
      headlineSmall: style(26, FontWeight.w700, t.foreground, 1.2, -0.4),
      titleLarge: style(20, FontWeight.w600, t.foreground, 1.3, -0.2),
      titleMedium: style(17, FontWeight.w600, t.foreground, 1.35),
      titleSmall: style(15, FontWeight.w600, t.foreground, 1.4),
      bodyLarge: style(17, FontWeight.w500, t.foreground, 1.5),
      bodyMedium: style(15, FontWeight.w500, t.foreground, 1.45),
      bodySmall: style(13, FontWeight.w500, t.muted, 1.4),
      labelLarge: style(15, FontWeight.w600, t.foreground, 1.2),
      labelMedium: style(13, FontWeight.w600, t.foreground, 1.2),
      labelSmall: style(12, FontWeight.w600, t.muted, 1.2),
    );
  }
}

extension ResiTextContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  /// Corps de texte secondaire (`text-sm text-muted`) : description, ligne
  /// d'appoint sous un titre.
  TextStyle get mutedText => text.bodyMedium!.copyWith(color: tokens.muted);
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
