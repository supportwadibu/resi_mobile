import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/router/role_guard.dart';

void main() {
  group('actionsForRole', () {
    test('le propriétaire garde ses cinq actions', () {
      expect(actionsForRole('proprio', _allActionKeys), hasLength(5));
    });

    test('le gérant perd la finance et les rapports', () {
      // Les agrégats du propriétaire — revenu net, tendances, parc entier —
      // ne relèvent pas de lui. Ses propres chiffres vivent sur l'accueil.
      expect(actionsForRole('gerant', _allActionKeys), [
        'expenses',
        'clients',
        'residences',
      ]);
    });

    test('le gérant garde les dépenses dans la grille', () {
      // La saisie de dépenses fait partie de son travail quotidien : elle
      // reste une entrée de la grille, et ne devient pas un onglet.
      expect(actionsForRole('gerant', _allActionKeys), contains('expenses'));
    });
  });

  group('featuresForRole', () {
    test('le propriétaire garde ses quatre créations', () {
      expect(featuresForRole('proprio', _allFeatureKeys), hasLength(4));
    });

    test('le gérant ne crée pas de bien', () {
      expect(featuresForRole('gerant', _allFeatureKeys), [
        'add_reservation',
        'add_client',
        'add_expense',
      ]);
    });
  });

  group('isRouteAllowed', () {
    test('le gérant n’atteint pas la création de logement', () {
      expect(isRouteAllowed('gerant', 'AddPropertyRoute'), isFalse);
    });

    test('le gérant n’atteint pas les rapports ni la finance', () {
      expect(isRouteAllowed('gerant', 'ReportRoute'), isFalse);
      expect(isRouteAllowed('gerant', 'FinanceRoute'), isFalse);
    });

    test('le gérant n’atteint pas la gestion des gérants', () {
      expect(isRouteAllowed('gerant', 'GerantListRoute'), isFalse);
    });

    test('le gérant atteint ses écrans quotidiens', () {
      expect(isRouteAllowed('gerant', 'AddReservationRoute'), isTrue);
      expect(isRouteAllowed('gerant', 'ExpenseRoute'), isTrue);
      expect(isRouteAllowed('gerant', 'ClientsRoute'), isTrue);
    });

    test('le propriétaire atteint tout', () {
      expect(isRouteAllowed('proprio', 'AddPropertyRoute'), isTrue);
      expect(isRouteAllowed('proprio', 'ReportRoute'), isTrue);
    });
  });
}

const _allActionKeys = <String>[
  'expenses',
  'finance',
  'reports',
  'clients',
  'residences',
];

const _allFeatureKeys = <String>[
  'add_property',
  'add_reservation',
  'add_client',
  'add_expense',
];
