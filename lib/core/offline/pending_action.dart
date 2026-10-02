import 'dart:convert';

/// Action du comptoir saisie sans réseau, autre qu'une création de
/// réservation — qui garde sa propre file, `pending_bookings`.
enum PendingActionType {
  bookingCheckOut('booking_check_out'),
  bookingCheckOutEarly('booking_check_out_early'),
  bookingExtend('booking_extend'),
  bookingUpdate('booking_update'),
  clientCreate('client_create'),
  clientUpdate('client_update'),
  expenseCreate('expense_create');

  const PendingActionType(this.code);

  final String code;

  /// `null` pour un code inconnu — une base écrite par une version ultérieure.
  static PendingActionType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// L'action porte-t-elle sur une réservation ?
  bool get targetsBooking => code.startsWith('booking_');
}

/// Où en est l'action.
enum PendingActionState {
  /// En attente de réseau.
  pending('pending'),

  /// Refusée pour chevauchement de période : à arbitrer, jamais supprimée.
  conflict('conflict'),

  /// Refusée pour une autre raison définitive (forme, droits) : conservée
  /// pour que le propriétaire la voie et décide.
  rejected('rejected');

  const PendingActionState(this.code);

  final String code;

  /// Un code inconnu vaut `pending` : réessayer une saisie est toujours moins
  /// grave que la perdre.
  static PendingActionState fromCode(String? code) {
    for (final state in values) {
      if (state.code == code) return state;
    }
    return PendingActionState.pending;
  }
}

/// Préfixe des identifiants tirés sur l'appareil pour un élément pas encore
/// connu du serveur — fiche client, réservation.
const localIdPrefix = 'local-';

bool isLocalId(String id) => id.startsWith(localIdPrefix);

class PendingAction {
  const PendingAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.targetRef,
    this.filePaths = const {},
    this.state = PendingActionState.pending,
    this.errorCode,
    this.errorMessage,
  });

  /// UUID tiré à la saisie. Sert aussi de `client_request_id` là où le
  /// serveur en accepte un.
  final String id;
  final PendingActionType type;

  /// Élément visé : identifiant serveur, ou `local-…` pour un élément créé
  /// hors ligne lui aussi. `null` pour une création.
  final String? targetRef;

  /// Corps de la requête, en `snake_case` comme l'API l'attend.
  final Map<String, dynamic> payload;

  /// Fichiers à joindre en multipart (pièces d'identité), par nom de champ.
  final Map<String, String> filePaths;

  final DateTime createdAt;
  final PendingActionState state;
  final String? errorCode;
  final String? errorMessage;

  Map<String, Object?> toRow() => {
    'id': id,
    'type': type.code,
    'target_ref': targetRef,
    'payload': jsonEncode(payload),
    'file_paths': filePaths.isEmpty ? null : jsonEncode(filePaths),
    'created_at': createdAt.millisecondsSinceEpoch,
    'state': state.code,
    'error_code': errorCode,
    'error_message': errorMessage,
  };

  /// `null` pour une ligne dont le type est inconnu de cette version.
  static PendingAction? fromRow(Map<String, Object?> row) {
    final type = PendingActionType.fromCode(row['type'] as String?);
    if (type == null) return null;

    return PendingAction(
      id: row['id']! as String,
      type: type,
      targetRef: row['target_ref'] as String?,
      payload: _decodeMap(row['payload']),
      filePaths: _decodeMap(
        row['file_paths'],
      ).map((key, value) => MapEntry(key, value.toString())),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      state: PendingActionState.fromCode(row['state'] as String?),
      errorCode: row['error_code'] as String?,
      errorMessage: row['error_message'] as String?,
    );
  }

  static Map<String, dynamic> _decodeMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }
}
