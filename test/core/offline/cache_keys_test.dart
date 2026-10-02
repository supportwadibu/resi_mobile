import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/offline/cache_keys.dart';

void main() {
  group('cacheKeysFor', () {
    test('ne dépend pas de l’ordre des paramètres', () {
      final a = cacheKeysFor(
        owner: 'u1',
        path: '/api/v1/proprio/bookings',
        query: {'page': 1, 'per_page': 20},
      );
      final b = cacheKeysFor(
        owner: 'u1',
        path: '/api/v1/proprio/bookings',
        query: {'per_page': 20, 'page': 1},
      );

      expect(a.exact, b.exact);
    });

    test('distingue deux utilisateurs sur le même appareil', () {
      final a = cacheKeysFor(owner: 'u1', path: '/p', query: const {});
      final b = cacheKeysFor(owner: 'u2', path: '/p', query: const {});

      expect(a.exact, isNot(b.exact));
    });

    test('distingue deux filtres', () {
      final a = cacheKeysFor(owner: 'u1', path: '/p', query: {'status': 'a'});
      final b = cacheKeysFor(owner: 'u1', path: '/p', query: {'status': 'b'});

      expect(a.exact, isNot(b.exact));
    });

    test('sans paramètre daté, pas de clé souple', () {
      final keys = cacheKeysFor(owner: 'u1', path: '/p', query: {'page': 2});

      expect(keys.loose, isNull);
    });

    test('ramène un instant au jour, pour qu’un « jusqu’à maintenant » se '
        'retrouve dans la journée', () {
      final morning = cacheKeysFor(
        owner: 'u1',
        path: '/finance',
        query: {'to': '2026-10-01T08:12:44.120Z'},
      );
      final evening = cacheKeysFor(
        owner: 'u1',
        path: '/finance',
        query: {'to': DateTime.utc(2026, 10, 1, 19, 3)},
      );

      expect(morning.exact, evening.exact);
    });

    test('la clé souple ignore les dates mais garde les autres filtres', () {
      final october = cacheKeysFor(
        owner: 'u1',
        path: '/finance',
        query: {'from': '2026-10-01T00:00:00Z', 'property_id': 'p1'},
      );
      final november = cacheKeysFor(
        owner: 'u1',
        path: '/finance',
        query: {'from': '2026-11-01T00:00:00Z', 'property_id': 'p1'},
      );
      final otherProperty = cacheKeysFor(
        owner: 'u1',
        path: '/finance',
        query: {'from': '2026-11-01T00:00:00Z', 'property_id': 'p2'},
      );

      expect(october.exact, isNot(november.exact));
      expect(october.loose, november.loose);
      expect(november.loose, isNot(otherProperty.loose));
    });

    test('ignore les paramètres nuls', () {
      final a = cacheKeysFor(owner: 'u1', path: '/p', query: {'q': null});
      final b = cacheKeysFor(owner: 'u1', path: '/p', query: const {});

      expect(a.exact, b.exact);
    });
  });
}
