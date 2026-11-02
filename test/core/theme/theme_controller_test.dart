import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/storage/local_storage.dart';
import 'package:resi_africa/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeController', () {
    test('suit le système sans choix enregistré', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(ThemeController(prefs).value, ThemeMode.system);
    });

    test('relit le choix enregistré au démarrage', () async {
      SharedPreferences.setMockInitialValues({'resi_theme': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      expect(ThemeController(prefs).value, ThemeMode.dark);
    });

    test('mémorise un mode forcé, oublie le mode système', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);

      await controller.select(ThemeMode.light);
      expect(prefs.getString(ThemeController.storageKey), 'light');

      // Revenir au système efface la clé : sans choix, le système décide,
      // comme le cookie absent du backoffice.
      await controller.select(ThemeMode.system);
      expect(prefs.getString(ThemeController.storageKey), isNull);
      expect(controller.value, ThemeMode.system);
    });

    test('le choix survit à la purge de la session', () async {
      SharedPreferences.setMockInitialValues({
        'resi_theme': 'dark',
        'session_role': 'proprio',
      });
      final prefs = await SharedPreferences.getInstance();

      await LocalStorage(prefs).clear();

      expect(prefs.getString('session_role'), isNull);
      expect(prefs.getString(ThemeController.storageKey), 'dark');
    });
  });
}
