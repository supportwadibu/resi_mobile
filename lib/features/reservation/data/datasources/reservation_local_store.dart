import 'dart:convert';

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

  factory PendingBooking.fromRow(Map<String, Object?> row) {
    return PendingBooking(
      clientRequestId: row['client_request_id'] as String,
      localClientId: row['local_client_id'] as String?,
      remoteClientId: row['remote_client_id'] as String?,
      propertyId: row['property_id'] as String,
      stayType: StayType.fromCode(row['stay_type'] as String?),
      checkInAt: DateTime.fromMillisecondsSinceEpoch(
        row['check_in_at'] as int,
      ),
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
  conflict('conflict');

  const PendingSyncStatus(this.code);

  final String code;

  static PendingSyncStatus fromCode(String? code) =>
      code == 'conflict' ? PendingSyncStatus.conflict : PendingSyncStatus.pending;
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
  });

  final String localId;
  final String? remoteId;
  final String fullName;
  final String phone;
  final String? documentFrontPath;
  final String? documentBackPath;

  factory PendingClient.fromRow(Map<String, Object?> row) {
    return PendingClient(
      localId: row['local_id'] as String,
      remoteId: row['remote_id'] as String?,
      fullName: row['full_name'] as String,
      phone: row['phone'] as String,
      documentFrontPath: row['document_front_path'] as String?,
      documentBackPath: row['document_back_path'] as String?,
    );
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
  Future<void> replaceProperties(List<PropertyModel> properties) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete('cached_properties');
      for (final property in properties) {
        await txn.insert('cached_properties', {
          'id': property.id,
          'title': property.title,
          'daily_price': property.pricing.dailyPrice,
          // Seuls ces trois champs servent au formulaire hors ligne : la
          // fiche complète du bien reste au serveur, et la recopier ici
          // obligerait à migrer le cache à chaque évolution de l'API.
          'payload': jsonEncode({
            'id': property.id,
            'title': property.title,
            'daily_price': property.pricing.dailyPrice,
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
      args..add(term)..add(term);
    }

    final rows = await db.query(
      'cached_clients',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'synced_at DESC',
      limit: limit,
    );

    return rows
        .map((r) => ClientModel.fromJson(
              jsonDecode(r['payload'] as String) as Map<String, dynamic>,
            ))
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
              : DateTime.fromMillisecondsSinceEpoch(
                  row['check_out_at'] as int,
                ),
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
          'local_id': newClient.localId,
          'remote_id': newClient.remoteId,
          'full_name': newClient.fullName,
          'phone': _normalizePhone(newClient.phone),
          'document_front_path': newClient.documentFrontPath,
          'document_back_path': newClient.documentBackPath,
          'created_at': DateTime.now().millisecondsSinceEpoch,
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
  });

  final String id;
  final String title;
  final double dailyPrice;

  factory CachedProperty.fromRow(Map<String, Object?> row) {
    return CachedProperty(
      id: row['id'] as String,
      title: row['title'] as String,
      dailyPrice: (row['daily_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
