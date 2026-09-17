import '../storage/local_storage.dart';

/// Rôle de la session en cours.
///
/// Les repositories n'ont pas accès à l'`AuthCubit`, et le rôle doit survivre
/// au redémarrage de l'application : la file d'envoi hors ligne se vide sans
/// que l'utilisateur se reconnecte, et elle doit alors savoir vers quel
/// préfixe poster.
class SessionRole {
  SessionRole(this._storage);

  final LocalStorage _storage;

  String _role = 'proprio';

  /// Rôle courant. Vaut `proprio` tant que rien n'a été chargé : le repli le
  /// plus sûr, puisqu'un préfixe gérant ouvert à tort échouerait en 403 sur
  /// chaque appel.
  String get value => _role;

  /// Mémorise le rôle à la connexion, en mémoire et sur le disque.
  Future<void> set(String role) async {
    _role = role;
    await _storage.saveRole(role);
  }

  /// Relit le rôle au démarrage, avant tout appel d'API.
  Future<void> restore() async {
    _role = await _storage.getRole() ?? 'proprio';
  }

  Future<void> clear() async {
    _role = 'proprio';
    await _storage.clearRole();
  }
}
