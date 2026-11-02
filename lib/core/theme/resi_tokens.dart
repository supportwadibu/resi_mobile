import 'package:flutter/material.dart';

/// Jetons de couleur de RESI, communs au mobile et au backoffice.
///
/// Source de vérité : `backoffice/src/app/globals.css`. Les valeurs sont
/// recopiées à l'identique — une teinte changée côté web se reporte ici à la
/// main, comme un DTO dans `types.ts`. Les widgets n'emploient que ces noms
/// (`context.tokens.muted`), jamais une teinte littérale : les deux modes
/// restent ainsi lisibles sans qu'un écran ait à y penser.
///
/// Deux familles :
/// - l'interface (fond, texte, boutons) est en noir et blanc, et `primary`
///   s'inverse d'un mode à l'autre — bouton noir sur fond clair, blanc sur
///   fond noir ;
/// - les accents (violet, vert, rouge, bleu, ambre) servent aux statistiques,
///   icônes et badges. Chacun a une variante `Soft` pour le fond d'une
///   pastille, avec le ton plein posé dessus. En sombre, le ton plein
///   s'éclaircit : un violet foncé sur fond noir manquerait de contraste.
@immutable
class ResiTokens extends ThemeExtension<ResiTokens> {
  const ResiTokens({
    required this.background,
    required this.surface,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.primary,
    required this.primaryForeground,
    required this.accentViolet,
    required this.accentVioletSoft,
    required this.accentGreen,
    required this.accentGreenSoft,
    required this.accentRed,
    required this.accentRedSoft,
    required this.accentBlue,
    required this.accentBlueSoft,
    required this.accentAmber,
    required this.accentAmberSoft,
  });

  final Color background;
  final Color surface;
  final Color foreground;
  final Color muted;
  final Color border;
  final Color primary;
  final Color primaryForeground;

  final Color accentViolet;
  final Color accentVioletSoft;
  final Color accentGreen;
  final Color accentGreenSoft;
  final Color accentRed;
  final Color accentRedSoft;
  final Color accentBlue;
  final Color accentBlueSoft;
  final Color accentAmber;
  final Color accentAmberSoft;

  /// Alias sémantique du rouge pour les erreurs : un écran d'erreur ne doit
  /// pas dépendre du choix de couleur d'un graphique.
  Color get danger => accentRed;
  Color get dangerSurface => accentRedSoft;

  /// Texte posé sur une photo assombrie : identique dans les deux modes,
  /// puisque le voile noir ne change pas.
  Color get overlay => const Color(0xFF000000);
  Color get onOverlay => const Color(0xFFFFFFFF);

  static const light = ResiTokens(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    foreground: Color(0xFF0A0A0A),
    muted: Color(0xFF5F5F66),
    border: Color(0xFFE5E5E8),
    primary: Color(0xFF0A0A0A),
    primaryForeground: Color(0xFFFFFFFF),
    accentViolet: Color(0xFF6D28D9),
    accentVioletSoft: Color(0xFFF3EFFD),
    accentGreen: Color(0xFF15803D),
    accentGreenSoft: Color(0xFFECF8F0),
    accentRed: Color(0xFFB42318),
    accentRedSoft: Color(0xFFFEF3F2),
    accentBlue: Color(0xFF1D4ED8),
    accentBlueSoft: Color(0xFFEEF3FE),
    accentAmber: Color(0xFFB45309),
    accentAmberSoft: Color(0xFFFDF6E9),
  );

  static const dark = ResiTokens(
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    foreground: Color(0xFFFAFAFA),
    muted: Color(0xFFA1A1A8),
    border: Color(0xFF27272A),
    primary: Color(0xFFFAFAFA),
    primaryForeground: Color(0xFF0A0A0A),
    accentViolet: Color(0xFFA78BFA),
    accentVioletSoft: Color(0xFF231A3A),
    accentGreen: Color(0xFF4ADE80),
    accentGreenSoft: Color(0xFF0F2A1A),
    accentRed: Color(0xFFFDA29B),
    accentRedSoft: Color(0xFF3A1512),
    accentBlue: Color(0xFF93B4FD),
    accentBlueSoft: Color(0xFF14203D),
    accentAmber: Color(0xFFFBBF24),
    accentAmberSoft: Color(0xFF33240A),
  );

  /// Ton plein d'un accent. `neutral` rend le texte secondaire.
  Color accent(AppAccent accent) => switch (accent) {
    AppAccent.neutral => muted,
    AppAccent.violet => accentViolet,
    AppAccent.green => accentGreen,
    AppAccent.red => accentRed,
    AppAccent.blue => accentBlue,
    AppAccent.amber => accentAmber,
  };

  /// Fond d'une pastille ou d'un badge. `neutral` n'a pas de fond : il se
  /// dessine avec un filet, comme `border border-border` côté web.
  Color accentSoft(AppAccent accent) => switch (accent) {
    AppAccent.neutral => background,
    AppAccent.violet => accentVioletSoft,
    AppAccent.green => accentGreenSoft,
    AppAccent.red => accentRedSoft,
    AppAccent.blue => accentBlueSoft,
    AppAccent.amber => accentAmberSoft,
  };

  @override
  ResiTokens copyWith() => this;

  /// Pas d'interpolation : les deux jeux basculent d'un bloc, comme
  /// `light-dark()` côté web. Une transition de thème fondue ferait passer
  /// l'interface par des gris qui n'appartiennent à aucun mode.
  @override
  ResiTokens lerp(ResiTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Accents réservés aux statistiques, icônes et badges.
enum AppAccent { neutral, violet, green, red, blue, amber }

extension ResiTokensContext on BuildContext {
  /// Jetons du mode courant.
  ///
  /// Les deux thèmes de l'application les déclarent ; le repli ne sert qu'aux
  /// arbres montés sans eux — tests de widget, `MaterialApp` nu — qui
  /// échoueraient sinon sur un détail de présentation étranger à ce qu'ils
  /// vérifient.
  ResiTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<ResiTokens>() ??
        (theme.brightness == Brightness.dark
            ? ResiTokens.dark
            : ResiTokens.light);
  }
}
