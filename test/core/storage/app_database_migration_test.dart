import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/storage/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Schéma tel qu'il existait en version 1, avant l'introduction des résidences.
///
/// Recopié ici volontairement : c'est le point de départ que la migration doit
/// savoir reprendre, et le faire produire par le code courant ne testerait
/// qu'une tautologie.
const _schemaV1 = [
  // Présente dès la version 1 (commit e75dbb9) : la migration v4 la fait
  // évoluer, et son absence ici masquerait un ALTER TABLE sur une table
  // inexistante.
  '''
    CREATE TABLE pending_clients (
      local_id            TEXT PRIMARY KEY,
      remote_id           TEXT,
      full_name           TEXT NOT NULL,
      phone               TEXT NOT NULL,
      document_front_path TEXT,
      document_back_path  TEXT,
      created_at          INTEGER NOT NULL
    )
  ''',
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

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      final columns = await db.rawQuery('PRAGMA table_info(cached_properties)');
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

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      final rows = await db.query('cached_properties');

      expect(rows, hasLength(1));
      expect(rows.single['title'], 'Villa Belvédère');
      expect(rows.single['daily_price'], 60000);
    });

    test('les biens existants valent « autonome » après migration', () async {
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

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

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      final pending = await db.query('pending_bookings');

      expect(pending, hasLength(1));
      expect(pending.single['client_request_id'], 'req-1');
      expect(pending.single['received_amount'], 45000);
    });

    test('la base migrée accepte une écriture avec rattachement', () async {
      // Vérifie que les colonnes sont utilisables, et pas seulement déclarées.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

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

    test('une base déjà à jour n’est pas migrée deux fois', () async {
      // `ALTER TABLE ADD COLUMN` échoue sur une colonne existante : sans les
      // gardes `from < n`, une seconde exécution lèverait.
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      await expectLater(
        AppDatabase.instance.upgradeSchema(
          db,
          AppDatabase.schemaVersion,
          AppDatabase.schemaVersion,
        ),
        completes,
      );
    });
  });

  group('Migration → v3', () {
    test('la file garde ses saisies et reçoit l’apporteur', () async {
      final db = await _openV1();
      addTearDown(db.close);

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      // La saisie mise en file avant la migration est intacte, sans apporteur.
      final before = (await db.query('pending_bookings')).single;
      expect(before['client_request_id'], 'req-1');
      expect(before['referrer_name'], isNull);

      await db.insert('pending_bookings', {
        'client_request_id': 'req-2',
        'property_id': 'villa',
        'stay_type': 'full_day',
        'check_in_at': 2000,
        'created_at': 2000,
        'referrer_name': 'Koffi',
        'referrer_phone': '0700000000',
      });

      final after = (await db.query(
        'pending_bookings',
        where: 'client_request_id = ?',
        whereArgs: ['req-2'],
      )).single;
      expect(after['referrer_name'], 'Koffi');
      expect(after['referrer_phone'], '0700000000');
    });
  });

  group('Migration → v4', () {
    test('un client en file garde sa saisie et reçoit son identité', () async {
      final db = await _openV1();
      addTearDown(db.close);

      await db.insert('pending_clients', {
        'local_id': 'local-1',
        'full_name': 'Aya Traoré',
        'phone': '0700000000',
        'created_at': 1000,
      });

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      final before = (await db.query('pending_clients')).single;
      expect(before['full_name'], 'Aya Traoré');
      expect(before['id_document_number'], isNull);

      await db.insert('pending_clients', {
        'local_id': 'local-2',
        'full_name': 'Koffi',
        'phone': '0500000000',
        'created_at': 2000,
        'id_document_type': 'cni',
        'id_document_number': 'C0012345',
        'identity_fields': '{"birth_place":"Bouaké"}',
      });

      final after = (await db.query(
        'pending_clients',
        where: 'local_id = ?',
        whereArgs: ['local-2'],
      )).single;
      expect(after['id_document_number'], 'C0012345');
      expect(after['identity_fields'], contains('Bouaké'));
    });
  });

  group('Migration → v5', () {
    test('les files existantes survivent, les tables hors ligne apparaissent',
        () async {
      final db = await _openV1();
      addTearDown(db.close);

      // Une réservation encaissée attend le réseau au moment de la mise à
      // jour : elle porte de l'argent, la migration ne doit pas y toucher.
      await db.insert('pending_bookings', {
        'client_request_id': 'req-v5',
        'property_id': 'villa',
        'stay_type': 'full_day',
        'check_in_at': 1000,
        'received_amount': 45000,
        'created_at': 1000,
      });

      await AppDatabase.instance.upgradeSchema(
        db,
        1,
        AppDatabase.schemaVersion,
      );

      expect(
        await db.query(
          'pending_bookings',
          where: 'client_request_id = ?',
          whereArgs: ['req-v5'],
        ),
        hasLength(1),
      );

      await db.insert('http_cache', {
        'cache_key': 'u1|/p?',
        'path': '/p',
        'body': '{"data":[]}',
        'cached_at': 1,
      });
      await db.insert('pending_actions', {
        'id': 'a1',
        'type': 'booking_check_out',
        'target_ref': 'b1',
        'payload': '{}',
        'created_at': 2,
      });
      await db.insert('local_refs', {
        'local_id': 'local-v5',
        'remote_id': 'r1',
      });

      final action = (await db.query('pending_actions')).single;
      expect(action['state'], 'pending');
      expect(await db.query('http_cache'), hasLength(1));
      expect(await db.query('local_refs'), hasLength(1));
    });
  });

  group('Schéma neuf', () {
    test(
      'une base créée de zéro porte les mêmes colonnes qu’une base migrée',
      () async {
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

        // Les deux tables que les migrations font évoluer.
        Future<Set<String>> columnsOf(Database db) async {
          final columns = <String>{};
          for (final table in [
            'cached_properties',
            'pending_bookings',
            'pending_clients',
            'http_cache',
            'pending_actions',
            'local_refs',
          ]) {
            final rows = await db.rawQuery('PRAGMA table_info($table)');
            columns.addAll(rows.map((c) => '$table.${c['name']}'));
          }
          return columns;
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
      },
    );
  });
}
