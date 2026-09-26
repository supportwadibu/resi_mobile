import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/property_manager_model.dart';

class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _propertyManagerKey = 'property_manager';
  static const String _sessionRoleKey = 'session_role';
  static const String _planAccessKey = 'plan_access';

  Future<void> saveRole(String role) async {
    await _prefs.setString(_sessionRoleKey, role);
  }

  Future<String?> getRole() async {
    return _prefs.getString(_sessionRoleKey);
  }

  Future<void> clearRole() async {
    await _prefs.remove(_sessionRoleKey);
  }

  /// Dernier palier connu, pour que l'écran sache quoi verrouiller au
  /// démarrage hors ligne, avant toute réponse de l'API.
  Future<void> savePlanAccess(String code) async {
    await _prefs.setString(_planAccessKey, code);
  }

  String? getPlanAccess() => _prefs.getString(_planAccessKey);

  Future<void> clearPlanAccess() async {
    await _prefs.remove(_planAccessKey);
  }

  Future<void> savePropertyManager(PropertyManagerModel manager) async {
    final jsonString = jsonEncode(manager.toJson());
    await _prefs.setString(_propertyManagerKey, jsonString);
  }

  Future<PropertyManagerModel?> getPropertyManager() async {
    final jsonString = _prefs.getString(_propertyManagerKey);
    if (jsonString == null) return null;

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return PropertyManagerModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPropertyManager() async {
    await _prefs.remove(_propertyManagerKey);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
