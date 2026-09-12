import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/storage/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Schéma tel qu'il existait en version 1, avant l'introduction des résidences.
///
/// Recopié ici volontairement : c'est le point de départ que la migration doit
/// savoir reprendre, et le faire produire par le code courant ne testerait
/// qu'une tautologie.
const _schemaV1 = [
  '''
    CREATE TABLE cached_properties (
      id           TEXT PRIMARY KEY,
      title        TEXT NOT NULL,
      daily_price  REAL NOT NULL DEFAULT 0,
      payload      TEXT NOT NULL,
      synced_at    INTEGER NOT NULL
    )
  ''',
  '''
    CREATE TABLE pending_bookings (
      client_request_id  TEXT PRIMARY KEY,
      local_client_id    TEXT,
      remote_client_id   TEXT,
      property_id        TEXT NOT NULL,
      stay_type          TEXT NOT NULL,
      check_in_at        INTEGER NOT NULL,
      check_out_at       INTEGER,
      received_amount    REAL,
      deposit_amount     REAL NOT NULL DEFAULT 0,
      message            TEXT,
      is_check_in        INTEGER NOT NULL DEFAULT 0,
      sync_status        TEXT NOT NULL DEFAULT 'pending',
      last_error         TEXT,
      attempts           INTEGER NOT NULL DEFAULT 0,
      created_at         INTEGER NOT NULL
    )
  ''',
];

/// Ouvre une base en mémoire portant le schéma de version 1, avec des données.
Future<Database> _openV1() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(version: 1),
  );

  for (final statement in _schemaV1) {
    await db.execute(statement);
  }

  await db.insert('cached_properties', {
    'id': 'villa',
    'title': 'Villa Belvédère',
    'daily_price': 60000,
    'payload': '{"id":"villa"}',
    'synced_at': 1,
  });

  // Une réservation hors ligne non encore synchronisée : c'est elle qui
  // interdit de recréer la base de zéro à la migration.
  await db.insert('pending_bookings', {
    'client_request_id': 'req-1',
    'property_id': 'villa',
    'stay_type': 'full_day',
    'check_in_at': 1000,
    'received_amount': 45000,
    'created_at': 1000,
  });

  return db;
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('Migration v1 → v2', () {
    test('ajoute les colonnes de rattachement', () async {
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      final columns = await db.rawQuery(
        'PRAGMA table_info(cached_properties)',
      );
      final names = columns.map((c) => c['name'] as String).toSet();

      expect(names, contains('residence_id'));
      expect(names, contains('residence_name'));
      expect(names, contains('unit_label'));
    });

    test('conserve les biens déjà en cache', () async {
      // `ALTER TABLE ADD COLUMN` laisse les lignes en place. Les recréer aurait
      // vidé le cache, et la saisie hors ligne n'aurait plus rien à proposer
      // tant qu'aucune connexion ne l'a repeuplé.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      final rows = await db.query('cached_properties');

      expect(rows, hasLength(1));
      expect(rows.single['title'], 'Villa Belvédère');
      expect(rows.single['daily_price'], 60000);
    });

    test('les biens existants valent « autonome » après migration', () async {
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      final row = (await db.query('cached_properties')).single;

      // `NULL` — c'est-à-dire le comportement d'avant les résidences.
      expect(row['residence_id'], isNull);
      expect(row['residence_name'], isNull);
      expect(row['unit_label'], isNull);
    });

    test('la file d’envoi survit à la migration', () async {
      // Le point qui compte le plus : `pending_bookings` porte de l'argent
      // encaissé pas encore parvenu au serveur. Une migration qui recrée la
      // base perdrait la réservation et le paiement avec.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      final pending = await db.query('pending_bookings');

      expect(pending, hasLength(1));
      expect(pending.single['client_request_id'], 'req-1');
      expect(pending.single['received_amount'], 45000);
    });

    test('la base migrée accepte une écriture avec rattachement', () async {
      // Vérifie que les colonnes sont utilisables, et pas seulement déclarées.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      await db.insert('cached_properties', {
        'id': 'studio-1',
        'title': 'Studio meublé',
        'daily_price': 25000,
        'residence_id': 'resi-adja',
        'residence_name': 'Resi Adja',
        'unit_label': 'Studio 1',
        'payload': '{"id":"studio-1"}',
        'synced_at': 2,
      });

      final row = (await db.query(
        'cached_properties',
        where: 'id = ?',
        whereArgs: ['studio-1'],
      )).single;

      expect(row['residence_name'], 'Resi Adja');
      expect(row['unit_label'], 'Studio 1');
    });

    test('une base déjà en version 2 n’est pas migrée deux fois', () async {
      // `ALTER TABLE ADD COLUMN` échoue sur une colonne existante : sans le
      // garde `from < 2`, une seconde exécution lèverait.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(db, 1, AppDatabase.schemaVersion);

      await expectLater(
        AppDatabase.instance.upgradeSchema(db, 2, AppDatabase.schemaVersion),
        completes,
      );
    });
  });

  group('Schéma neuf', () {
    test('une base créée de zéro porte les mêmes colonnes qu’une base migrée', () async {
      // Les deux chemins doivent converger : une divergence ferait qu'un
      // appareil neuf et un appareil migré ne se comportent pas pareil.
      // `onCreate` plutôt qu’un `createSchema` après ouverture : deux bases
      // en mémoire ouvertes en parallèle partagent le même espace, et rejouer
      // le schéma sur la seconde buterait sur les tables de la première.
      final fresh = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppDatabase.schemaVersion,
          onCreate: (db, _) => AppDatabase.instance.createSchema(db),
        ),
      );

      Future<Set<String>> columnsOf(Database db) async {
        final rows = await db.rawQuery('PRAGMA table_info(cached_properties)');
        return rows.map((c) => c['name'] as String).toSet();
      }

      final freshColumns = await columnsOf(fresh);
      await fresh.close();

      final migrated = await _openV1();
      addTearDown(migrated.close);
      await AppDatabase.instance.upgradeSchema(
        migrated,
        1,
        AppDatabase.schemaVersion,
      );

      expect(await columnsOf(migrated), freshColumns);
    });
  });
}
