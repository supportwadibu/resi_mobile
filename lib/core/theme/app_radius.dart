import 'package:flutter/material.dart';

/// Échelle des arrondis. Un contour se choisit par la taille de ce qu'il
/// entoure, jamais par un rayon écrit à la main : l'arrondi reste
/// proportionné d'un écran à l'autre, et se retouche ici seulement.
///
/// Un filet de séparation (bord haut ou bas seul) reste droit : Flutter
/// refuse un arrondi sur une bordure qui n'entoure pas toute la boîte.
abstract final class AppRadius {
  /// Badges, cases à cocher, barres de jauge, blocs de squelette.
  static const xs = BorderRadius.all(Radius.circular(6));

  /// Pastilles d'icône, boutons icône, vignettes, puces.
  static const sm = BorderRadius.all(Radius.circular(8));

  /// Boutons, champs, lignes de choix, encarts, toasts, sections et cartes.
  static const md = BorderRadius.all(Radius.circular(12));

  /// Feuilles, dialogues, grandes cartes à photo.
  static const lg = BorderRadius.all(Radius.circular(20));

  /// Pilule ou disque : moitié de la hauteur, quelle qu'elle soit.
  static const pill = BorderRadius.all(Radius.circular(999));

  static const xsShape = RoundedRectangleBorder(borderRadius: xs);
  static const smShape = RoundedRectangleBorder(borderRadius: sm);
  static const mdShape = RoundedRectangleBorder(borderRadius: md);
  static const lgShape = RoundedRectangleBorder(borderRadius: lg);

  /// Contour arrondi et bordé, pour un `Material` ou une `Card`.
  static RoundedRectangleBorder outlined(
    BorderRadius radius,
    Color color, [
    double width = 1,
  ]) => RoundedRectangleBorder(
    borderRadius: radius,
    side: BorderSide(color: color, width: width),
  );
}
