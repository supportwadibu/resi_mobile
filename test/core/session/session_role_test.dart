import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/session/session_role.dart';
import '../../support/session_role_fixture.dart';

void main() {
  group('SessionRole', () {
    test('vaut proprio avant tout chargement', () {
      // Repli le plus sûr : un préfixe gérant ouvert à tort échouerait en 403.
      expect(SessionRole(MemoryLocalStorage()).value, 'proprio');
    });

    test('retient le rôle après set', () async {
      final session = SessionRole(MemoryLocalStorage());
      await session.set('gerant');

      expect(session.value, 'gerant');
    });

    test('persiste le rôle donné à set', () async {
      final storage = MemoryLocalStorage();
      await SessionRole(storage).set('gerant');

      expect(storage.role, 'gerant');
    });

    test('relit le rôle persisté au démarrage', () async {
      final storage = MemoryLocalStorage()..role = 'gerant';
      final session = SessionRole(storage);
      await session.restore();

      expect(session.value, 'gerant');
    });

    test('retombe sur proprio quand rien n’est persisté', () async {
      final session = SessionRole(MemoryLocalStorage());
      await session.restore();

      expect(session.value, 'proprio');
    });

    test('la déconnexion remet le rôle à proprio', () async {
      final session = SessionRole(MemoryLocalStorage());
      await session.set('gerant');
      await session.clear();

      expect(session.value, 'proprio');
    });

    test('la déconnexion efface aussi le rôle persisté', () async {
      // Un rôle gérant qui survivrait à la déconnexion ferait appeler
      // `/gerant/*` par le propriétaire qui se connecte ensuite.
      final storage = MemoryLocalStorage();
      final session = SessionRole(storage);
      await session.set('gerant');
      await session.clear();

      expect(storage.role, isNull);
    });
  });
}
