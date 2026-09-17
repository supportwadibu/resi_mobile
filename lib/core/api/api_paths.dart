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
