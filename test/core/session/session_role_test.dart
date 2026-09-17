import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/core/storage/local_storage.dart';
import 'package:resi_africa/features/auth/data/models/property_manager_model.dart';

/// Double local : les tests unitaires du projet ne touchent aucun stockage
/// réel, et `SharedPreferences` exigerait le binding de plateforme.
class FakeStorage implements LocalStorage {
  String? role;

  @override
  Future<void> saveRole(String value) async => role = value;

  @override
  Future<String?> getRole() async => role;

  @override
  Future<void> clearRole() async => role = null;

  @override
  Future<void> savePropertyManager(PropertyManagerModel manager) async {}

  @override
  Future<PropertyManagerModel?> getPropertyManager() async => null;

  @override
  Future<void> clearPropertyManager() async {}

  @override
  Future<void> clear() async => role = null;
}

void main() {
  group('SessionRole', () {
    test('vaut proprio avant tout chargement', () {
      // Repli le plus sûr : un préfixe gérant ouvert à tort échouerait en 403.
      expect(SessionRole(FakeStorage()).value, 'proprio');
    });

    test('retient le rôle après set', () async {
      final session = SessionRole(FakeStorage());
      await session.set('gerant');

      expect(session.value, 'gerant');
    });

    test('persiste le rôle donné à set', () async {
      final storage = FakeStorage();
      await SessionRole(storage).set('gerant');

      expect(storage.role, 'gerant');
    });

    test('relit le rôle persisté au démarrage', () async {
      final storage = FakeStorage()..role = 'gerant';
      final session = SessionRole(storage);
      await session.restore();

      expect(session.value, 'gerant');
    });

    test('retombe sur proprio quand rien n’est persisté', () async {
      final session = SessionRole(FakeStorage());
      await session.restore();

      expect(session.value, 'proprio');
    });

    test('la déconnexion remet le rôle à proprio', () async {
      final session = SessionRole(FakeStorage());
      await session.set('gerant');
      await session.clear();

      expect(session.value, 'proprio');
    });

    test('la déconnexion efface aussi le rôle persisté', () async {
      // Un rôle gérant qui survivrait à la déconnexion ferait appeler
      // `/gerant/*` par le propriétaire qui se connecte ensuite.
      final storage = FakeStorage();
      final session = SessionRole(storage);
      await session.set('gerant');
      await session.clear();

      expect(storage.role, isNull);
    });
  });
}
