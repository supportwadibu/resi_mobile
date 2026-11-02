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

// `isOwnerOnlyPath` vivait ici : elle reconnaissait un chemin propriétaire pour
// expliquer un 403 plutôt que de le laisser nu. Elle a été retirée, sans
// appelant depuis son écriture, pour deux raisons.
//
// La première est qu'elle n'a plus d'objet : un geste fermé au gérant ne lui est
// plus présenté, donc aucun appel ne part plus vers un chemin qu'il n'a pas —
// voir `_managerHiddenGestures` dans `core/router/role_guard.dart`. Un message
// posé après le refus arrive de toute façon trop tard : la conception veut une
// absence, pas une explication.
//
// La seconde est qu'elle formait un second endroit où se décide ce qu'un rôle
// atteint, concurrent du `role_guard` et déjà en retard sur lui — sa liste
// ignorait `/properties/stats`, `/bookings/stats`, `/profile` et `/feedbacks`.
// Deux règles de périmètre finissent par se contredire ; celle qui ne servait
// à rien part.
