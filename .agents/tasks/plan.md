# Plan d'implémentation : Autocomplétion Google Maps pour la sélection de ville

Ce plan détaille l'ajout de l'autocomplétion Google Places API dans l'étape de localisation d'une propriété, permettant aux utilisateurs de choisir entre leur position actuelle (déjà implémentée) et une recherche de ville via Google Maps.

## Architecture et approche

L'implémentation sera basée sur le package `google_place` (activement maintenu) qui offre une API Flutter propre pour Google Places. Le choix se justifie par :
- API moderne supportant Places API (New)
- Configuration via `String.fromEnvironment` (sans imposer de clé au build)
- Compatibilité multiplateforme incluant Flutter Web
- Documentation claire et exemples complets

## Stratégie de fallback

Si la clé Google Places API n'est pas configurée (`String.fromEnvironment` retourne une chaîne vide), l'interface se dégradera gracieusement :
- Le champ ville reste un `AppTextField` classique (saisie libre)
- Aucune suggestion d'autocomplétion n'apparaît
- L'application ne plante pas et reste fonctionnelle
- Un message informatif peut être affiché (optionnel)

## Plan d'implémentation

### 1. Configuration du package et des clés API

- [ ] 1. Ajouter la dépendance `google_place: ^0.6.0` dans pubspec.yaml.
      Installer le package pour l'autocomplétion Google Places API.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/pubspec.yaml
      Vérifier : `flutter pub get` s'exécute sans erreur.

- [ ] 2. Ajouter la configuration de la clé API dans AppConfig.
      Créer une constante `googlePlacesApiKey` utilisant `String.fromEnvironment`.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/core/config/app_config.dart
      Vérifier : `flutter analyze` passe sans erreur sur le fichier modifié.

### 2. Service d'autocomplétion Google Places

- [ ] 3. Créer le service GooglePlacesService pour encapsuler l'API Google Places.
      Service gérant l'autocomplétion avec fallback gracieux si pas de clé API.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/features/property/data/services/google_places_service.dart
      Vérifier : `flutter analyze` passe et les types sont correctement définis.

- [ ] 4. Enregistrer GooglePlacesService dans le service locator.
      Ajouter `registerLazySingleton<GooglePlacesService>` dans setupServiceLocator.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/core/di/service_locator.dart
      Vérifier : `flutter analyze` passe sans erreur de dépendance.

### 3. Widget d'autocomplétion de ville

- [ ] 5. Créer le widget CityAutocompleteField.
      Widget réutilisable gérant l'autocomplétion avec fallback vers champ texte libre.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/shared/widgets/city_autocomplete_field.dart
      Vérifier : `flutter analyze` passe et le widget respecte les conventions du design system.

### 4. Intégration dans l'étape de localisation

- [ ] 6. Modifier StepLocationWidget pour utiliser CityAutocompleteField.
      Remplacer le champ ville par le nouveau widget d'autocomplétion.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/features/property/presentation/widgets/add_property/steps/step_location_widget.dart
      Vérifier : `flutter test` passe sur les tests existants de cette fonctionnalité.

- [ ] 7. Ajouter la gestion des coordonnées depuis les résultats Google Places.
      Récupérer lat/lng depuis Place Details et mettre à jour la carte.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/lib/features/property/presentation/widgets/add_property/steps/step_location_widget.dart
      Vérifier : La carte se met à jour correctement lors de la sélection d'une ville.

### 5. Traductions et interface utilisateur

- [ ] 8. Ajouter les chaînes de traduction nécessaires.
      Clés pour les placeholders, messages d'erreur et instructions d'utilisation.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/assets/translations/fr.json, c:/Divers/perso/Projets/resi/mobile/assets/translations/en.json
      Vérifier : `easy_localization` charge correctement les nouvelles clés.

### 6. Tests et validation

- [ ] 9. Écrire les tests unitaires pour GooglePlacesService.
      Tests couvrant le cas nominal et le fallback sans clé API.
      Fichiers : c:/Divers/perso/Projets/resi/mobile/test/features/property/data/services/google_places_service_test.dart
      Vérifier : `flutter test` passe avec couverture complète du service.

- [ ] 10. Tester manuellement l'intégration complète.
      Validation des deux modes : avec et sans clé Google Places API.
      Fichiers : Mode de test manuel sur l'étape de localisation
      Vérifier : L'autocomplétion fonctionne avec une clé valide et se dégrade proprement sans clé.

## Détails techniques par fichier

### GooglePlacesService (nouveau)

**Localisation :** `c:/Divers/perso/Projets/resi/mobile/lib/features/property/data/services/google_places_service.dart`

**Responsabilités :**
- Encapsuler l'API Google Places via le package `google_place`
- Gérer le fallback gracieux si aucune clé API n'est configurée
- Fournir des méthodes d'autocomplétion et de détails de lieu
- Retourner des modèles Dart typés plutôt que du JSON brut

**Classes principales :**
- `GooglePlacesService` : service principal
- `PlaceSuggestion` : modèle pour les suggestions d'autocomplétion
- `PlaceDetails` : modèle pour les détails complets d'un lieu

**Dépendances :** `google_place`, `AppConfig`

### CityAutocompleteField (nouveau)

**Localisation :** `c:/Divers/perso/Projets/resi/mobile/lib/shared/widgets/city_autocomplete_field.dart`

**Responsabilités :**
- Widget d'autocomplétion respectant le design system existant
- Interface similaire à `AppTextField` pour consistance
- Gestion des états de chargement et d'erreur
- Fallback automatique vers champ texte libre

**API publique :**
```dart
CityAutocompleteField({
  required String label,
  required ValueChanged<String> onCityChanged,
  required ValueChanged<PlaceDetails?> onPlaceSelected,
  TextEditingController? controller,
  String? hint,
})
```

### Modifications de StepLocationWidget

**Changements :**
1. Remplacer le `AppTextField` actuel du champ ville par `CityAutocompleteField`
2. Ajouter la gestion du callback `onPlaceSelected` pour récupérer les coordonnées
3. Mettre à jour la carte quand un lieu est sélectionné via l'autocomplétion
4. Conserver la logique existante de géolocalisation (bouton "Ma position")

**Nouveaux callbacks :**
- `onPlaceSelected(PlaceDetails place)` : déclenché quand l'utilisateur sélectionne un lieu
- Appel automatique de `_applyPoint()` avec les coordonnées du lieu sélectionné

### Configuration AppConfig

**Ajout :**
```dart
static const String googlePlacesApiKey = String.fromEnvironment(
  'GOOGLE_PLACES_API_KEY',
  defaultValue: '',
);

static bool get isGooglePlacesEnabled => googlePlacesApiKey.isNotEmpty;
```

### Traductions

**Nouvelles clés à ajouter :**
- `property_form.city_search_placeholder` : "Rechercher une ville..."
- `property_form.city_autocomplete_error` : "Erreur lors de la recherche"
- `property_form.no_city_found` : "Aucune ville trouvée"
- `property_form.city_search_hint` : "Tapez pour rechercher ou utiliser votre position"

## Ordre d'implémentation et dépendances

1. **Étapes 1-2** : Configuration (indépendantes)
2. **Étapes 3-4** : Service Google Places (dépend des étapes 1-2)
3. **Étape 5** : Widget d'autocomplétion (dépend de l'étape 3)
4. **Étapes 6-7** : Intégration (dépendent de l'étape 5)
5. **Étape 8** : Traductions (peut être fait en parallèle)
6. **Étapes 9-10** : Tests et validation (dernières étapes)

## Vérifications à chaque étape

Chaque étape inclut une commande de vérification spécifique utilisant les outils du projet :
- `flutter pub get` pour les dépendances
- `flutter analyze` pour la validation statique
- `flutter test` pour les tests automatisés
- Tests manuels pour l'intégration UI

Cette approche garantit que chaque modification laisse le projet dans un état buildable et fonctionnel, respectant les conventions existantes du codebase Resi Africa.