import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/api_paths.dart';

void main() {
  group('basePathForRole', () {
    test('le gérant lit ses propres routes', () {
      expect(basePathForRole('gerant'), '/api/v1/gerant');
    });

    test('le propriétaire garde les siennes', () {
      expect(basePathForRole('proprio'), '/api/v1/proprio');
    });

    test('un rôle inconnu retombe sur le propriétaire', () {
      // Le serveur reste maître : un rôle qu'on ne connaît pas encore ne doit
      // pas ouvrir le préfixe gérant, qui lèverait un 403 incompréhensible.
      expect(basePathForRole('client'), '/api/v1/proprio');
      expect(basePathForRole(''), '/api/v1/proprio');
    });
  });

  group('isOwnerOnlyPath', () {
    test('l’abonnement est fermé au gérant', () {
      expect(isOwnerOnlyPath('/api/v1/proprio/subscription'), isTrue);
    });

    test('le dépôt de photos est fermé au gérant', () {
      expect(isOwnerOnlyPath('/api/v1/proprio/properties/images'), isTrue);
    });

    test('une route gérant ne l’est pas', () {
      expect(isOwnerOnlyPath('/api/v1/gerant/bookings'), isFalse);
    });
  });
}
