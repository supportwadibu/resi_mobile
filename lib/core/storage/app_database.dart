import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base locale de l'application.
///
/// Trois usages, tous nés du besoin de travailler sans réseau :
///
/// 1. **Les caches** (`cached_properties`, `cached_clients`,
///    `cached_bookings`) — sans eux, le formulaire hors ligne n'a aucune
///    résidence à proposer ni aucun client à retrouver. Le cache des biens
///    est donc un prérequis de la saisie, pas un confort.
/// 2. **La file d'envoi** (`pending_bookings`) — les réservations saisies
///    sans réseau, en attente de synchronisation.
/// 3. **Les pièces d'identité en attente** — leur chemin sur l'appareil, le
///    fichier partant en multipart au moment de l'envoi.
///
/// SQLite plutôt qu'un stockage clé-valeur : la file porte de l'argent
/// encaissé et exige de vraies transactions — un plantage entre l'écriture du
/// client et celle de sa réservation laisserait sinon une réservation
/// orpheline. Le dédoublonnage par téléphone est par ailleurs une recherche,
/// pas une lecture par clé.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'resi_local.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _fileName),
      version: _version,
      onCreate: (db, _) => _createSchema(db),
      onConfigure: (db) async {
        // Les réservations en attente référencent un client local : sans
        // contrainte, supprimer le client laisserait une référence morte.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    // ── Caches ──────────────────────────────────────────────────────────────
    // `payload` porte le JSON tel que reçu du serveur : les colonnes nommées
    // servent aux recherches, le reste n'a pas à être éclaté en colonnes que
    // chaque évolution de l'API obligerait à migrer.

    batch.execute('''
      CREATE TABLE cached_properties (
        id           TEXT PRIMARY KEY,
        title        TEXT NOT NULL,
        daily_price  REAL NOT NULL DEFAULT 0,
        payload      TEXT NOT NULL,
        synced_at    INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE cached_clients (
        id           TEXT PRIMARY KEY,
        full_name    TEXT NOT NULL,
        phone        TEXT NOT NULL,
        status       TEXT NOT NULL DEFAULT 'active',
        payload      TEXT NOT NULL,
        synced_at    INTEGER NOT NULL
      )
    ''');

    // Le téléphone identifie le client : la recherche pendant la saisie passe
    // par cet index, et l'unicité empêche deux fiches locales pour un même
    // numéro.
    batch.execute(
      'CREATE UNIQUE INDEX idx_cached_clients_phone ON cached_clients (phone)',
    );

    batch.execute('''
      CREATE TABLE cached_bookings (
        id            TEXT PRIMARY KEY,
        property_id   TEXT NOT NULL,
        check_in_at   INTEGER NOT NULL,
        check_out_at  INTEGER NOT NULL,
        status        TEXT NOT NULL,
        payload       TEXT NOT NULL,
        synced_at     INTEGER NOT NULL
      )
    ''');

    // Le contrôle de chevauchement interroge les réservations d'un bien sur
    // une période : sans cet index, il balaierait toute la table.
    batch.execute(
      'CREATE INDEX idx_cached_bookings_property '
      'ON cached_bookings (property_id, check_out_at)',
    );

    // ── Clients créés hors ligne ────────────────────────────────────────────
    // Un client saisi sans réseau n'a pas encore d'identifiant serveur : il
    // en reçoit un local, remplacé par le vrai à la synchronisation.

    batch.execute('''
      CREATE TABLE pending_clients (
        local_id            TEXT PRIMARY KEY,
        remote_id           TEXT,
        full_name           TEXT NOT NULL,
        phone               TEXT NOT NULL,
        document_front_path TEXT,
        document_back_path  TEXT,
        created_at          INTEGER NOT NULL
      )
    ''');

    // ── File d'envoi ────────────────────────────────────────────────────────

    batch.execute('''
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
        created_at         INTEGER NOT NULL,
        FOREIGN KEY (local_client_id)
          REFERENCES pending_clients (local_id)
          ON DELETE CASCADE
      )
    ''');

    // La file se vide dans l'ordre de saisie : deux réservations sur le même
    // bien doivent s'ordonner, et les envoyer en parallèle rendrait l'issue
    // indéterminée.
    batch.execute(
      'CREATE INDEX idx_pending_bookings_queue '
      'ON pending_bookings (sync_status, created_at)',
    );

    await batch.commit(noResult: true);
  }

  /// Vide les caches et la file — à la déconnexion.
  ///
  /// Les données d'un propriétaire ne doivent pas rester lisibles par le
  /// suivant sur le même appareil.
  Future<void> clear() async {
    final db = await database;
    final batch = db.batch();

    for (final table in const [
      'cached_properties',
      'cached_clients',
      'cached_bookings',
      'pending_bookings',
      'pending_clients',
    ]) {
      batch.delete(table);
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
