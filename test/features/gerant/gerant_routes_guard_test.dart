import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/router/app_router.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/router/role_guard.dart';

/// Le garde est nommé, pas typé : `_ownerOnlyRoutes` compare des chaînes aux
/// noms que `build_runner` génère. Un écran renommé sans que la règle suive
/// rouvrirait la gestion des gérants au gérant sans rien casser à la
/// compilation — ces tests sont le seul filet.
void main() {
  group('routes de gestion des gérants', () {
    test('les noms générés sont ceux que la règle nomme', () {
      expect(GerantListRoute.name, 'GerantListRoute');
      expect(AddGerantRoute.name, 'AddGerantRoute');
      expect(GerantScopeRoute.name, 'GerantScopeRoute');
    });

    test('le gérant n’atteint aucune des trois', () {
      for (final route in [
        GerantListRoute.name,
        AddGerantRoute.name,
        GerantScopeRoute.name,
      ]) {
        expect(
          isRouteAllowed('gerant', route),
          isFalse,
          reason: '$route doit rester fermée au gérant',
        );
      }
    });

    test('le propriétaire les atteint toutes', () {
      for (final route in [
        GerantListRoute.name,
        AddGerantRoute.name,
        GerantScopeRoute.name,
      ]) {
        expect(isRouteAllowed('proprio', route), isTrue);
      }
    });

    test('les trois routes portent effectivement un garde', () {
      // La règle de `role_guard.dart` ne protège que les routes auxquelles le
      // routeur attache le garde. Nommer la route dans `_ownerOnlyRoutes` sans
      // écrire `guards: [_ownerOnly]` laisse la porte ouverte, et rien à la
      // compilation ne le signale : c'est le seul test qui le voie.
      final routes = {
        for (final route in AppRouter().routes) route.name: route.guards,
      };

      for (final name in [
        GerantListRoute.name,
        AddGerantRoute.name,
        GerantScopeRoute.name,
      ]) {
        expect(
          routes[name],
          isNotEmpty,
          reason: '$name doit porter guards: [_ownerOnly]',
        );
      }
    });

    test('le périmètre transporte l’identifiant du gérant', () {
      // Sans lui, l'écran ne saurait pas quel périmètre remplacer, et le `PUT`
      // partirait sur un identifiant vide.
      final route = GerantScopeRoute(gerantId: 'g-1', gerantName: 'Awa');

      expect(route.args?.gerantId, 'g-1');
      expect(route.args?.gerantName, 'Awa');
    });
  });
}
