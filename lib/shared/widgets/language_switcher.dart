import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'choice_tiles.dart';

/// Choix de la langue de l'application, à côté du choix d'apparence.
///
/// Sans choix, l'application suit la langue du téléphone. Une fois choisie,
/// la langue est mémorisée par easy_localization et l'emporte sur celle du
/// téléphone, y compris après une déconnexion.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const _french = Locale('fr');
  static const _english = Locale('en');

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode == 'en' ? _english : _french;
    // Chaque langue s'écrit dans sa propre langue : un lecteur perdu dans une
    // interface qu'il ne comprend pas doit reconnaître la sienne.
    return AppChoiceTiles<Locale>(
      selected: current,
      onSelected: context.setLocale,
      options: [
        AppChoiceTileOption(
          value: _french,
          glyph: 'FR',
          label: 'language.fr'.tr(),
        ),
        AppChoiceTileOption(
          value: _english,
          glyph: 'EN',
          label: 'language.en'.tr(),
        ),
      ],
    );
  }
}
