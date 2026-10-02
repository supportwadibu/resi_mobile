import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/storage/local_storage.dart';
import 'package:resi_africa/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorage.clear', () {
    test('efface la session mais garde le thème et la langue choisis', () async {
      SharedPreferences.setMockInitialValues({
        'session_role': 'proprio',
        ThemeController.storageKey: 'dark',
        LocalStorage.localeKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      await LocalStorage(prefs).clear();

      expect(prefs.getString('session_role'), isNull);
      expect(prefs.getString(ThemeController.storageKey), 'dark');
      // Sans elle, l'écran de connexion qui suit la déconnexion repasserait
      // dans la langue du téléphone au prochain démarrage.
      expect(prefs.getString(LocalStorage.localeKey), 'en');
    });

    test('sans langue choisie, rien n’est inventé', () async {
      SharedPreferences.setMockInitialValues({'session_role': 'proprio'});
      final prefs = await SharedPreferences.getInstance();

      await LocalStorage(prefs).clear();

      expect(prefs.getString(LocalStorage.localeKey), isNull);
    });
  });
}
