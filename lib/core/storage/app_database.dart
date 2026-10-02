import 'package:flutter/foundation.dart';
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

  /// Version du schéma local.
  ///
  /// 2 — `cached_properties` porte le libellé de l’unité et le nom de sa
  /// résidence, pour que la saisie comptoir hors ligne affiche
  /// « Resi Adja › Studio 1 » et non le seul titre de l’annonce.
  ///
  /// 3 — `pending_bookings` porte l’apporteur d’affaire, pour qu’une
  /// réservation saisie hors ligne le transmette à la synchronisation.
  ///
  /// 4 — `pending_clients` porte la pièce (nature, numéro) et l’identité du
  /// registre de police, lues au comptoir : sans elles, un client saisi hors
  /// ligne arrivait au carnet sans rien de ce que le registre exige.
  ///
  /// 5 — `http_cache` garde la dernière réponse de chaque lecture, pour que
  /// tout écran déjà ouvert en ligne s'affiche hors ligne ; `pending_actions`
  /// et `local_refs` étendent la file aux autres actions du comptoir
  /// (départ, prolongation, fiche client, dépense).
  static const _version = 5;

  /// Version courante du schéma, lue par les tests de migration.
  @visibleForTesting
  static int get schemaVersion => _version;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _fileName),
      version: _version,
      onCreate: (db, _) => createSchema(db),
      onUpgrade: upgradeSchema,
      onConfigure: (db) async {
        // Les réservations en attente référencent un client local : sans
        // contrainte, supprimer le client laisserait une référence morte.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Crée le schéma complet, à la version courante.
  ///
  /// Publique pour que les tests la lancent sur une base en mémoire : une
  /// copie du SQL dans le test divergerait au premier changement de schéma.
  @visibleForTesting
  Future<void> createSchema(Database db) async {
    final batch = db.batch();

    // ── Caches ──────────────────────────────────────────────────────────────
    // `payload` porte le JSON tel que reçu du serveur : les colonnes nommées
    // servent aux recherches, le reste n'a pas à être éclaté en colonnes que
    // chaque évolution de l'API obligerait à migrer.

    batch.execute('''
      CREATE TABLE cached_properties (
        id             TEXT PRIMARY KEY,
        title          TEXT NOT NULL,
        daily_price    REAL NOT NULL DEFAULT 0,
        residence_id   TEXT,
        residence_name TEXT,
        unit_label     TEXT,
        payload        TEXT NOT NULL,
        synced_at      INTEGER NOT NULL
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
        created_at          INTEGER NOT NULL,
        id_document_type    TEXT,
        id_document_number  TEXT,
        identity_fields     TEXT
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
        referrer_name      TEXT,
        referrer_phone     TEXT,
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

    _createV5Tables(batch);

    await batch.commit(noResult: true);
  }

  /// Tables apparues en version 5, partagées par la création et la migration
  /// pour qu'un appareil migré ait exactement le schéma d'une installation
  /// neuve.
  static void _createV5Tables(Batch batch) {
    // Corps JSON tel que reçu : le repository le parse comme une réponse
    // réseau, sans savoir d'où il vient.
    batch.execute('''
      CREATE TABLE http_cache (
        cache_key  TEXT PRIMARY KEY,
        path       TEXT NOT NULL,
        body       TEXT NOT NULL,
        cached_at  INTEGER NOT NULL
      )
    ''');

    // Actions du comptoir saisies hors réseau, hors création de réservation
    // qui garde sa propre file. `id` sert aussi d'identifiant d'idempotence.
    batch.execute('''
      CREATE TABLE pending_actions (
        id             TEXT PRIMARY KEY,
        type           TEXT NOT NULL,
        target_ref     TEXT,
        payload        TEXT NOT NULL,
        file_paths     TEXT,
        created_at     INTEGER NOT NULL,
        state          TEXT NOT NULL DEFAULT 'pending',
        error_code     TEXT,
        error_message  TEXT
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_pending_actions_queue '
      'ON pending_actions (state, created_at)',
    );

    // Identifiant serveur d'un élément créé hors ligne : une action qui le
    // vise par son identifiant local se résout ici au moment de l'envoi.
    batch.execute('''
      CREATE TABLE local_refs (
        local_id   TEXT PRIMARY KEY,
        remote_id  TEXT NOT NULL
      )
    ''');
  }

  /// Fait évoluer un schéma déjà installé.
  ///
  /// Les migrations sont cumulatives et sans `else` : un appareil resté en
  /// version 1 doit traverser toutes les étapes jusqu’à la version courante.
  ///
  /// Les caches ne sont pas recréés de zéro, même si leur contenu est
  /// jetable : `pending_bookings` vit dans la même base et porte de l’argent
  /// encaissé pas encore parvenu au serveur.
  /// Publique pour la même raison que [createSchema] : la migration est
  /// exactement ce que le test doit exercer, pas une réécriture.
  @visibleForTesting
  Future<void> upgradeSchema(Database db, int from, int to) async {
    if (from < 2) {
      // Colonnes ajoutées et non table recréée : `ALTER TABLE ADD COLUMN`
      // laisse les lignes en place, et les valeurs manquantes valent `NULL`
      // — c’est-à-dire « bien autonome », le comportement d’avant.
      await db.execute(
        'ALTER TABLE cached_properties ADD COLUMN residence_id TEXT',
      );
      await db.execute(
        'ALTER TABLE cached_properties ADD COLUMN residence_name TEXT',
      );
      await db.execute(
        'ALTER TABLE cached_properties ADD COLUMN unit_label TEXT',
      );
    }

    if (from < 3) {
      // Même règle : la file porte de l’argent encaissé, elle ne se recrée
      // pas. Les saisies déjà en file valent `NULL`, sans apporteur.
      await db.execute(
        'ALTER TABLE pending_bookings ADD COLUMN referrer_name TEXT',
      );
      await db.execute(
        'ALTER TABLE pending_bookings ADD COLUMN referrer_phone TEXT',
      );
    }

    if (from < 4) {
      // `identity_fields` porte les champs du registre en JSON, tels que le
      // formulaire multipart les enverra : cinq colonnes de plus seraient à
      // migrer au prochain champ ajouté. Les clients déjà en file valent
      // `NULL`, sans identité — ce qu’ils étaient.
      await db.execute(
        'ALTER TABLE pending_clients ADD COLUMN id_document_type TEXT',
      );
      await db.execute(
        'ALTER TABLE pending_clients ADD COLUMN id_document_number TEXT',
      );
      await db.execute(
        'ALTER TABLE pending_clients ADD COLUMN identity_fields TEXT',
      );
    }

    if (from < 5) {
      // Tables nouvelles seulement : les files existantes restent en place,
      // elles portent de l'argent encaissé.
      final batch = db.batch();
      _createV5Tables(batch);
      await batch.commit(noResult: true);
    }
  }

  /// Tables jetables : leur contenu se reconstruit d'un appel réseau.
  static const _cacheTables = [
    'cached_properties',
    'cached_clients',
    'cached_bookings',
    'http_cache',
  ];

  /// Tables de la file hors ligne, à ne vider qu'à la déconnexion.
  ///
  /// `pending_clients` suit `pending_bookings` : la clé étrangère les lie, et
  /// garder les clients sans leurs réservations n'aurait aucun sens.
  /// `local_refs` suit la file : sans elle, une action visant un élément créé
  /// hors ligne ne saurait plus où partir.
  static const _queueTables = [
    'pending_bookings',
    'pending_clients',
    'pending_actions',
    'local_refs',
  ];

  /// Vide les caches et la file — à la déconnexion.
  ///
  /// Les données d'un propriétaire ne doivent pas rester lisibles par le
  /// suivant sur le même appareil.
  Future<void> clear() async {
    await _deleteFrom([..._cacheTables, ..._queueTables]);
  }

  /// Vide les seuls caches — à l'expiration subie d'une session.
  ///
  /// L'asymétrie avec [clear] est délibérée. Un jeton expire tout seul, après
  /// une nuit d'inactivité ou une coupure réseau prolongée — c'est-à-dire
  /// dans le contexte même pour lequel la file existe. `pending_bookings`
  /// porte alors des réservations encaissées en espèces au comptoir et pas
  /// encore parvenues au serveur : les détruire là perdrait de l'argent réel
  /// et sans trace, le gérant ayant la liasse en caisse et plus rien nulle
  /// part. La fuite de données qu'on ferme ici ne vaut pas ce prix.
  ///
  /// Les caches, eux, ne coûtent rien à perdre : les purger referme l'accès
  /// au carnet clients — pièces d'identité comprises — sans rien détruire.
  Future<void> clearCaches() async {
    await _deleteFrom(_cacheTables);
  }

  Future<void> _deleteFrom(List<String> tables) async {
    final db = await database;
    final batch = db.batch();

    for (final table in tables) {
      batch.delete(table);
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
