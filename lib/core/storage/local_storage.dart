import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/property_manager_model.dart';
import '../theme/theme_controller.dart';

class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _propertyManagerKey = 'property_manager';
  static const String _sessionRoleKey = 'session_role';
  static const String _planAccessKey = 'plan_access';
  static const String _accountNameKey = 'account_name';

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

  /// Nom du compte connecté : l'accueil salue sans requête, donc hors ligne.
  /// Distinct du brouillon `property_manager`, qui n'existe que le temps
  /// d'une saisie du dossier de validation.
  Future<void> saveAccountName(String name) async {
    await _prefs.setString(_accountNameKey, name);
  }

  String? getAccountName() => _prefs.getString(_accountNameKey);

  Future<void> clearAccountName() async {
    await _prefs.remove(_accountNameKey);
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

  /// Clé sous laquelle easy_localization mémorise la langue choisie dans le
  /// profil. Fixée par le paquet, elle n'est recopiée ici que pour la garder.
  static const String localeKey = 'locale';

  /// Efface la session, mais pas l'apparence ni la langue choisies : une
  /// préférence d'affichage n'appartient pas au compte, et l'écran de
  /// connexion qui suit basculerait sinon de thème ou de langue.
  Future<void> clear() async {
    final theme = _prefs.getString(ThemeController.storageKey);
    final locale = _prefs.getString(localeKey);
    await _prefs.clear();
    if (theme != null) {
      await _prefs.setString(ThemeController.storageKey, theme);
    }
    if (locale != null) await _prefs.setString(localeKey, locale);
  }
}
