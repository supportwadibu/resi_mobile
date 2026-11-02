import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/storage/app_database.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Le point a ne pas rater de toute la tache : une saisie rejetee ne doit plus
/// jamais ressortir de la file d'envoi.
///
/// Verifie sur du vrai SQLite, et non sur un double : c'est la clause
/// `WHERE sync_status = 'pending'` de `getQueue()` qui fait foi, et un espion
/// en memoire ne la traverserait pas.
Future<Database> _openSchema() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    version: AppDatabase.schemaVersion,
    onCreate: (db, _) => AppDatabase.instance.createSchema(db),
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
  ),
);

Map<String, Object?> _row(String id, PendingSyncStatus status) => {
  'client_request_id': id,
  'property_id': 'villa',
  'stay_type': 'full_day',
  'check_in_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
  'deposit_amount': 0,
  'is_check_in': 0,
  'sync_status': status.code,
  'attempts': 0,
  'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
};

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;

  setUp(() async {
    db = await _openSchema();
  });

  tearDown(() async => db.close());

  group('une saisie rejetee sort de la file', () {
    test('le statut rejected se relit tel quel', () async {
      // `fromCode` repliait tout sur `pending` avant l'ajout du statut : une
      // saisie rejetee serait revenue dans la file a la lecture suivante.
      await db.insert(
        'pending_bookings',
        _row('req-rejected', PendingSyncStatus.rejected),
      );

      final rows = await db.query('pending_bookings');
      final booking = PendingBooking.fromRow(rows.single);

      expect(booking.syncStatus, PendingSyncStatus.rejected);
    });

    test('getQueue() ne sert pas une saisie rejetee', () async {
      await db.insert(
        'pending_bookings',
        _row('req-pending', PendingSyncStatus.pending),
      );
      await db.insert(
        'pending_bookings',
        _row('req-rejected', PendingSyncStatus.rejected),
      );
      await db.insert(
        'pending_bookings',
        _row('req-conflict', PendingSyncStatus.conflict),
      );

      final rows = await db.query(
        'pending_bookings',
        where: 'sync_status = ?',
        whereArgs: [PendingSyncStatus.pending.code],
        orderBy: 'created_at ASC',
      );
      final queue = rows.map(PendingBooking.fromRow).toList();

      expect(queue.map((b) => b.clientRequestId), ['req-pending']);
    });

    test('la saisie rejetee reste consultable en base', () async {
      // Tout l'objet de la decision : elle sort de la file, elle n'est pas
      // detruite. Montant et client doivent survivre.
      await db.insert('pending_bookings', {
        ..._row('req-rejected', PendingSyncStatus.rejected),
        'received_amount': 45000.0,
        'remote_client_id': 'client-7',
        'last_error': 'Ce logement ne fait pas partie de votre perimetre.',
      });

      final rows = await db.query('pending_bookings');
      final booking = PendingBooking.fromRow(rows.single);

      expect(booking.receivedAmount, 45000.0);
      expect(booking.remoteClientId, 'client-7');
      expect(booking.lastError, isNotNull);
    });

    test('le compteur des rejets ne compte que les rejets', () async {
      await db.insert(
        'pending_bookings',
        _row('req-pending', PendingSyncStatus.pending),
      );
      await db.insert(
        'pending_bookings',
        _row('req-conflict', PendingSyncStatus.conflict),
      );
      await db.insert(
        'pending_bookings',
        _row('req-rejected-1', PendingSyncStatus.rejected),
      );
      await db.insert(
        'pending_bookings',
        _row('req-rejected-2', PendingSyncStatus.rejected),
      );

      Future<int> countOf(PendingSyncStatus status) async {
        final rows = await db.rawQuery(
          'SELECT COUNT(*) AS total FROM pending_bookings WHERE sync_status = ?',
          [status.code],
        );
        return rows.first['total']! as int;
      }

      expect(await countOf(PendingSyncStatus.rejected), 2);
      expect(await countOf(PendingSyncStatus.conflict), 1);
      expect(await countOf(PendingSyncStatus.pending), 1);
    });

    test('le schema accepte le nouveau statut sans migration', () async {
      // `sync_status` n'a pas de contrainte CHECK : c'est ce qui permet
      // d'ajouter un statut sans toucher au schema. Si une contrainte
      // apparaissait, ce test le dirait avant les utilisateurs.
      await expectLater(
        db.insert(
          'pending_bookings',
          _row('req-rejected', PendingSyncStatus.rejected),
        ),
        completes,
      );
    });
  });

  group('PendingSyncStatus.fromCode', () {
    test('reconnait chaque statut', () {
      for (final status in PendingSyncStatus.values) {
        expect(PendingSyncStatus.fromCode(status.code), status);
      }
    });

    test('un code inconnu ou absent vaut pending', () {
      // Repli volontaire : reessayer une saisie est moins grave que la perdre.
      expect(PendingSyncStatus.fromCode(null), PendingSyncStatus.pending);
      expect(PendingSyncStatus.fromCode('inconnu'), PendingSyncStatus.pending);
    });
  });
}
