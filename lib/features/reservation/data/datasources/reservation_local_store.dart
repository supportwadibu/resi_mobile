import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../property/data/models/property_model.dart';
import '../models/occupied_period_model.dart';
import '../models/reservation_model.dart';

/// Réservation saisie sans réseau, en attente d'envoi.
class PendingBooking {
  const PendingBooking({
    required this.clientRequestId,
    required this.propertyId,
    required this.stayType,
    required this.checkInAt,
    required this.createdAt,
    this.localClientId,
    this.remoteClientId,
    this.checkOutAt,
    this.receivedAmount,
    this.depositAmount = 0,
    this.message,
    this.isCheckIn = false,
    this.syncStatus = PendingSyncStatus.pending,
    this.lastError,
    this.attempts = 0,
    this.referrerName,
    this.referrerPhone,
  });

  /// Identifiant tiré sur l'appareil, qui rend l'envoi idempotent.
  final String clientRequestId;

  /// Client créé hors ligne, tant qu'il n'a pas d'identifiant serveur.
  final String? localClientId;

  /// Client déjà connu du serveur — choisi au carnet.
  final String? remoteClientId;

  final String propertyId;
  final StayType stayType;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final double? receivedAmount;
  final double depositAmount;
  final String? message;
  final bool isCheckIn;
  final PendingSyncStatus syncStatus;
  final String? lastError;
  final int attempts;
  final DateTime createdAt;

  /// Apporteur d'affaire. La commission n'est pas stockée : le serveur la
  /// calcule et la fige à la réception.
  final String? referrerName;
  final String? referrerPhone;

  factory PendingBooking.fromRow(Map<String, Object?> row) {
    return PendingBooking(
      clientRequestId: row['client_request_id'] as String,
      localClientId: row['local_client_id'] as String?,
      remoteClientId: row['remote_client_id'] as String?,
      propertyId: row['property_id'] as String,
      stayType: StayType.fromCode(row['stay_type'] as String?),
      checkInAt: DateTime.fromMillisecondsSinceEpoch(row['check_in_at'] as int),
      checkOutAt: row['check_out_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['check_out_at'] as int),
      receivedAmount: (row['received_amount'] as num?)?.toDouble(),
      depositAmount: (row['deposit_amount'] as num?)?.toDouble() ?? 0,
      message: row['message'] as String?,
      isCheckIn: (row['is_check_in'] as int? ?? 0) == 1,
      syncStatus: PendingSyncStatus.fromCode(row['sync_status'] as String?),
      lastError: row['last_error'] as String?,
      attempts: (row['attempts'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      // Colonnes ajoutées en version 3 du schéma : `NULL` sur les saisies
      // mises en file avant, c'est-à-dire sans apporteur.
      referrerName: row['referrer_name'] as String?,
      referrerPhone: row['referrer_phone'] as String?,
    );
  }
}

/// État d'une réservation dans la file d'envoi.
enum PendingSyncStatus {
  /// En attente de réseau.
  pending('pending'),

  /// Refusée par le serveur pour cause de chevauchement. Jamais supprimée :
  /// le propriétaire doit arbitrer, la machine ne sait pas qui occupe
  /// réellement le logement.
  conflict('conflict'),

  /// Refusée définitivement : le logement a quitté le périmètre du gérant, ou
  /// son affectation a été suspendue.
  ///
  /// Sortie de la file d'envoi — la rejouer donnerait le même refus — mais
  /// **conservée** : la saisie porte de l'argent encaissé au comptoir, et la
  /// détruire laisserait le gérant sans rien à montrer au propriétaire.
  rejected('rejected');

  const PendingSyncStatus(this.code);

  final String code;

  /// Un code inconnu vaut `pending`.
  ///
  /// Repli délibéré : les lignes écrites avant ce statut n'ont que `pending` ou
  /// `conflict`, et une base d'une version ultérieure ne doit pas faire lever
  /// la lecture. Réessayer une saisie est toujours moins grave que la perdre.
  static PendingSyncStatus fromCode(String? code) {
    for (final status in PendingSyncStatus.values) {
      if (status.code == code) return status;
    }
    return PendingSyncStatus.pending;
  }
}

/// Client saisi hors ligne, en attente de création côté serveur.
class PendingClient {
  const PendingClient({
    required this.localId,
    required this.fullName,
    required this.phone,
    this.remoteId,
    this.documentFrontPath,
    this.documentBackPath,
    this.idDocumentType,
    this.idDocumentNumber,
    this.identity = ClientIdentity.empty,
  });

  final String localId;
  final String? remoteId;
  final String fullName;
  final String phone;
  final String? documentFrontPath;
  final String? documentBackPath;

  /// Pièce et identité lues au comptoir. Sans elles, un client saisi hors
  /// ligne arriverait au carnet sans rien de ce que le registre de police
  /// exige, et il faudrait tout ressaisir.
  final ClientIdDocumentType? idDocumentType;
  final String? idDocumentNumber;
  final ClientIdentity identity;

  /// Ligne de `pending_clients`. L'identité y est rangée en JSON, sous la
  /// forme même que le formulaire multipart enverra.
  Map<String, Object?> toRow({required int createdAt}) => {
    'local_id': localId,
    'remote_id': remoteId,
    'full_name': fullName,
    'phone': phone,
    'document_front_path': documentFrontPath,
    'document_back_path': documentBackPath,
    'created_at': createdAt,
    'id_document_type': idDocumentType?.code,
    'id_document_number': idDocumentNumber,
    'identity_fields': jsonEncode(identity.toFormFields()),
  };

  factory PendingClient.fromRow(Map<String, Object?> row) {
    return PendingClient(
      localId: row['local_id'] as String,
      remoteId: row['remote_id'] as String?,
      fullName: row['full_name'] as String,
      phone: row['phone'] as String,
      documentFrontPath: row['document_front_path'] as String?,
      documentBackPath: row['document_back_path'] as String?,
      // Absents des lignes écrites avant la v4 du schéma.
      idDocumentType: ClientIdDocumentType.fromCode(
        row['id_document_type'] as String?,
      ),
      idDocumentNumber: row['id_document_number'] as String?,
      identity: _identityFrom(row['identity_fields']),
    );
  }

  /// Une identité illisible vaut une identité vide : la réservation, qui porte
  /// de l'argent encaissé, doit partir quand même.
  static ClientIdentity _identityFrom(Object? raw) {
    if (raw is! String || raw.isEmpty) return ClientIdentity.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return ClientIdentity.empty;
      return ClientIdentity.fromJson(decoded);
    } on FormatException {
      return ClientIdentity.empty;
    }
  }
}

/// Accès à la base locale : caches et file d'envoi.
class ReservationLocalStore {
  const ReservationLocalStore(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.database;

  // ── Caches ────────────────────────────────────────────────────────────────

  /// Remplace le cache des biens par ce que le serveur vient de servir.
  ///
  /// Remplacement et non fusion : un bien supprimé côté serveur doit
  /// disparaître du sélecteur, sans quoi le propriétaire pourrait réserver un
  /// logement qu'il ne possède plus.
  /// Refait le cache des biens.
  ///
  /// [residenceNames] associe un identifiant de résidence à son nom. Le nom
  /// est recopié sur chaque ligne plutôt que lu par jointure : le sélecteur
  /// hors ligne doit afficher « Resi Adja › Studio 1 » sans dépendre d’une
  /// seconde table, que rien ne garantit peuplée.
  Future<void> replaceProperties(
    List<PropertyModel> properties, {
    Map<String, String> residenceNames = const {},
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete('cached_properties');
      for (final property in properties) {
        await txn.insert('cached_properties', {
          'id': property.id,
          'title': property.title,
          'daily_price': property.pricing.dailyPrice,
          // Le rattachement suit le bien : sans lui, la saisie hors ligne
          // proposerait trois « Studio 1 » indiscernables dès que le
          // propriétaire gère plusieurs résidences.
          'residence_id': property.residenceId,
          'residence_name': residenceNames[property.residenceId],
          'unit_label': property.unitLabel,
          // Seuls ces champs servent au formulaire hors ligne : la fiche
          // complète du bien reste au serveur, et la recopier ici obligerait
          // à migrer le cache à chaque évolution de l'API.
          'payload': jsonEncode({
            'id': property.id,
            'title': property.title,
            'daily_price': property.pricing.dailyPrice,
            'residence_id': property.residenceId,
            'unit_label': property.unitLabel,
          }),
          'synced_at': now,
        });
      }
    });
  }

  Future<List<CachedProperty>> getProperties() async {
    final db = await _db;
    final rows = await db.query('cached_properties', orderBy: 'title');
    return rows.map(CachedProperty.fromRow).toList(growable: false);
  }

  /// Ajoute ou met à jour des fiches au cache du carnet.
  ///
  /// Fusion et non remplacement, à l'inverse des biens : la liste arrive
  /// paginée, et repartir de zéro à chaque page viderait le cache de tout ce
  /// que les pages précédentes avaient apporté.
  Future<void> upsertClients(List<ClientModel> clients) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final batch = db.batch();
    for (final client in clients) {
      batch.insert('cached_clients', {
        'id': client.id,
        'full_name': client.fullName,
        'phone': client.phone,
        'status': client.status.code,
        'payload': jsonEncode(_clientToJson(client)),
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Clients du cache, filtrés comme sur le serveur.
  Future<List<ClientModel>> searchClients({
    String? query,
    ClientStatus? status,
    int limit = 50,
  }) async {
    final db = await _db;

    final where = <String>[];
    final args = <Object?>[];

    if (status != null) {
      where.add('status = ?');
      args.add(status.code);
    }

    if (query != null && query.trim().isNotEmpty) {
      final term = '%${query.trim().toLowerCase()}%';
      where.add('(LOWER(full_name) LIKE ? OR phone LIKE ?)');
      args
        ..add(term)
        ..add(term);
    }

    final rows = await db.query(
      'cached_clients',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'synced_at DESC',
      limit: limit,
    );

    return rows
        .map(
          (r) => ClientModel.fromJson(
            jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  /// Fiche portant ce numéro, pour le dédoublonnage sans réseau.
  Future<ClientModel?> findClientByPhone(String phone) async {
    final db = await _db;
    final normalized = _normalizePhone(phone);

    final rows = await db.query(
      'cached_clients',
      where: 'phone = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ClientModel.fromJson(
      jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>,
    );
  }

  /// Remplace les réservations connues d'un bien.
  Future<void> replaceBookingsForProperty(
    String propertyId,
    List<OccupiedPeriodModel> periods,
  ) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'cached_bookings',
        where: 'property_id = ?',
        whereArgs: [propertyId],
      );

      for (final period in periods) {
        await txn.insert('cached_bookings', {
          'id': period.bookingId,
          'property_id': propertyId,
          'check_in_at': period.checkInAt.millisecondsSinceEpoch,
          'check_out_at': period.checkOutAt.millisecondsSinceEpoch,
          'status': period.status.code,
          'payload': jsonEncode({
            'booking_id': period.bookingId,
            'check_in_at': period.checkInAt.toIso8601String(),
            'check_out_at': period.checkOutAt.toIso8601String(),
            'status': period.status.code,
            'client_name': period.clientName,
          }),
          'synced_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Périodes occupées d'un bien, celles du cache et celles encore en file.
  ///
  /// Les deux sources comptent : une réservation saisie il y a cinq minutes et
  /// pas encore envoyée immobilise le bien tout autant qu'une réservation
  /// confirmée par le serveur.
  Future<List<OccupiedPeriodModel>> getOccupiedPeriods(
    String propertyId, {
    DateTime? from,
  }) async {
    final db = await _db;
    final lower = (from ?? DateTime.now()).millisecondsSinceEpoch;

    final cached = await db.query(
      'cached_bookings',
      where: 'property_id = ? AND check_out_at > ?',
      whereArgs: [propertyId, lower],
    );

    final pending = await db.query(
      'pending_bookings',
      where: 'property_id = ? AND sync_status = ?',
      whereArgs: [propertyId, PendingSyncStatus.pending.code],
    );

    final periods = <OccupiedPeriodModel>[
      for (final row in cached)
        OccupiedPeriodModel.fromJson(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        ),
      for (final row in pending)
        OccupiedPeriodModel(
          bookingId: row['client_request_id'] as String,
          checkInAt: DateTime.fromMillisecondsSinceEpoch(
            row['check_in_at'] as int,
          ),
          checkOutAt: row['check_out_at'] == null
              ? DateTime.fromMillisecondsSinceEpoch(row['check_in_at'] as int)
              : DateTime.fromMillisecondsSinceEpoch(row['check_out_at'] as int),
          // En file d'attente : le bien est pris, même si le serveur l'ignore
          // encore.
          status: ReservationStatus.confirmed,
          clientName: null,
        ),
    ];

    return periods;
  }

  // ── File d'envoi ──────────────────────────────────────────────────────────

  /// Met une réservation en file, avec le client s'il est nouveau.
  ///
  /// Les deux écritures sont dans la même transaction : un plantage entre
  /// elles laisserait une réservation pointant vers un client inexistant.
  Future<void> enqueueBooking({
    required PendingBooking booking,
    PendingClient? newClient,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      if (newClient != null) {
        await txn.insert('pending_clients', {
          ...newClient.toRow(createdAt: DateTime.now().millisecondsSinceEpoch),
          'phone': _normalizePhone(newClient.phone),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.insert('pending_bookings', {
        'client_request_id': booking.clientRequestId,
        'local_client_id': booking.localClientId,
        'remote_client_id': booking.remoteClientId,
        'property_id': booking.propertyId,
        'stay_type': booking.stayType.code,
        'check_in_at': booking.checkInAt.millisecondsSinceEpoch,
        'check_out_at': booking.checkOutAt?.millisecondsSinceEpoch,
        'received_amount': booking.receivedAmount,
        'deposit_amount': booking.depositAmount,
        'message': booking.message,
        'is_check_in': booking.isCheckIn ? 1 : 0,
        'sync_status': booking.syncStatus.code,
        'created_at': booking.createdAt.millisecondsSinceEpoch,
        'referrer_name': booking.referrerName,
        'referrer_phone': booking.referrerPhone,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Réservations à envoyer, dans l'ordre de saisie.
  Future<List<PendingBooking>> getQueue({
    PendingSyncStatus status = PendingSyncStatus.pending,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'pending_bookings',
      where: 'sync_status = ?',
      whereArgs: [status.code],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingBooking.fromRow).toList(growable: false);
  }

  Future<PendingClient?> getPendingClient(String localId) async {
    final db = await _db;
    final rows = await db.query(
      'pending_clients',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    return rows.isEmpty ? null : PendingClient.fromRow(rows.first);
  }

  /// Retient l'identifiant serveur d'un client créé hors ligne, pour que les
  /// autres réservations de la file s'y rattachent sans le recréer.
  Future<void> linkClientRemoteId(String localId, String remoteId) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.update(
        'pending_clients',
        {'remote_id': remoteId},
        where: 'local_id = ?',
        whereArgs: [localId],
      );

      await txn.update(
        'pending_bookings',
        {'remote_client_id': remoteId},
        where: 'local_client_id = ?',
        whereArgs: [localId],
      );
    });
  }

  /// Retire une réservation de la file, une fois acceptée par le serveur.
  Future<void> dequeue(String clientRequestId) async {
    final db = await _db;
    await db.delete(
      'pending_bookings',
      where: 'client_request_id = ?',
      whereArgs: [clientRequestId],
    );
  }

  /// Note l'échec d'un envoi, sans retirer la réservation de la file.
  Future<void> markFailure(
    String clientRequestId, {
    required String error,
    required PendingSyncStatus status,
  }) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE pending_bookings '
      'SET sync_status = ?, last_error = ?, attempts = attempts + 1 '
      'WHERE client_request_id = ?',
      [status.code, error, clientRequestId],
    );
  }

  /// Réservations de la file, tous états confondus, mises en forme de réponse
  /// d'API — pour que les listes les affichent avant leur envoi.
  ///
  /// Le nom du client et le titre du bien sont joints ici depuis les caches :
  /// une ligne de liste sans eux ne dirait rien au propriétaire.
  Future<List<Map<String, dynamic>>> pendingBookingsAsJson() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT b.*,
             pc.full_name AS pending_client_name,
             pc.phone     AS pending_client_phone,
             cc.full_name AS cached_client_name,
             cc.phone     AS cached_client_phone,
             p.title      AS property_title
      FROM pending_bookings b
      LEFT JOIN pending_clients pc ON pc.local_id = b.local_client_id
      LEFT JOIN cached_clients cc ON cc.id = b.remote_client_id
      LEFT JOIN cached_properties p ON p.id = b.property_id
      ORDER BY b.created_at ASC
    ''');
    return rows.map(pendingBookingJson).toList(growable: false);
  }

  /// Remet une réservation refusée dans la file d'envoi, à la demande du
  /// propriétaire — après avoir libéré la période, par exemple.
  Future<void> requeue(String clientRequestId) async {
    final db = await _db;
    await db.update(
      'pending_bookings',
      {'sync_status': PendingSyncStatus.pending.code, 'last_error': null},
      where: 'client_request_id = ?',
      whereArgs: [clientRequestId],
    );
  }

  /// Abandonne une réservation refusée, sur décision du propriétaire.
  ///
  /// Son client local part avec elle s'il n'est rattaché à aucune autre
  /// saisie : une fiche orpheline en file serait créée au serveur sans
  /// raison.
  Future<void> discard(String clientRequestId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'pending_bookings',
        columns: ['local_client_id'],
        where: 'client_request_id = ?',
        whereArgs: [clientRequestId],
        limit: 1,
      );
      await txn.delete(
        'pending_bookings',
        where: 'client_request_id = ?',
        whereArgs: [clientRequestId],
      );

      final localClient = rows.isEmpty
          ? null
          : rows.first['local_client_id'] as String?;
      if (localClient == null) return;

      final others = await txn.query(
        'pending_bookings',
        columns: ['client_request_id'],
        where: 'local_client_id = ?',
        whereArgs: [localClient],
        limit: 1,
      );
      if (others.isEmpty) {
        await txn.delete(
          'pending_clients',
          where: 'local_id = ?',
          whereArgs: [localClient],
        );
      }
    });
  }

  /// Identifiant affiché d'une réservation en file, avant que le serveur ne
  /// lui en donne un.
  static String localBookingId(String clientRequestId) =>
      'local-$clientRequestId';

  /// Ligne jointe de la file, au format d'une réservation de l'API.
  @visibleForTesting
  static Map<String, dynamic> pendingBookingJson(Map<String, Object?> row) {
    final booking = PendingBooking.fromRow(row);
    final checkIn = booking.checkInAt.toUtc().toIso8601String();
    // Un passage peut partir sans heure de sortie : il occupe le bien à
    // l'entrée seulement, comme dans le contrôle de chevauchement.
    final checkOut = (booking.checkOutAt ?? booking.checkInAt)
        .toUtc()
        .toIso8601String();
    final amount = booking.receivedAmount ?? 0;
    final clientId = booking.remoteClientId ?? booking.localClientId ?? '';

    return {
      'id': localBookingId(booking.clientRequestId),
      'property_id': booking.propertyId,
      'property': {
        'id': booking.propertyId,
        'title': row['property_title'] as String? ?? '',
        'city': '',
      },
      'client_id': clientId,
      'client': {
        'id': clientId,
        'full_name':
            row['pending_client_name'] ?? row['cached_client_name'] ?? '',
        'phone': row['pending_client_phone'] ?? row['cached_client_phone'] ?? '',
      },
      'status': booking.isCheckIn ? 'in_progress' : 'confirmed',
      'source': 'offline',
      'stay_type': booking.stayType.code,
      'start_date': checkIn,
      'check_in_at': checkIn,
      'end_date': checkOut,
      'check_out_at': checkOut,
      'total_amount': amount,
      'expected_amount': amount,
      'received_amount': amount,
      'deposit_amount': booking.depositAmount,
      'message': booking.message,
      if (booking.referrerName != null)
        'referrer': {'name': booking.referrerName, 'phone': booking.referrerPhone},
      'sync_status': booking.syncStatus.code,
      // Pour l'arbitrage : le motif d'un refus et l'heure de la saisie.
      'last_error': booking.lastError,
      'created_at': booking.createdAt.toUtc().toIso8601String(),
    };
  }

  Future<int> pendingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_bookings WHERE sync_status = ?',
      [PendingSyncStatus.pending.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> conflictCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_bookings WHERE sync_status = ?',
      [PendingSyncStatus.conflict.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> rejectedCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_bookings WHERE sync_status = ?',
      [PendingSyncStatus.rejected.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Forme canonique d'un numéro, identique à celle du serveur : « 07 12 34 »
  /// et « 071234 » doivent désigner la même fiche.
  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-.()]'), '');

  /// `ClientModel` n'a pas de `toJson` — il n'est jamais renvoyé au serveur
  /// tel quel. Le cache reconstruit la forme que `fromJson` sait relire.
  static Map<String, dynamic> _clientToJson(ClientModel client) => {
    'id': client.id,
    'full_name': client.fullName,
    'phone': client.phone,
    'whatsapp': client.whatsapp,
    'id_document_type': client.idDocumentType?.code,
    'id_document_number': client.idDocumentNumber,
    'has_document_front': client.hasDocumentFront,
    'has_document_back': client.hasDocumentBack,
    'documents_status': client.documentsComplete ? 'complete' : 'pending',
    'stats': {
      'total_stays': client.stats.totalStays,
      'total_paid': client.stats.totalPaid,
      'last_stay_at': client.stats.lastStayAt?.toIso8601String(),
    },
    'status': client.status.code,
  };
}

/// Bien tel que conservé en cache, avec de quoi remplir le sélecteur.
class CachedProperty {
  const CachedProperty({
    required this.id,
    required this.title,
    required this.dailyPrice,
    this.residenceId,
    this.residenceName,
    this.unitLabel,
  });

  final String id;
  final String title;
  final double dailyPrice;

  /// `null` pour un bien autonome — y compris sur les lignes écrites avant la
  /// version 2 du schéma, que la migration laisse à `NULL`.
  final String? residenceId;

  /// Nom de la résidence, recopié pour que le sélecteur hors ligne ne dépende
  /// pas d’une seconde table.
  final String? residenceName;
  final String? unitLabel;

  /// Libellé affiché par le sélecteur : « Resi Adja › Studio 1 ».
  ///
  /// Le titre de l’annonce sert de repli quand l’unité n’est pas nommée, et
  /// reste seul pour un bien autonome.
  String get displayLabel {
    final unit = unitLabel?.trim();
    final residence = residenceName?.trim();

    if (residence == null || residence.isEmpty) return title;
    if (unit == null || unit.isEmpty) return '$residence › $title';
    return '$residence › $unit';
  }

  factory CachedProperty.fromRow(Map<String, Object?> row) {
    return CachedProperty(
      id: row['id'] as String,
      title: row['title'] as String,
      dailyPrice: (row['daily_price'] as num?)?.toDouble() ?? 0,
      residenceId: row['residence_id'] as String?,
      residenceName: row['residence_name'] as String?,
      unitLabel: row['unit_label'] as String?,
    );
  }
}
