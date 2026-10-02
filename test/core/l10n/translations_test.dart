import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/translations_fixture.dart';

/// Aplatit un fichier de traduction en clés pointées (`common.retry`).
///
/// Un pluriel (`one` / `other`…) est une seule clé : `plural()` choisit la
/// forme, l'appelant n'en nomme jamais une.
Set<String> _flatKeys(Map<String, dynamic> map, [String prefix = '']) {
  const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};
  final keys = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      if (value.keys.every(pluralForms.contains)) {
        keys.add(key);
      } else {
        keys.addAll(_flatKeys(value, key));
      }
    } else {
      keys.add(key);
    }
  }
  return keys;
}

Iterable<File> _dartSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.gr.dart'));

String _relative(File f) => f.path.replaceAll(r'\', '/');

/// Fichiers dont le français est une **donnée**, pas un libellé : il ne doit
/// pas suivre la langue du téléphone.
const _frenchByDesign = {
  // Lisent les mentions imprimées sur une pièce d'identité ivoirienne.
  'lib/features/clients/data/services/id_card_reading.dart',
  'lib/features/clients/data/services/id_label_parser.dart',
  // Données de démonstration, jamais affichées en production.
  'lib/features/clients/data/models/clients_fake_data.dart',
};

void main() {
  final fr = _flatKeys(readTranslationFile('fr'));
  final en = _flatKeys(readTranslationFile('en'));

  test('le français et l\'anglais déclarent exactement les mêmes clés', () {
    expect(fr.difference(en), isEmpty, reason: 'absentes de en.json');
    expect(en.difference(fr), isEmpty, reason: 'absentes de fr.json');
  });

  test('toute clé appelée dans le code existe dans les traductions', () {
    // Une clé inconnue ne lève pas : easy_localization affiche la clé brute,
    // et l'oubli ne se voit qu'à l'écran.
    final call = RegExp(
      r"""['"]([a-z0-9_]+(?:\.[a-z0-9_]+)+)['"]\s*\.\s*(?:tr|plural)\(|\b(?:tr|plural)\(\s*['"]([a-z0-9_]+(?:\.[a-z0-9_]+)+)['"]""",
    );
    // Une clé peut aussi être rangée dans une liste constante et traduite
    // plus loin (`label: 'nav.home'` puis `item.label.tr()`) : toute chaîne
    // qui commence par un espace de noms des traductions est donc vérifiée.
    final namespaces = readTranslationFile('fr').keys.toSet();
    final bareKey = RegExp(r"""['"]([a-z0-9_]+(?:\.[a-z0-9_]+)+)['"]""");
    final missing = <String>{};
    for (final file in _dartSources()) {
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        final key = match.group(1) ?? match.group(2)!;
        if (!fr.contains(key)) missing.add('${_relative(file)} : $key');
      }
      for (final match in bareKey.allMatches(source)) {
        final key = match.group(1)!;
        // Un chemin d'import (`client_identity.dart`) a la forme d'une clé.
        if (key.endsWith('.dart')) continue;
        if (namespaces.contains(key.split('.').first) && !fr.contains(key)) {
          missing.add('${_relative(file)} : $key');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('aucune date ni aucun montant n\'est figé sur le français', () {
    // `Intl.defaultLocale` suit la langue de l'application : une locale
    // passée en dur l'emporte sur elle et garde « octobre » sur un
    // téléphone en anglais.
    final pinned = RegExp(r"""(DateFormat|NumberFormat)[\w.]*\([^;]*['"]fr(_FR)?['"]""");
    final offenders = [
      for (final file in _dartSources())
        if (pinned.hasMatch(file.readAsStringSync())) _relative(file),
    ];
    expect(offenders, isEmpty);
  });

  test('aucun libellé affiché n\'est écrit en dur', () {
    final literal = RegExp(
      r"""Text\(\s*['"][^'"$]*[A-Za-zÀ-ÿ]{2}"""
      r"""|\b(?:label|title|hint|hintText|labelText|message|subtitle|description|tooltip|confirmLabel|cancelLabel|helperText|errorText|actionLabel|emptyMessage|userMessage)\s*:\s*['"][^'"$]*[A-Za-zÀ-ÿ]{2}"""
      r"""|AppToast\.\w+\(\s*['"]""",
    );
    // Une clé (`'common.retry'`, traduite sur place ou plus loin) est elle
    // aussi une chaîne littérale : l'effacer avant la recherche évite de la
    // prendre pour un libellé. Son existence est vérifiée par le test
    // précédent.
    // Une clé peut se composer à l'exécution (`'gerant_errors.$code'`).
    final translated = RegExp(
      r"""(['"])[a-z0-9_]+(?:\.(?:[a-z0-9_]+|\$\{[^}]+\}|\$\w+))+\1""",
    );
    final offenders = <String>[];
    for (final file in _dartSources()) {
      final path = _relative(file);
      if (_frenchByDesign.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (literal.hasMatch(line.replaceAll(translated, 'key('))) {
          offenders.add('$path:${i + 1}  $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
