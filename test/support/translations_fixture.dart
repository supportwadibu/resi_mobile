import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
// `Localization` et `Translations` ne sont pas exportés par le paquet : ce
// sont pourtant les seuls points d'entrée qui chargent une langue sans
// monter de widget.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';

/// Lit un fichier de traduction de l'application tel qu'il est livré.
Map<String, dynamic> readTranslationFile(String lang) =>
    jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

/// Charge [lang] comme langue active, sans widget.
///
/// Les tests unitaires lisent des messages produits hors de l'arbre — une
/// `AppFailure` se construit dans un repository. Sans traductions chargées,
/// `tr()` renverrait la clé, et un test vérifierait la clé au lieu du texte
/// que voit l'utilisateur.
void loadTestTranslations([String lang = 'fr']) {
  EasyLocalization.logger.enableBuildModes = [];
  Intl.defaultLocale = lang;
  Localization.load(
    Locale(lang),
    translations: Translations(readTranslationFile(lang)),
    fallbackTranslations: Translations(readTranslationFile('fr')),
  );
}
