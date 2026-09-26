import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apparence choisie : clair, sombre ou celle du système.
///
/// Miroir du cookie `resi_theme` du backoffice, sous la même clé. Sans choix
/// enregistré, l'application suit le système. Une simple préférence
/// d'affichage : elle survit à la déconnexion (voir `LocalStorage.clear`).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_read(_prefs));

  static const storageKey = 'resi_theme';

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) =>
      switch (prefs.getString(storageKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> select(ThemeMode mode) async {
    value = mode;
    if (mode == ThemeMode.system) {
      await _prefs.remove(storageKey);
    } else {
      await _prefs.setString(storageKey, mode.name);
    }
  }
}
