import 'package:sqflite/sqflite.dart';

import 'package:resi_africa/core/storage/app_database.dart';

/// Espion de la base locale : il note ce qui a été purgé, sans SQLite.
///
/// `implements` plutôt qu'un vrai `AppDatabase` : le constructeur est privé,
/// et ouvrir une base réelle exigerait le binding de plateforme que les tests
/// unitaires du projet n'installent pas.
///
/// La distinction entre [clearedAll] et [cachesCleared] est tout l'objet des
/// tests : un chemin qui vide la file d'envoi détruit de l'argent encaissé au
/// comptoir, et seule la déconnexion volontaire en a le droit.
class SpyDatabase implements AppDatabase {
  SpyDatabase({this.throwOnClear = false});

  /// Simule une purge impossible — disque plein, fichier verrouillé.
  final bool throwOnClear;

  bool clearedAll = false;
  bool cachesCleared = false;

  @override
  Future<void> clear() async {
    if (throwOnClear) throw StateError('base verrouillée');
    clearedAll = true;
  }

  @override
  Future<void> clearCaches() async {
    if (throwOnClear) throw StateError('base verrouillée');
    cachesCleared = true;
  }

  @override
  Future<void> close() async {}

  @override
  Future<Database> get database =>
      throw UnimplementedError('aucun test unitaire n’ouvre SQLite');

  @override
  Future<void> createSchema(Database db) =>
      throw UnimplementedError('couvert par le test de migration');

  @override
  Future<void> upgradeSchema(Database db, int from, int to) =>
      throw UnimplementedError('couvert par le test de migration');
}
