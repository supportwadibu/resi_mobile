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

  /// Les deux seuls accents de surface : une carte prend la lavande, le sable
  /// ou reste neutre — deux teintes au plus par écran, pour que l'interface
  /// reste calme. Identiques dans les deux modes : le texte posé dessus reste
  /// sombre, comme sur les maquettes.
  Color get lavender => const Color(0xFFC9C2FF);
  Color get onLavender => const Color(0xFF14112A);
  Color get sand => const Color(0xFFFDE9B9);
  Color get onSand => const Color(0xFF2E2205);

  bool get _isDark => background.computeLuminance() < 0.2;

  /// Verre des surfaces flottantes (barre d'onglets, boutons sur photo ou
  /// carte) : blanc laiteux en clair, prune fumée en sombre.
  Color get glass =>
      _isDark ? const Color(0x8C241A2E) : const Color(0xC7FFFFFF);
  Color get glassBorder =>
      _isDark ? const Color(0x1FFFFFFF) : const Color(0xF2FFFFFF);

  /// Fond des écrans racines : la lueur prune descend du coin haut gauche en
  /// sombre ; en clair elle est transparente et le fond crème reste nu.
  RadialGradient get glowGradient => RadialGradient(
    center: const Alignment(-0.6, -1.1),
    radius: 1.3,
    colors: [glow, glow.withValues(alpha: 0)],
  );

  /// Lueur prune du haut des écrans sombres ; transparente en clair, où le
  /// fond crème suffit.
  Color get glow => _isDark ? const Color(0xFF2E1838) : const Color(0x00FBF6F0);

  static const light = ResiTokens(
    background: Color(0xFFFBF6F0),
    surface: Color(0xFFFFFFFF),
    foreground: Color(0xFF0B0B0F),
    muted: Color(0xFF625C6A),
    border: Color(0xFFE7DED3),
    primary: Color(0xFF0B0B0F),
    primaryForeground: Color(0xFFFFFFFF),
    accentViolet: Color(0xFF4B3FC4),
    accentVioletSoft: Color(0xFFECE8FF),
    accentGreen: Color(0xFF15803D),
    accentGreenSoft: Color(0xFFE8F5EC),
    accentRed: Color(0xFFB42318),
    accentRedSoft: Color(0xFFFEF3F2),
    accentBlue: Color(0xFF3B4FC4),
    accentBlueSoft: Color(0xFFECEFFE),
    accentAmber: Color(0xFF8A5A00),
    accentAmberSoft: Color(0xFFFDE9B9),
  );

  static const dark = ResiTokens(
    background: Color(0xFF07050B),
    surface: Color(0xFF16101C),
    foreground: Color(0xFFF5F3F7),
    muted: Color(0xFFB0A8BA),
    border: Color(0xFF2A2232),
    primary: Color(0xFFF5F3F7),
    primaryForeground: Color(0xFF0B0B0F),
    accentViolet: Color(0xFFC9C2FF),
    accentVioletSoft: Color(0xFF2A2340),
    accentGreen: Color(0xFF4ADE80),
    accentGreenSoft: Color(0xFF0F2A1A),
    accentRed: Color(0xFFFDA29B),
    accentRedSoft: Color(0xFF3A1512),
    accentBlue: Color(0xFFB4C0FF),
    accentBlueSoft: Color(0xFF1C2140),
    accentAmber: Color(0xFFFDE9B9),
    accentAmberSoft: Color(0xFF3A2E14),
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
