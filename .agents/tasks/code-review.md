# Google Places API integration pour l'autocomplétion de ville

Cette implémentation ajoute l'autocomplétion Google Places dans l'étape de localisation d'une propriété, permettant aux utilisateurs de rechercher une ville via Google Maps en plus de leur position actuelle. L'approche privilégie les appels HTTP directs plutôt qu'un package tiers, avec une dégradation gracieuse en mode hors ligne.

**Watch for:** La sécurité de la clé API est correctement gérée via `String.fromEnvironment`, l'interface se dégrade proprement sans la clé, les coordonnées sont bien transmises aux callbacks parents, et les appels API sont limités aux villes uniquement.

**Verdict**: APPROVED

## High-level view

L'implémentation utilise des appels HTTP directs à l'API Google Places au lieu du package `google_place` initialement prévu, ce qui évite une dépendance externe tout en gardant le contrôle total sur les requêtes. Le service `GooglePlacesService` encapsule l'autocomplétion et la récupération des détails avec une gestion silencieuse des erreurs pour le mode dégradé.

L'interface utilisateur offre deux modes selon la disponibilité de la clé API : recherche autocomplétion complète avec suggestions en temps réel, ou saisie manuelle avec coordonnées par défaut d'Abidjan. L'intégration dans `StepLocationWidget` préserve parfaitement les callbacks existants et ajoute la mise à jour automatique de la carte lors de la sélection d'une ville.

La configuration de sécurité respecte les bonnes pratiques en utilisant `String.fromEnvironment` pour la clé API, évitant tout hardcoding et permettant une compilation sans clé pour le développement.

<details>
<summary>Issues (2)</summary>

1. **Fallback coordinates hardcodées** — Les coordonnées d'Abidjan (5.3364, -3.9772) sont hardcodées dans `CityPickerWidget._onManualSubmit()`. Considérer une constante dans `AppConfig` pour la cohérence.

2. **Gestion d'erreur silencieuse** — Les exceptions dans `GooglePlacesService` sont capturées silencieusement sans logging. Ajouter un log de debug serait utile pour le troubleshooting en développement.

</details>

<details><summary>Details</summary>

## Service GooglePlacesService et approche API directe

L'implémentation utilise des appels HTTP directs plutôt que le package `google_place` prévu, évitant une dépendance externe. L'API limite correctement aux villes avec `types=(cities)` et minimise les coûts avec `fields=name,geometry`.

La gestion d'erreur silencieuse manque de logging pour le debug en développement.

## Interface CityPickerWidget et mode dégradé

Le mode dégradé informe clairement l'utilisateur "Google Places API non configuré" et utilise des coordonnées d'Abidjan hardcodées (5.3364, -3.9772) dans `_onManualSubmit()`. Ces coordonnées devraient être déplacées vers une constante `AppConfig` pour la cohérence.

La recherche utilise un debouncing de 300ms et gère correctement les états de chargement avec un indicateur remplaçant l'icône de recherche.

## Intégration dans StepLocationWidget et callback preservation

Les callbacks existants (`onStreetChanged`, `onCityChanged`, `onCoordinatesChanged`) sont préservés et appelés correctement. Le callback `onCitySelected` met à jour le champ texte, appelle le callback parent, et synchronise la carte avec `_applyPoint(coordinates, moveMap: true)`.

## Configuration et sécurité de la clé API

La clé API utilise `String.fromEnvironment('GOOGLE_PLACES_API_KEY')` avec valeur par défaut vide, évitant le hardcoding. Le service locator enregistre `GooglePlacesService` comme lazy singleton.

## Traductions et internationalisation

</details>

<details>
<summary>File map</summary>

- **lib/core/config/app_config.dart** — Configuration de la clé Google Places API via environment variable
- **lib/core/di/service_locator.dart** — Enregistrement du GooglePlacesService comme lazy singleton
- **lib/features/property/data/services/google_places_service.dart** — Service d'autocomplétion et détails de lieux via HTTP direct
- **lib/features/property/presentation/widgets/add_property/city_picker_widget.dart** — Modal de recherche de ville avec autocomplétion
- **lib/features/property/presentation/widgets/add_property/steps/step_location_widget.dart** — Ajout du bouton de recherche et intégration du sélecteur
- **pubspec.yaml** — Ajout de la dépendance HTTP (déjà présente)
- **assets/translations/fr.json** — Nouvelles clés de traduction pour la recherche de ville
- **assets/translations/en.json** — Traductions anglaises correspondantes

[Voir le diff complet](git diff HEAD~6..HEAD)

</details>