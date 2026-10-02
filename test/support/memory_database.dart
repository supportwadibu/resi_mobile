import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:resi_africa/core/storage/app_database.dart';

/// Base locale réelle, en mémoire, au schéma courant.
///
/// `implements` pour la même raison que `SpyDatabase` : le constructeur
/// d'`AppDatabase` est privé. Les requêtes, elles, passent par du vrai
/// SQLite — c'est leur clause `WHERE` que les tests de file doivent éprouver.
class MemoryDatabase implements AppDatabase {
  MemoryDatabase._(this._db);

  final Database _db;

  static Future<MemoryDatabase> open() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion,
        onCreate: (db, _) => AppDatabase.instance.createSchema(db),
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        // Une base en mémoire par test : sans cela, ffi la partage.
        singleInstance: false,
      ),
    );
    return MemoryDatabase._(db);
  }

  @override
  Future<Database> get database async => _db;

  @override
  Future<void> close() => _db.close();

  @override
  Future<void> clear() => throw UnimplementedError();

  @override
  Future<void> clearCaches() => throw UnimplementedError();

  @override
  Future<void> createSchema(Database db) =>
      AppDatabase.instance.createSchema(db);

  @override
  Future<void> upgradeSchema(Database db, int from, int to) =>
      AppDatabase.instance.upgradeSchema(db, from, to);
}
