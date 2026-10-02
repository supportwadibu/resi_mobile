import 'dart:async';

import 'support/translations_fixture.dart';

/// Exécuté par `flutter test` avant chaque fichier de test.
///
/// Les libellés passent par `tr()`, qui rend la clé brute tant qu'aucune
/// langue n'est chargée : sans ce préambule, chaque test qui lit un texte à
/// l'écran comparerait des clés. Le français est la langue de référence de
/// l'application ; un test qui vérifie l'anglais le charge lui-même.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  loadTestTranslations();
  await testMain();
}
