import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/gerant/business_logic/gerant_scope_cubit.dart';
import 'package:resi_africa/features/gerant/presentation/widgets/scope_selector.dart';

/// La case d'une résidence partiellement confiée doit porter `null`.
///
/// Test de widget et non de fonction pure : `residenceCheckboxValue` peut
/// rendre le bon `null` sans que la case le reçoive. C'est le câblage qui a
/// manqué la première fois — la case recevait un `bool`, et six logements sur
/// dix s'affichaient comme zéro sur dix.
void main() {
  /// Résidence de dix logements, dont [confies] sont confiés.
  Widget sujet({required int confies}) {
    final ids = List<String>.generate(10, (i) => 'p-${i + 1}');

    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScopeSelector(
            groups: [
              ResidenceGroup(
                residence: ResidenceSelection(
                  id: 'res-1',
                  name: 'Resi Cocody',
                  propertyIds: ids,
                ),
                properties: [
                  for (final id in ids) PropertyOption(id: id, label: id),
                ],
              ),
            ],
            standalone: const [],
            selection: ids.take(confies).toSet(),
            onToggleResidence: (_) {},
            onToggleProperty: (_) {},
          ),
        ),
      ),
    );
  }

  /// La case de la résidence est la première de l'arbre : les logements sont
  /// repliés tant que la ligne n'est pas dépliée.
  Checkbox caseResidence(WidgetTester tester) =>
      tester.widget<Checkbox>(find.byType(Checkbox).first);

  group('case à cocher d’une résidence', () {
    testWidgets('six sur dix : la case porte null, pas false', (tester) async {
      await tester.pumpWidget(sujet(confies: 6));

      final box = caseResidence(tester);

      // `isNull` et non `isNot(isTrue)` : `false` passerait le second, et c'est
      // précisément la valeur qui effaçait le tiret.
      expect(box.value, isNull);
      expect(box.tristate, isTrue);
    });

    testWidgets('aucun confié : la case porte false', (tester) async {
      await tester.pumpWidget(sujet(confies: 0));

      expect(caseResidence(tester).value, isFalse);
    });

    testWidgets('tous confiés : la case porte true', (tester) async {
      await tester.pumpWidget(sujet(confies: 10));

      expect(caseResidence(tester).value, isTrue);
    });

    testWidgets('vide et partielle ne se ressemblent pas', (tester) async {
      // Le défaut tenait tout entier dans cette comparaison : les deux états
      // rendaient la même case.
      await tester.pumpWidget(sujet(confies: 0));
      final vide = caseResidence(tester).value;

      await tester.pumpWidget(sujet(confies: 6));
      final partielle = caseResidence(tester).value;

      expect(partielle, isNot(vide));
    });

    testWidgets('le sous-titre compte les logements confiés', (tester) async {
      await tester.pumpWidget(sujet(confies: 6));

      expect(find.text('6 confiés sur 10'), findsOneWidget);
    });
  });
}
