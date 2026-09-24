import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/gerant/business_logic/gerant_scope_cubit.dart';

void main() {
  group('sélection du périmètre', () {
    final residence = ResidenceSelection(
      id: 'res-1',
      name: 'Resi Adja',
      propertyIds: const ['p-1', 'p-2', 'p-3'],
    );

    test('cocher une résidence coche tous ses logements', () {
      final selection = toggleResidence(const <String>{}, residence);

      expect(selection, {'p-1', 'p-2', 'p-3'});
    });

    test('décocher une résidence décoche tous ses logements', () {
      final selection = toggleResidence(const {'p-1', 'p-2', 'p-3'}, residence);

      expect(selection, isEmpty);
    });

    test('une résidence partiellement cochée se complète', () {
      // 6 logements sur 10 : le cas que le propriétaire rencontre vraiment.
      final selection = toggleResidence(const {'p-1'}, residence);

      expect(selection, {'p-1', 'p-2', 'p-3'});
    });

    test('un logement se coche seul', () {
      final selection = toggleProperty(const <String>{}, 'p-2');

      expect(selection, {'p-2'});
    });

    test('la sélection transmise est une liste de logements', () {
      // Jamais de residence_id : côté serveur, l'affectation ignore les
      // résidences. « Résidence entière » est un geste d'interface.
      final payload = scopePayload(const {'p-2', 'p-1'});

      expect(payload, {
        'property_ids': ['p-1', 'p-2'],
      });
    });

    test('un périmètre vide reste transmissible', () {
      // Un gérant créé sans logement est légitime : le propriétaire lui en
      // attribuera ensuite. Il ne voit alors rien.
      expect(scopePayload(const <String>{}), {'property_ids': <String>[]});
    });
  });

  _dixLogementsDontSix();
  _valeurDeLaCase();
}

/// Cas réel : une résidence de 10 logements dont 6 seulement sont confiés.
///
/// Verrouillé à part des cas à trois logements : c'est celui que le
/// propriétaire rencontre, et celui où une résidence partiellement cochée doit
/// se compléter au lieu de se vider.
void _dixLogementsDontSix() {
  group('résidence de 10 logements, 6 confiés', () {
    final residence = ResidenceSelection(
      id: 'res-10',
      name: 'Resi Cocody',
      propertyIds: List<String>.generate(10, (i) => 'p-${i + 1}'),
    );

    final confies = <String>{'p-1', 'p-2', 'p-3', 'p-4', 'p-5', 'p-6'};

    test('cocher la résidence ajoute les 4 restants sans toucher aux 6', () {
      final selection = toggleResidence(confies, residence);

      expect(selection.length, 10);
      expect(selection.containsAll(confies), isTrue);
    });

    test('une fois complète, la cocher la vide entièrement', () {
      final complete = toggleResidence(confies, residence);

      expect(toggleResidence(complete, residence), isEmpty);
    });

    test('retirer un logement laisse les cinq autres confiés', () {
      final selection = toggleProperty(confies, 'p-3');

      expect(selection, {'p-1', 'p-2', 'p-4', 'p-5', 'p-6'});
    });

    test('la charge utile ne porte que les logements confiés', () {
      expect(scopePayload(confies), {
        'property_ids': ['p-1', 'p-2', 'p-3', 'p-4', 'p-5', 'p-6'],
      });
    });

    test('la sélection d’origine n’est pas modifiée en place', () {
      // Les fonctions rendent une nouvelle sélection : muter celle de l'état
      // empêcherait le cubit de distinguer l'avant de l'après, et l'écran ne
      // se redessinerait pas.
      final avant = confies.toSet();
      toggleResidence(confies, residence);
      toggleProperty(confies, 'p-9');

      expect(confies, avant);
    });
  });
}

/// Case à cocher d'une résidence : le tiret de l'état mixte n'apparaît que sur
/// une valeur **nulle**.
///
/// Flutter ne dessine le tiret que si `value == null`, même avec
/// `tristate: true`. Un `bool` rendait six logements sur dix visuellement
/// identiques à zéro sur dix.
void _valeurDeLaCase() {
  group('valeur de la case d’une résidence', () {
    test('aucun logement confié : case vide', () {
      expect(residenceCheckboxValue(checkedCount: 0, totalCount: 10), isFalse);
    });

    test('tous confiés : case cochée', () {
      expect(residenceCheckboxValue(checkedCount: 10, totalCount: 10), isTrue);
    });

    test('six sur dix : null, seule valeur qui dessine le tiret', () {
      // Le cas que le propriétaire rencontre vraiment. `false` ici le rendrait
      // indiscernable d'une résidence dont rien n'est confié.
      expect(residenceCheckboxValue(checkedCount: 6, totalCount: 10), isNull);
    });

    test('un seul sur dix reste mixte', () {
      expect(residenceCheckboxValue(checkedCount: 1, totalCount: 10), isNull);
    });

    test('neuf sur dix reste mixte', () {
      // Borne haute : il s'en faut d'un, la case ne doit pas paraître pleine.
      expect(residenceCheckboxValue(checkedCount: 9, totalCount: 10), isNull);
    });

    test('résidence sans logement : case vide, jamais de tiret', () {
      // Rien à confier : un tiret y suggérerait une sélection partielle qui
      // n'existe pas.
      expect(residenceCheckboxValue(checkedCount: 0, totalCount: 0), isFalse);
    });
  });
}
