import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Convertit un code ISO 3166-1 alpha-2 en emoji drapeau.
/// 'CI' -> 🇨🇮
///
/// Aucune image ni requête : l'emoji est calculé à partir des deux Regional
/// Indicator Symbols correspondant aux lettres du code.
String countryFlag(String iso2) {
  if (iso2.length != 2) return '';
  const base = 0x1F1E6; // Regional Indicator Symbol Letter A
  final code = iso2.toUpperCase();

  // Hors de A–Z, l'arithmétique produirait un point de code arbitraire.
  for (var i = 0; i < 2; i++) {
    final unit = code.codeUnitAt(i);
    if (unit < 0x41 || unit > 0x5A) return '';
  }

  return String.fromCharCodes([
    base + code.codeUnitAt(0) - 0x41,
    base + code.codeUnitAt(1) - 0x41,
  ]);
}

/// Windows ne dispose d'aucune police couvrant les Regional Indicators : les
/// drapeaux y apparaissent comme deux lettres encadrées. Sur cette plateforme
/// on affiche le code ISO2, plus lisible que des caractères de repli.
bool get supportsFlagEmoji {
  if (kIsWeb) {
    // Le navigateur hérite des polices du système : indécidable côté Dart,
    // et faux sur Windows. On s'abstient.
    return defaultTargetPlatform != TargetPlatform.windows;
  }
  return !Platform.isWindows;
}

/// Drapeau prêt à l'affichage, avec repli textuel sur les plateformes qui ne
/// savent pas rendre l'emoji.
String countryFlagLabel(String iso2) {
  if (!supportsFlagEmoji) return iso2.toUpperCase();
  final flag = countryFlag(iso2);
  return flag.isEmpty ? iso2.toUpperCase() : flag;
}
