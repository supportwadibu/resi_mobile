import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/core/storage/local_storage.dart';
import 'package:resi_africa/features/auth/data/models/property_manager_model.dart';

/// Stockage en mémoire : les tests unitaires du projet ne touchent aucun
/// stockage réel, et `SharedPreferences` exigerait le binding de plateforme.
///
/// `role` est laissé public : les tests de `SessionRole` vérifient ce qui a
/// été réellement écrit sur le disque, et pas seulement l'état en mémoire.
class MemoryLocalStorage implements LocalStorage {
  String? role;
  String? planAccess;

  @override
  Future<void> savePlanAccess(String code) async => planAccess = code;

  @override
  String? getPlanAccess() => planAccess;

  @override
  Future<void> clearPlanAccess() async => planAccess = null;

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

/// Session de test portant un rôle donné, `proprio` par défaut.
///
/// Les tests existants vérifient des chemins `/proprio/*` : le repli par
/// défaut les laisse inchangés, et seul un test du gérant passe `'gerant'`.
SessionRole sessionRoleFixture([String role = 'proprio']) {
  final session = SessionRole(MemoryLocalStorage());
  // `set` est asynchrone mais n'attend que le stockage en mémoire : le rôle
  // en mémoire est posé dès l'appel, avant que le test ne construise son Dio.
  session.set(role);
  return session;
}
