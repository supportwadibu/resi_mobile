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

/// Gestes fermés au gérant **à l'intérieur** d'un écran qui lui reste ouvert.
///
/// Retirer une entrée de la grille ferme un écran entier ; ici l'écran est
/// délibérément conservé et seul le geste disparaît. Sans ce filtre le gérant
/// voyait le bouton du propriétaire et n'obtenait, à l'appui, qu'une
/// redirection muette, un 404 ou un 403 — un refus après coup, là où la
/// conception veut une absence.
///
/// Ce que chaque clé ferme, et pourquoi le serveur la refuse :
///
/// - `residence_create`, `residence_edit`, `residence_delete`,
///   `residence_attach_unit` : `/gerant/residences` n'expose qu'un `GET`.
///   Le regroupement lui sert d'affichage, jamais d'objet qu'il façonne.
/// - `property_publish` : la mise en ligne n'a pas d'équivalent gérant, et le
///   repository vise `/proprio/...` en dur — l'appui répondait 403.
/// - `expense_common_charge` : une charge commune de résidence n'a pas de
///   `property_id`, et `POST /gerant/expenses` l'exige (422 `property_required`).
///   Elle porte en outre sur des logements hors de son périmètre et entre dans
///   le net du propriétaire, que le gérant ne voit pas.
/// - `profile_edit` : l'édition du profil passe par
///   `PropertyManagerProfileRoute`, que `_ownerOnlyRoutes` ferme déjà. Le
///   bouton menait donc à une redirection muette. `PATCH /gerant/profile`
///   existe, mais n'accepte que le nom et le mot de passe — pas les
///   coordonnées ni le périmètre, qui relèvent du propriétaire qui a ouvert le
///   compte. Le formulaire propriétaire, qui exige une pièce d'identité, ne
///   peut donc pas lui servir.
const _managerHiddenGestures = <String>{
  'residence_create',
  'residence_edit',
  'residence_delete',
  'residence_attach_unit',
  'property_publish',
  'expense_common_charge',
  'profile_edit',
};

/// Vrai quand ce rôle peut voir ce geste. Un widget interroge cette fonction
/// pour ne pas construire le bouton, jamais pour le construire désactivé.
bool isGestureAllowed(String role, String gesture) {
  if (role != 'gerant') return true;
  return !_managerHiddenGestures.contains(gesture);
}

/// Écrans réservés au propriétaire.
///
/// Le routeur racine est plat : une route reste atteignable par navigation
/// directe même sans bouton pour y mener. Retirer une entrée de la grille ne
/// ferme pas l'écran — d'où ce garde, qui redirige.
///
/// `GerantListRoute`, `AddGerantRoute` et `GerantScopeRoute` n'existent pas
/// encore dans le routeur : la règle les nomme d'avance pour que l'écran de
/// gestion des gérants naisse déjà fermé au gérant lui-même.
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
    //
    // `redirectUntil` et non `redirect` : depuis auto_route 11 c'est le nom
    // de la redirection depuis un garde, et elle remplace l'entrée dans
    // l'historique au lieu de l'empiler — le retour ne ramène pas sur
    // l'écran refusé.
    resolver.redirectUntil(const HomeRoute(), replace: true);
  }
}
