# Rôle gérant — plan d'implémentation (mobile)

> **Pour les agents exécutants :** SOUS-SKILL REQUISE — utiliser
> `superpowers:subagent-driven-development` pour dérouler ce plan tâche par
> tâche. Les étapes utilisent la syntaxe case à cocher (`- [ ]`).

**But :** ouvrir l'application aux comptes de rôle `gerant`, qui servent les
logements que leur propriétaire leur a affectés, et donner au propriétaire de
quoi créer et gérer ces comptes.

**Architecture :** le rôle, déjà porté par la classe `AuthUser` (dans
`auth_model.dart`), devient le point de bascule des chemins d'API et du
**contenu** des écrans. Les routes fermées au
gérant le sont par un garde `auto_route`, non par un bouton masqué.

**La navigation ne change pas.** Les quatre onglets — Accueil, Réservations,
Biens, Stats — le bouton `+` central, ses animations et la barre flottante
restent identiques pour les deux rôles. Ce qui varie est ce qu'ils contiennent :

| Élément | Propriétaire | Gérant |
|---|---|---|
| Onglets | Accueil · Réservations · Biens · Stats | **identiques** |
| Grille Stats | Dépenses · Finance · Rapports · Clients · Résidences | Dépenses · Clients · Résidences |
| Menu `+` | Bien · Réservation · Client · Dépense | Réservation · Client · Dépense |
| Cartes d'accueil | son parc entier | ses logements affectés |

Aucun écran, widget ni composant nouveau côté gérant : les cartes de revenus,
la grille d'actions et le menu flottant sont réemployés tels quels, alimentés
par un périmètre restreint. **Ne pas créer d'onglet « Dépenses »** — la
gestion des dépenses est déjà une entrée de la grille Stats, et l'y promouvoir
casserait la logique de l'interface.

**Pile :** Flutter, Bloc/Cubit, `auto_route`, `get_it`, Dio, SQLite.

**Contrat serveur :** [`api/docs/specs/gerant-design.md`](../../../api/docs/specs/gerant-design.md)
— 22 routes `/api/v1/gerant/*` et 6 routes `/api/v1/proprio/managers/*`,
implémentées, relues et testées côté API.

## Contraintes globales

- Nom du paquet Dart : **`resi_africa`** — les imports de test s'écrivent
  `package:resi_africa/...`. Imports internes en chemins relatifs, comme
  l'existant.
- **Vocabulaire : `Gerant`**, jamais `Manager`. `PropertyManagerModel` existe
  déjà et désigne le **profil du propriétaire** (pièces d'identité, dossier de
  validation) : deux concepts distincts ne doivent pas porter des noms voisins.
- Cubits, pas de Bloc à événements. State en hiérarchie `sealed` de classes
  `final` : `Initial` / `Loading` / `Loaded` / `Error`.
- Un cubit vérifie `if (!isClosed)` avant chaque `emit` suivant un `await`, et
  attrape `AppFailure` pour émettre un état d'erreur porteur d'un message
  affichable.
- Tout nouveau repository ou cubit se déclare dans
  `lib/core/di/service_locator.dart` — `registerLazySingleton` pour les
  repositories, `registerFactory` pour les cubits d'écran.
- Aucune chaîne en dur dans un widget : clé de traduction dans
  `assets/translations/{fr,en}.json`.
- Couleurs et styles pris dans `lib/core/theme/` — les deux thèmes, clair et
  sombre, doivent rester lisibles.
- Les erreurs réseau ne remontent jamais en `DioException` au-dessus du
  repository : `AppFailure.fromDio` les convertit. Lire le `statusCode`, jamais
  le texte du message.
- Après ajout ou renommage d'un écran :
  `dart run build_runner build --delete-conflicting-outputs`. Les `.gr.dart`
  sont générés, jamais édités à la main.
- Commits conventionnels, description en français, sans majuscule initiale.
- **Commiter dans `mobile/` uniquement**, jamais depuis la racine.

---

## Structure des fichiers

**Nouvelle feature `gerant`** — gestion des gérants par le propriétaire :

| Fichier | Responsabilité |
|---|---|
| `lib/features/gerant/data/models/gerant_model.dart` | Fiche gérant + périmètre |
| `lib/features/gerant/data/repositories/gerant_repository.dart` | Les 6 routes propriétaire |
| `lib/features/gerant/business_logic/gerant_cubit.dart` | Liste, création, suspension |
| `lib/features/gerant/business_logic/gerant_scope_cubit.dart` | Sélection du périmètre |
| `lib/features/gerant/presentation/screens/` | Liste, création, périmètre |
| `lib/features/gerant/presentation/router/` | Module `auto_route` |

**Transverse :**

| Fichier | Changement |
|---|---|
| `lib/core/api/api_endpoints.dart` | `basePathForRole`, chemins par rôle |
| `lib/core/router/role_guard.dart` | Garde des routes propriétaire |
| `lib/core/sync/sync_service.dart` | `out_of_scope` comme issue définitive |
| `lib/features/auth/data/models/auth_model.dart` | `isManager` |
| `lib/features/home/presentation/widgets/stats/action_grid.dart` | Grille filtrée par rôle |
| `lib/features/home/presentation/screens/home_screen.dart` | Menu `+` filtré par rôle |

---

## Task 1 : le rôle comme donnée de navigation

Socle de tout le reste : sans lui, rien ne peut bifurquer.

**Fichiers :**
- Modifier : `lib/features/auth/data/models/auth_model.dart:21`
- Créer : `lib/core/api/api_paths.dart`
- Test : `test/core/api/api_paths_test.dart`

**Interfaces produites :**
```dart
// auth_model.dart
bool get isOwner => role == 'proprio';   // existe déjà
bool get isManager => role == 'gerant';  // ajouté

// api_paths.dart
String basePathForRole(String role);
bool isOwnerOnlyPath(String path);
```

- [ ] **Étape 1 : écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/api_paths.dart';

void main() {
  group('basePathForRole', () {
    test('le gérant lit ses propres routes', () {
      expect(basePathForRole('gerant'), '/api/v1/gerant');
    });

    test('le propriétaire garde les siennes', () {
      expect(basePathForRole('proprio'), '/api/v1/proprio');
    });

    test('un rôle inconnu retombe sur le propriétaire', () {
      // Le serveur reste maître : un rôle qu'on ne connaît pas encore ne doit
      // pas ouvrir le préfixe gérant, qui lèverait un 403 incompréhensible.
      expect(basePathForRole('client'), '/api/v1/proprio');
      expect(basePathForRole(''), '/api/v1/proprio');
    });
  });

  group('isOwnerOnlyPath', () {
    test('l’abonnement est fermé au gérant', () {
      expect(isOwnerOnlyPath('/api/v1/proprio/subscription'), isTrue);
    });

    test('le dépôt de photos est fermé au gérant', () {
      expect(isOwnerOnlyPath('/api/v1/proprio/properties/images'), isTrue);
    });

    test('une route gérant ne l’est pas', () {
      expect(isOwnerOnlyPath('/api/v1/gerant/bookings'), isFalse);
    });
  });
}
```

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

Lancer : `flutter test test/core/api/api_paths_test.dart`
Attendu : ÉCHEC — `api_paths.dart` n'existe pas.

- [ ] **Étape 3 : écrire l'implémentation**

```dart
/// Préfixe d'API correspondant au rôle de l'utilisateur connecté.
///
/// Un point de bascule unique : disperser la condition dans chaque repository
/// garantirait qu'un chemin finisse par être oublié, et un gérant appelant une
/// route propriétaire reçoit un 403 que rien n'explique à l'écran.
///
/// Tout rôle inconnu retombe sur le propriétaire. L'inverse ouvrirait le
/// préfixe gérant à un compte sans affectation, dont chaque appel échouerait.
String basePathForRole(String role) {
  return role == 'gerant' ? '/api/v1/gerant' : '/api/v1/proprio';
}

/// Chemins qui n'ont aucun équivalent gérant.
///
/// Ils ne sont pas seulement absents de sa navigation : le serveur les refuse.
/// Les reconnaître permet d'afficher un message juste plutôt qu'un 403 nu.
const _ownerOnlySegments = <String>[
  '/subscription',
  '/properties/images',
  '/reports',
  '/managers',
];

bool isOwnerOnlyPath(String path) {
  if (!path.contains('/proprio')) return false;
  return _ownerOnlySegments.any(path.contains);
}
```

- [ ] **Étape 4 : ajouter `isManager` à `AuthModel`**

Après la ligne 21 :

```dart
  /// Gérant : sert les logements que son propriétaire lui a affectés.
  /// Symétrique de `isOwner`, qui existait avant l'ajout du rôle.
  bool get isManager => role == 'gerant';
```

- [ ] **Étape 5 : lancer les tests et vérifier qu'ils passent**

Lancer : `flutter test && flutter analyze`
Attendu : SUCCÈS, aucune régression.

- [ ] **Étape 6 : commit**

```bash
git add lib/core/api/api_paths.dart lib/features/auth/data/models/auth_model.dart test/core/api/api_paths_test.dart
git commit -m "feat(gerant): resoudre les chemins d'api selon le role"
```

---

## Task 2 : chemins d'API par rôle

**Fichiers :**
- Modifier : `lib/core/api/api_endpoints.dart`
- Test : `test/core/api/api_endpoints_test.dart`

**Interfaces consommées :** `basePathForRole` (Task 1).

**Interfaces produites :** les constantes `proprioBookings`, `proprioClients`,
`proprioExpenses`, `proprioProperties`, `proprioResidences` et leurs variantes
paramétrées deviennent des **fonctions prenant le rôle**.

- [ ] **Étape 1 : écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/api_endpoints.dart';

void main() {
  group('chemins par rôle', () {
    test('les réservations suivent le rôle', () {
      expect(ApiEndpoints.bookings('gerant'), '/api/v1/gerant/bookings');
      expect(ApiEndpoints.bookings('proprio'), '/api/v1/proprio/bookings');
    });

    test('une réservation nommée suit le rôle', () {
      expect(
        ApiEndpoints.booking('gerant', 'bk-1'),
        '/api/v1/gerant/bookings/bk-1',
      );
    });

    test('le carnet clients suit le rôle', () {
      expect(ApiEndpoints.clients('gerant'), '/api/v1/gerant/clients');
    });

    test('les dépenses suivent le rôle', () {
      expect(ApiEndpoints.expenses('gerant'), '/api/v1/gerant/expenses');
    });

    test('le relevé financier suit le rôle', () {
      expect(
        ApiEndpoints.financeOverview('gerant'),
        '/api/v1/gerant/finance/overview',
      );
    });
  });

  group('routes sans équivalent gérant', () {
    test('l’abonnement reste une constante propriétaire', () {
      // Pas de variante par rôle : un gérant n'a pas d'abonnement, et la
      // signature doit le dire plutôt que de produire une URL qui échouera.
      expect(ApiEndpoints.proprioSubscription, contains('/proprio/'));
    });
  });
}
```

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

Lancer : `flutter test test/core/api/api_endpoints_test.dart`

- [ ] **Étape 3 : convertir les chemins partagés**

Dans `api_endpoints.dart`, importer `api_paths.dart` puis convertir, en
conservant les commentaires existants :

```dart
  /// Réservations servies par l'appelant — son parc entier pour le
  /// propriétaire, ses seuls logements affectés pour le gérant.
  static String bookings(String role) => '${basePathForRole(role)}/bookings';

  static String booking(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id';

  static String bookingCancel(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id/cancel';

  static String bookingPayments(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id/payments';

  static String clients(String role) => '${basePathForRole(role)}/clients';

  static String client(String role, String id) =>
      '${basePathForRole(role)}/clients/$id';

  static String expenses(String role) => '${basePathForRole(role)}/expenses';

  static String expense(String role, String id) =>
      '${basePathForRole(role)}/expenses/$id';

  static String properties(String role) =>
      '${basePathForRole(role)}/properties';

  static String property(String role, String id) =>
      '${basePathForRole(role)}/properties/$id';

  static String propertyAvailability(String role, String id) =>
      '${basePathForRole(role)}/properties/$id/availability';

  static String residences(String role) =>
      '${basePathForRole(role)}/residences';

  static String financeOverview(String role) =>
      '${basePathForRole(role)}/finance/overview';
```

**Ne pas convertir** — ces routes n'ont aucun équivalent gérant :
`proprioSubscription`, `proprioProfile`, `proprioPropertyImages`,
`proprioPropertyPublish`, `proprioPropertyUnpublish`, `proprioPropertyStats`,
`proprioBookingStats`, les rapports, les feedbacks.

**Ajouter** les routes de gestion des gérants, côté propriétaire :

```dart
  /// Gérants du propriétaire connecté : comptes et périmètres.
  static const String proprioManagers = '$_v1/proprio/managers';

  static String proprioManager(String id) => '$_v1/proprio/managers/$id';

  /// Remplacement du périmètre — `PUT`, la liste complète des logements
  /// affectés : un ajout et un retrait faits ensemble deviennent une seule
  /// écriture, et l'état obtenu ne dépend pas de l'ordre des requêtes.
  static String proprioManagerProperties(String id) =>
      '$_v1/proprio/managers/$id/properties';

  static String proprioManagerStatus(String id) =>
      '$_v1/proprio/managers/$id/status';
```

- [ ] **Étape 4 : répercuter dans les repositories appelants**

Chaque repository qui employait une constante convertie doit désormais lire le
rôle. Le rôle vient de la session : `sl<AuthCubit>().state` ou du stockage
sécurisé selon ce que fait déjà le repository voisin — **suivre le motif en
place plutôt que d'en introduire un nouveau**.

Repositories concernés : `reservation`, `clients`, `expense`, `property`,
`residence`, `stats`.

`flutter analyze` signale chaque appel non converti : traiter jusqu'à ce qu'il
soit muet.

- [ ] **Étape 5 : lancer la suite**

Lancer : `flutter test && flutter analyze`
Attendu : SUCCÈS, aucune régression sur les tests existants.

- [ ] **Étape 6 : commit**

```bash
git add lib/core/api/api_endpoints.dart lib/features test/core/api/api_endpoints_test.dart
git commit -m "feat(gerant): router les appels d'api selon le role"
```

---

## Task 3 : `out_of_scope` définitif à la synchronisation

Le point le plus délicat du chantier mobile : une erreur ici bouche la file
d'envoi hors ligne, et la saisie au comptoir cesse de fonctionner.

**Fichiers :**
- Modifier : `lib/core/sync/sync_service.dart` (`_handleFailure`, ~ligne 221)
- Modifier : `lib/core/sync/sync_service.dart` (`SyncReport`, ~ligne 15)
- Test : `test/core/sync/sync_scope_test.dart`

**Interfaces produites :**
```dart
enum _SendOutcome { sent, conflict, rejected, retry }  // `rejected` ajouté

class SyncReport {
  final int sent;
  final int conflicts;
  final int rejected;  // ajouté
  final int failed;
}

bool isDefinitiveRejection(int? statusCode, String? code);
```

- [ ] **Étape 1 : écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/sync/sync_service.dart';

void main() {
  group('isDefinitiveRejection', () {
    test('un logement sorti du périmètre ne se rejoue pas', () {
      // Le propriétaire a retiré le logement au gérant entre la saisie et
      // l'envoi. Rejouer bloquerait la file indéfiniment.
      expect(isDefinitiveRejection(403, 'out_of_scope'), isTrue);
    });

    test('un gérant suspendu ne se rejoue pas', () {
      expect(isDefinitiveRejection(403, 'manager_not_assigned'), isTrue);
    });

    test('un conflit de période se rejoue', () {
      // Le propriétaire arbitre, la saisie reste dans la file.
      expect(isDefinitiveRejection(409, 'booking_period_conflict'), isFalse);
    });

    test('une panne réseau se rejoue', () {
      expect(isDefinitiveRejection(null, null), isFalse);
      expect(isDefinitiveRejection(500, null), isFalse);
      expect(isDefinitiveRejection(503, null), isFalse);
    });

    test('un 403 sans code connu se rejoue', () {
      // Un refus qu'on ne sait pas nommer peut être transitoire — un jeton
      // expiré, par exemple. Le supprimer perdrait une saisie du gérant.
      expect(isDefinitiveRejection(403, null), isFalse);
      expect(isDefinitiveRejection(403, 'autre_chose'), isFalse);
    });
  });
}
```

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

Lancer : `flutter test test/core/sync/sync_scope_test.dart`

- [ ] **Étape 3 : écrire l'implémentation**

```dart
/// Codes d'un refus que rejouer ne résoudra jamais.
///
/// `out_of_scope` : le logement a quitté le périmètre du gérant entre la saisie
/// et l'envoi. `manager_not_assigned` : son affectation a été suspendue.
/// Dans les deux cas le serveur refusera identiquement à chaque tentative, et
/// la saisie resterait en tête de file à bloquer tout ce qui suit.
const _definitiveCodes = <String>{'out_of_scope', 'manager_not_assigned'};

/// Ce refus doit-il retirer la saisie de la file plutôt que d'être rejoué ?
///
/// Le code prime sur le statut : un 403 dont on ne reconnaît pas le code peut
/// être transitoire — un jeton expiré que l'interceptor rafraîchira. Supprimer
/// la saisie perdrait le travail du gérant, ce qu'aucune reprise ne rattrape.
bool isDefinitiveRejection(int? statusCode, String? code) {
  if (statusCode != 403) return false;
  if (code == null) return false;
  return _definitiveCodes.contains(code);
}
```

Dans `_handleFailure`, avant le test existant :

```dart
    if (isDefinitiveRejection(failure.statusCode, code)) {
      // Retirée de la file, et signalée : le gérant doit en référer au
      // propriétaire. La garder ferait échouer toute la file derrière elle.
      await _store.removeFromQueue(booking.localId);
      return _SendOutcome.rejected;
    }
```

Ajouter `rejected` à l'énumération, au `SyncReport` et à la boucle de
`synchronize`, sur le motif exact de `conflicts`.

- [ ] **Étape 4 : extraire le code d'erreur de la réponse**

`AppFailure` porte `statusCode` mais le code métier vient du corps JSON.
Vérifier ce que `AppFailure.fromDio` en conserve
(`lib/core/error/failures.dart`) et, si le code est perdu, l'ajouter en champ
optionnel `code`. **Sans lui, la distinction ne peut pas se faire** — et lire
le texte du message est proscrit par les règles du projet.

- [ ] **Étape 5 : annoncer le rejet à l'écran**

`sync_result_listener.dart` affiche déjà le `SyncReport`. Ajouter le cas
`rejected` avec un message distinct de celui du conflit : le conflit s'arbitre,
le rejet se constate. Clés dans `fr.json` et `en.json`.

- [ ] **Étape 6 : lancer la suite**

Lancer : `flutter test && flutter analyze`

- [ ] **Étape 7 : commit**

```bash
git add lib/core/sync lib/core/error lib/features/reservation assets/translations test/core/sync
git commit -m "feat(gerant): retirer de la file une saisie hors perimetre"
```

---

## Task 4 : filtrer le contenu selon le rôle

**La navigation ne change pas.** Quatre onglets, bouton `+` central, barre
flottante : tout reste identique. Seul le contenu de la grille d'actions et du
menu de création varie, et les routes fermées reçoivent un garde.

**Fichiers :**
- Créer : `lib/core/router/role_guard.dart`
- Modifier : `lib/features/home/presentation/widgets/stats/action_grid.dart`
- Modifier : `lib/features/home/presentation/screens/home_screen.dart` (`_features`)
- Modifier : `lib/core/router/app_router.dart`
- Test : `test/core/router/role_guard_test.dart`

**Interfaces consommées :** `isManager` (Task 1).

**Interfaces produites :**
```dart
List<StatsAction> actionsForRole(String role, List<StatsAction> all);
List<FloatingFeature> featuresForRole(String role, List<FloatingFeature> all);
bool isRouteAllowed(String role, String routeName);
class OwnerRouteGuard extends AutoRouteGuard { ... }
```

- [ ] **Étape 1 : écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/router/role_guard.dart';

void main() {
  group('actionsForRole', () {
    test('le propriétaire garde ses cinq actions', () {
      expect(actionsForRole('proprio', _allActionKeys), hasLength(5));
    });

    test('le gérant perd la finance et les rapports', () {
      // Les agrégats du propriétaire — revenu net, tendances, parc entier —
      // ne relèvent pas de lui. Ses propres chiffres vivent sur l'accueil.
      expect(actionsForRole('gerant', _allActionKeys), [
        'expenses',
        'clients',
        'residences',
      ]);
    });

    test('le gérant garde les dépenses dans la grille', () {
      // La saisie de dépenses fait partie de son travail quotidien : elle
      // reste une entrée de la grille, et ne devient pas un onglet.
      expect(actionsForRole('gerant', _allActionKeys), contains('expenses'));
    });
  });

  group('featuresForRole', () {
    test('le propriétaire garde ses quatre créations', () {
      expect(featuresForRole('proprio', _allFeatureKeys), hasLength(4));
    });

    test('le gérant ne crée pas de bien', () {
      expect(featuresForRole('gerant', _allFeatureKeys), [
        'add_reservation',
        'add_client',
        'add_expense',
      ]);
    });
  });

  group('isRouteAllowed', () {
    test('le gérant n’atteint pas la création de logement', () {
      expect(isRouteAllowed('gerant', 'AddPropertyRoute'), isFalse);
    });

    test('le gérant n’atteint pas les rapports ni la finance', () {
      expect(isRouteAllowed('gerant', 'ReportRoute'), isFalse);
      expect(isRouteAllowed('gerant', 'FinanceRoute'), isFalse);
    });

    test('le gérant n’atteint pas la gestion des gérants', () {
      expect(isRouteAllowed('gerant', 'GerantListRoute'), isFalse);
    });

    test('le gérant atteint ses écrans quotidiens', () {
      expect(isRouteAllowed('gerant', 'AddReservationRoute'), isTrue);
      expect(isRouteAllowed('gerant', 'ExpenseRoute'), isTrue);
      expect(isRouteAllowed('gerant', 'ClientsRoute'), isTrue);
    });

    test('le propriétaire atteint tout', () {
      expect(isRouteAllowed('proprio', 'AddPropertyRoute'), isTrue);
      expect(isRouteAllowed('proprio', 'ReportRoute'), isTrue);
    });
  });
}

const _allActionKeys = <String>[
  'expenses',
  'finance',
  'reports',
  'clients',
  'residences',
];

const _allFeatureKeys = <String>[
  'add_property',
  'add_reservation',
  'add_client',
  'add_expense',
];
```

Les deux listes de clés sont écrites en dur dans le test : il porte sur la
**règle de filtrage**, pas sur le contenu des grilles, qui peut évoluer.

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

Lancer : `flutter test test/core/router/role_guard_test.dart`

- [ ] **Étape 3 : écrire `role_guard.dart`**

Les deux fonctions de filtrage sont écrites sur des **clés**, pas sur les
objets : elles restent testables sans monter un widget, et `action_grid.dart`
les applique à sa propre liste.

```dart
import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

/// Entrées de la grille d'actions fermées au gérant.
///
/// `finance` et `reports` portent les agrégats du propriétaire — revenu net,
/// tendances, parc entier —, que la conception lui ferme. `expenses`,
/// `clients` et `residences` restent : ce sont ses outils quotidiens, que le
/// serveur cloisonne déjà sur son périmètre.
const _managerHiddenActions = <String>{'finance', 'reports'};

/// Créations fermées au gérant dans le menu du bouton `+`.
///
/// Il ne crée ni ne supprime de logement. Réservation, client et dépense
/// restent : c'est la saisie au comptoir.
const _managerHiddenFeatures = <String>{'add_property'};

List<String> _keep(String role, List<String> keys, Set<String> hidden) {
  if (role != 'gerant') return keys;
  return keys.where((key) => !hidden.contains(key)).toList();
}

/// Clés d'action retenues pour ce rôle. Même widget, mêmes couleurs, mêmes
/// icônes : seules les entrées fermées disparaissent de la grille.
List<String> actionsForRole(String role, List<String> keys) =>
    _keep(role, keys, _managerHiddenActions);

/// Clés de création retenues pour ce rôle.
List<String> featuresForRole(String role, List<String> keys) =>
    _keep(role, keys, _managerHiddenFeatures);

/// Écrans réservés au propriétaire.
///
/// Le routeur racine est plat : une route reste atteignable par navigation
/// directe même sans bouton pour y mener. Retirer une entrée de la grille ne
/// ferme pas l'écran — d'où ce garde, qui redirige.
const _ownerOnlyRoutes = <String>{
  'AddPropertyRoute',
  'AddResidenceRoute',
  'ReportRoute',
  'FinanceRoute',
  'GerantListRoute',
  'AddGerantRoute',
  'GerantScopeRoute',
  'PropertyManagerProfileRoute',
};

bool isRouteAllowed(String role, String routeName) {
  if (role != 'gerant') return true;
  return !_ownerOnlyRoutes.contains(routeName);
}

/// Garde appliqué aux routes réservées au propriétaire.
class OwnerRouteGuard extends AutoRouteGuard {
  const OwnerRouteGuard(this.roleOf);

  /// Lecture du rôle courant, injectée pour rester testable hors widget.
  final String Function() roleOf;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isRouteAllowed(roleOf(), resolver.route.name)) {
      resolver.next();
      return;
    }

    // Redirection silencieuse : un gérant qui atteint cette route ne l'a pas
    // demandée, aucune entrée de l'interface ne l'y menait.
    resolver.redirect(const HomeRoute());
  }
}
```

- [ ] **Étape 4 : donner une clé stable aux actions**

`StatsAction` (`action_grid.dart`) ne porte aujourd'hui qu'un `label` français.
Ajouter un champ `key` : filtrer sur un libellé d'affichage casserait à la
première retouche de texte.

```dart
class StatsAction {
  const StatsAction({
    required this.key,   // 'expenses', 'finance', 'reports', 'clients', 'residences'
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  /// Identifiant stable, indépendant du libellé affiché : c'est lui que le
  /// filtrage par rôle regarde.
  final String key;
```

Renseigner les cinq entrées existantes de `_actions`.

`FloatingFeature` porte déjà `action` (`add_property`, `add_reservation`, …) :
l'employer tel quel, sans rien y ajouter.

- [ ] **Étape 5 : brancher la grille et le menu**

Dans `action_grid.dart`, le `build` filtre la liste avant de la rendre :

```dart
    final role = context.read<AuthCubit>().state.role;
    final visible = actionsForRole(role, _actions.map((a) => a.key).toList());
    final actions = _actions.where((a) => visible.contains(a.key)).toList();
```

Même motif dans `home_screen.dart` pour `_features`, filtré sur `action`.

**Ne rien changer d'autre** : ni le `GridView.count(crossAxisCount: 2)`, ni les
couleurs, ni les animations du menu flottant, ni la barre de navigation. Une
grille à trois entrées se réagence d'elle-même.

Lire le rôle par le motif déjà en place dans les widgets voisins — ne pas
introduire un nouveau moyen d'accéder à la session.

- [ ] **Étape 6 : appliquer le garde aux routes**

Dans `app_router.dart`, ajouter `guards: [OwnerRouteGuard(...)]` aux routes de
`_ownerOnlyRoutes`. Puis :
`dart run build_runner build --delete-conflicting-outputs`

- [ ] **Étape 7 : lancer la suite**

Lancer : `flutter test && flutter analyze`
Attendu : SUCCÈS. Aucune régression possible pour le propriétaire — les deux
fonctions de filtrage rendent la liste d'origine pour tout rôle autre que
`gerant`.

- [ ] **Étape 8 : commit**

```bash
git add lib/core/router lib/features/home test/core/router
git commit -m "feat(gerant): filtrer les actions et les creations selon le role"
```

---
## Task 5 : accueil du gérant

**Fichiers :**
- Créer : `lib/features/gerant/business_logic/gerant_overview_cubit.dart`
- Créer : `lib/features/gerant/business_logic/gerant_overview_state.dart`
- Créer : `lib/features/gerant/data/models/gerant_overview_model.dart`
- Modifier : `lib/features/home/presentation/widgets/tabs/home_tab.dart`
- Test : `test/features/gerant/gerant_overview_test.dart`

**Ce que l'accueil du gérant montre :** arrivées et départs du jour,
réservations en cours, et ses chiffres du mois — nombre de réservations,
encaissements, taux d'occupation — sur ses seuls logements.

**Ce qu'il ne montre pas :** aucun revenu net. `GET /gerant/finance/overview`
n'en renvoie aucun, et le modèle ne doit pas en fabriquer un par soustraction.
Un net calculé sur un périmètre partiel n'est pas une marge partielle, c'est un
chiffre faux.

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/gerant/data/models/gerant_overview_model.dart';

void main() {
  group('GerantOverviewModel', () {
    test('lit le relevé du serveur', () {
      final model = GerantOverviewModel.fromJson(const {
        'bookings_count': 12,
        'gross_revenue': 380000,
        'expenses_total': 45000,
        'occupancy_rate': 0.42,
        'revenue_points': [
          {'month': 'Oct', 'value': 380000},
        ],
      });

      expect(model.bookingsCount, 12);
      expect(model.grossRevenue, 380000);
      expect(model.expensesTotal, 45000);
      expect(model.occupancyRate, 0.42);
      expect(model.revenuePoints, hasLength(1));
    });

    test('supporte un relevé vide', () {
      // Un gérant fraîchement affecté n'a encore aucune réservation.
      final model = GerantOverviewModel.fromJson(const {});

      expect(model.bookingsCount, 0);
      expect(model.grossRevenue, 0);
      expect(model.occupancyRate, 0);
      expect(model.revenuePoints, isEmpty);
    });

    test('n’expose aucun revenu net', () {
      // Le net déduirait des charges qui ne relèvent pas du gérant :
      // abonnement du propriétaire, charges communes, dépenses d'autres
      // logements. Sur un périmètre partiel, ce n'est pas une marge partielle
      // mais un chiffre faux.
      final model = GerantOverviewModel.fromJson(const {
        'gross_revenue': 380000,
        'expenses_total': 45000,
      });

      expect(model.toJson().containsKey('net_revenue'), isFalse);
      expect(model.toJson().containsKey('benefice_net'), isFalse);
    });
  });
}
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

- [ ] **Étape 3 : écrire le modèle, le cubit et son state**

Le state suit la hiérarchie `sealed` du projet :
`GerantOverviewInitial` / `Loading` / `Loaded` / `Error`.
Le cubit vérifie `if (!isClosed)` avant chaque `emit` suivant un `await`, et
attrape `AppFailure` pour émettre `GerantOverviewError(failure.userMessage)`.

- [ ] **Étape 4 : brancher l'accueil**

Dans `home_tab.dart`, bifurquer selon `isManager` : le gérant voit ses chiffres
et ses mouvements du jour, le propriétaire garde son tableau de bord actuel.
Réutiliser les widgets de cartes existants (`revenue_card.dart`,
`reservation_stats_row.dart`) plutôt que d'en créer de nouveaux.

Clés de traduction dans `fr.json` et `en.json`.

- [ ] **Étape 5 : déclarer dans le service locator**

```dart
sl.registerFactory(() => GerantOverviewCubit(sl<GerantRepository>()));
```

- [ ] **Étape 6 : lancer la suite et commiter**

```bash
flutter test && flutter analyze
git add lib/features/gerant lib/features/home lib/core/di assets/translations test/features/gerant
git commit -m "feat(gerant): accueil du gerant avec ses chiffres du mois"
```

---

## Task 6 : `client: null` à la création d'une fiche

Changement de contrat livré par l'API : sur `POST /gerant/clients`, quand la
fiche existe déjà **hors du périmètre**, la réponse porte
`{ client: null, already_existed: true }`.

Un accusé nu plutôt qu'un 403 : le gérant doit pouvoir constater qu'il n'y a
rien à créer, sans rien apprendre de la fiche — pas même son existence.

**Sans ce traitement, l'application plante** en déréférençant `data`.

**Fichiers :**
- Modifier : `lib/features/clients/data/repositories/clients_repository.dart`
- Modifier : `lib/features/clients/business_logic/` (cubit de création)
- Modifier : `lib/features/clients/presentation/screens/add_client_screen.dart`
- Test : `test/features/clients/create_client_scope_test.dart`

- [ ] **Étape 1 : écrire le test qui échoue**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/clients/data/models/client_creation_result.dart';

void main() {
  group('ClientCreationResult', () {
    test('une fiche créée revient complète', () {
      final result = ClientCreationResult.fromJson(const {
        'client': {'id': 'cl-1', 'full_name': 'Awa', 'phone': '+2250700000000'},
        'already_existed': false,
      });

      expect(result.alreadyExisted, isFalse);
      expect(result.client, isNotNull);
      expect(result.client!.id, 'cl-1');
    });

    test('une fiche du périmètre revient complète', () {
      final result = ClientCreationResult.fromJson(const {
        'client': {'id': 'cl-1', 'full_name': 'Awa', 'phone': '+2250700000000'},
        'already_existed': true,
      });

      expect(result.alreadyExisted, isTrue);
      expect(result.client, isNotNull);
    });

    test('une fiche hors périmètre revient nue', () {
      // Le serveur confirme qu'il n'y a rien à créer, sans livrer la fiche
      // d'un client que ce gérant ne sert pas.
      final result = ClientCreationResult.fromJson(const {
        'client': null,
        'already_existed': true,
      });

      expect(result.alreadyExisted, isTrue);
      expect(result.client, isNull);
      expect(result.isOutOfScope, isTrue);
    });
  });
}
```

- [ ] **Étape 2 : lancer le test et vérifier qu'il échoue**

- [ ] **Étape 3 : écrire le modèle de résultat**

```dart
/// Résultat d'une création de fiche client.
///
/// `client` peut être nul alors que `already_existed` vaut `true` : la fiche
/// existe chez le propriétaire, mais hors du périmètre du gérant qui la
/// demande. Le serveur l'accuse sans la livrer — pas même son existence par
/// recoupement, ce qu'un 403 aurait trahi.
class ClientCreationResult {
  const ClientCreationResult({required this.client, required this.alreadyExisted});

  final ClientModel? client;
  final bool alreadyExisted;

  /// Fiche existante que l'appelant n'a pas le droit de voir.
  bool get isOutOfScope => alreadyExisted && client == null;
}
```

- [ ] **Étape 4 : traiter le cas à l'écran**

Dans `add_client_screen.dart`, sur `isOutOfScope` : message expliquant qu'un
client porte déjà ce numéro et qu'il faut en référer au propriétaire. **Ne pas
proposer de réessayer** — la réponse sera identique.

Clés dans `fr.json` et `en.json`.

- [ ] **Étape 5 : traduire les autres codes d'erreur du gérant**

Trois codes que l'API lève sur des routes gérant et que le mobile doit
présenter en français, plutôt que de laisser remonter un message brut :

| Code | Statut | Où | Message |
|---|---|---|---|
| `property_required` | 422 | dépenses | Rattachez cette dépense à un logement. Les charges communes relèvent du propriétaire. |
| `invalid_payment_amount` | 422 | encaissement | Le montant encaissé est invalide. |
| `booking_cancelled` | 409 | encaissement | Cette réservation est annulée, aucun encaissement n'est possible. |

Les placer là où le projet traduit déjà les codes métier — repérer par
`grep -rn "statusCode == 422" lib/` et suivre le motif en place.

Clés dans `fr.json` et `en.json`.

- [ ] **Étape 6 : lancer la suite et commiter**

```bash
flutter test && flutter analyze
git add lib/features/clients lib/features/expense lib/features/reservation assets/translations test/features/clients
git commit -m "feat(gerant): accuser une fiche client hors perimetre sans la livrer"
```

---

## Task 7 : gestion des gérants par le propriétaire

Sans cet écran, l'API livrée est inutilisable : aucun gérant ne peut exister.

**Fichiers :**
- Créer : `lib/features/gerant/data/models/gerant_model.dart`
- Créer : `lib/features/gerant/data/repositories/gerant_repository.dart`
- Créer : `lib/features/gerant/business_logic/gerant_cubit.dart` + state
- Créer : `lib/features/gerant/business_logic/gerant_scope_cubit.dart` + state
- Créer : `lib/features/gerant/presentation/screens/gerant_list_screen.dart`
- Créer : `lib/features/gerant/presentation/screens/add_gerant_screen.dart`
- Créer : `lib/features/gerant/presentation/screens/gerant_scope_screen.dart`
- Créer : `lib/features/gerant/presentation/router/gerant_router_module.dart`
- Modifier : `lib/core/di/service_locator.dart`
- Modifier : `lib/core/router/app_router.dart`
- Modifier : `lib/features/home/presentation/widgets/tabs/profile_tab.dart`
- Test : `test/features/gerant/gerant_scope_test.dart`

**Les six routes :**
```
GET    /proprio/managers                  liste
POST   /proprio/managers                  création (compte + périmètre)
GET    /proprio/managers/:id              détail
PATCH  /proprio/managers/:id              renommage, coordonnées
PUT    /proprio/managers/:id/properties   remplacement du périmètre
PATCH  /proprio/managers/:id/status       activation / suspension
```

**La sélection du périmètre est le cœur de l'écran.** Le propriétaire voit ses
résidences dépliables ; cocher une résidence coche ses logements. Mais ce que
l'application transmet reste **toujours une liste de `property_id`** : côté
serveur, l'affectation ignore les résidences.

- [ ] **Étape 1 : écrire les tests qui échouent**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/gerant/business_logic/gerant_scope_cubit.dart';

void main() {
  group('sélection du périmètre', () {
    final residence = ResidenceSelection(
      id: 'res-1',
      name: 'Resi Adja',
      propertyIds: const ['p-1', 'p-2', 'p-3'],
    );

    test('cocher une résidence coche tous ses logements', () {
      final selection = toggleResidence(const <String>{}, residence);

      expect(selection, {'p-1', 'p-2', 'p-3'});
    });

    test('décocher une résidence décoche tous ses logements', () {
      final selection = toggleResidence(const {'p-1', 'p-2', 'p-3'}, residence);

      expect(selection, isEmpty);
    });

    test('une résidence partiellement cochée se complète', () {
      // 6 logements sur 10 : le cas que le propriétaire rencontre vraiment.
      final selection = toggleResidence(const {'p-1'}, residence);

      expect(selection, {'p-1', 'p-2', 'p-3'});
    });

    test('un logement se coche seul', () {
      final selection = toggleProperty(const <String>{}, 'p-2');

      expect(selection, {'p-2'});
    });

    test('la sélection transmise est une liste de logements', () {
      // Jamais de residence_id : côté serveur, l'affectation ignore les
      // résidences. « Résidence entière » est un geste d'interface.
      final payload = scopePayload(const {'p-2', 'p-1'});

      expect(payload, {'property_ids': ['p-1', 'p-2']});
    });

    test('un périmètre vide reste transmissible', () {
      // Un gérant créé sans logement est légitime : le propriétaire lui en
      // attribuera ensuite. Il ne voit alors rien.
      expect(scopePayload(const <String>{}), {'property_ids': <String>[]});
    });
  });
}
```

- [ ] **Étape 2 : lancer les tests et vérifier qu'ils échouent**

- [ ] **Étape 3 : écrire les fonctions pures de sélection**

```dart
/// Coche ou décoche une résidence entière.
///
/// Tout ou rien : une résidence partiellement cochée se complète plutôt que de
/// se vider, ce qui est le geste attendu — on coche une résidence pour la
/// confier, pas pour en retirer les logements déjà confiés.
Set<String> toggleResidence(Set<String> selection, ResidenceSelection residence) {
  final all = residence.propertyIds.toSet();
  final complete = all.every(selection.contains);

  return complete
      ? (selection.toSet()..removeAll(all))
      : (selection.toSet()..addAll(all));
}

Set<String> toggleProperty(Set<String> selection, String propertyId) {
  final next = selection.toSet();
  return selection.contains(propertyId)
      ? (next..remove(propertyId))
      : (next..add(propertyId));
}

/// Charge utile envoyée au serveur.
///
/// Toujours une liste de logements, ordonnée pour que deux sélections
/// identiques produisent la même requête. Le serveur ignore les résidences :
/// « affecter une résidence entière » n'existe que dans cette interface.
Map<String, dynamic> scopePayload(Set<String> selection) {
  return {'property_ids': selection.toList()..sort()};
}
```

- [ ] **Étape 4 : écrire le repository**

Les six routes, avec les codes d'erreur convertis en messages français :

| Code | Statut | Message |
|---|---|---|
| `manager_already_exists` | 409 | Un compte existe déjà avec ces coordonnées. |
| `manager_contact_required` | 422 | Renseignez un e-mail ou un téléphone. |
| `property_not_owned` | 422 | Un des logements sélectionnés ne vous appartient pas. |
| `manager_not_found` | 404 | Ce gérant est introuvable. |

Lire le `statusCode` et le `code`, jamais le texte du message.

- [ ] **Étape 5 : écrire les trois écrans**

- **Liste** : gérants avec leur nombre de logements et leur état (actif /
  suspendu), bouton d'ajout.
- **Création** : nom, téléphone ou e-mail, mot de passe initial, puis
  sélection du périmètre. Préciser à l'écran que le gérant pourra changer son
  mot de passe.
- **Périmètre** : résidences dépliables, logements cochables, envoi en `PUT`.

Prendre couleurs et styles dans `lib/core/theme/`, vérifier les deux thèmes.
Toutes les chaînes en clés de traduction.

- [ ] **Étape 6 : déclarer routes et dépendances**

```dart
sl.registerLazySingleton<GerantRepository>(() => GerantRepository(sl<ApiClient>()));
sl.registerFactory(() => GerantCubit(sl<GerantRepository>()));
sl.registerFactory(() => GerantScopeCubit(sl<GerantRepository>(), sl<ResidenceRepository>()));
```

Ajouter les trois routes à `app_router.dart` **avec `OwnerRouteGuard`** — elles
sont fermées au gérant. Puis `dart run build_runner build
--delete-conflicting-outputs`.

Entrée depuis `profile_tab.dart`, visible du propriétaire seul.

- [ ] **Étape 7 : lancer la suite et commiter**

```bash
flutter test && flutter analyze
git add lib/features/gerant lib/core/di lib/core/router lib/features/home assets/translations test/features/gerant
git commit -m "feat(gerant): creation et affectation d'un gerant par le proprietaire"
```

---

## Vérification de bout en bout

Les tests unitaires ne couvrent pas le câblage. Avant de considérer le chantier
terminé, éprouver sur un appareil ou un émulateur, contre une API où
`node ace seed:roles` a été lancé et les index Firestore déployés :

1. Le propriétaire crée un gérant et lui affecte 6 logements d'une résidence
   qui en compte 10.
2. Le gérant se connecte : il voit 6 logements, pas 10. La résidence affiche
   6 unités.
3. Il enregistre une réservation au comptoir, hors réseau, puis rétablit la
   connexion : la file se vide.
4. Le propriétaire lui retire un logement. Le gérant saisit une réservation
   dessus hors réseau, puis se reconnecte : la saisie est **retirée de la file
   et signalée**, elle ne la bloque pas.
5. Le gérant garde les quatre onglets et le bouton `+`. Sa grille Stats porte
   trois entrées — Dépenses, Clients, Résidences — sans Finance ni Rapports.
   Son menu `+` en porte trois, sans « Ajouter un bien ». La navigation directe
   vers une route fermée le ramène à l'accueil.
6. Le propriétaire suspend le gérant : sa session suivante affiche un message
   explicite plutôt qu'une erreur nue.
