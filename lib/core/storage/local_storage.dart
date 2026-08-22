import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/property_manager_model.dart';

class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _propertyManagerKey = 'property_manager';

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
