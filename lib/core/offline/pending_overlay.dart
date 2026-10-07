import 'pending_action.dart';

/// Ce que l'appareil sait et que le serveur ignore encore.
class OverlaySnapshot {
  const OverlaySnapshot({
    this.actions = const [],
    this.pendingBookings = const [],
  });

  /// Actions en file, tous états confondus, dans l'ordre de saisie.
  final List<PendingAction> actions;

  /// Réservations saisies hors ligne, déjà mises en forme de réponse d'API
  /// (`id` = `local-<client_request_id>`, `sync_status` renseigné).
  final List<Map<String, dynamic>> pendingBookings;

  bool get isEmpty => actions.isEmpty && pendingBookings.isEmpty;
}

/// État de synchronisation d'un élément affiché, lu dans `sync_status`.
///
/// `null` pour un élément connu du serveur — `synced`, ou champ absent. Les
/// réservations comptoir portent `synced` côté API ; seule la superposition
/// pose les autres valeurs.
PendingActionState? localSyncState(Object? raw) {
  if (raw is! String || raw == 'synced') return null;
  for (final state in PendingActionState.values) {
    if (state.code == raw) return state;
  }
  return null;
}

/// Applique [snapshot] à la réponse d'une lecture.
///
/// Fonction pure, appelée sur chaque réponse servie à un repository — qu'elle
/// vienne du réseau ou du cache : une saisie hors ligne doit se voir aussitôt,
/// et rester visible tant que le serveur ne l'a pas reçue. La réponse d'origine
/// n'est jamais modifiée en place : c'est elle qui est gardée en cache.
dynamic applyOverlay({
  required String path,
  required Map<String, dynamic> query,
  required dynamic data,
  required OverlaySnapshot snapshot,
}) {
  if (snapshot.isEmpty || data is! Map<String, dynamic>) return data;

  if (path.endsWith('/bookings/stats')) return _bookingStats(data, snapshot);
  if (_bookingList.hasMatch(path)) return _bookings(data, query, snapshot);
  if (path.endsWith('/clients')) return _clients(data, query, snapshot);
  final client = _clientDetail.firstMatch(path);
  if (client != null) return _clientDetailOverlay(data, client[1]!, snapshot);
  if (path.endsWith('/expenses/summary')) {
    return _expenseSummary(data, query, snapshot);
  }
  if (path.endsWith('/expenses')) return _expenses(data, query, snapshot);
  return data;
}

/// Liste des réservations du compte, et non l'historique d'un client
/// (`/clients/:id/bookings`), où une saisie d'un autre client n'a rien à
/// faire.
final _bookingList = RegExp(r'/(proprio|gerant)/bookings$');
final _clientDetail = RegExp(r'/clients/([^/]+)$');

// ── Réservations ────────────────────────────────────────────────────────────

/// Applique une action à une réservation, au format de l'API.
///
/// Exposée seule : un cubit qui vient de mettre une action en file en tire
/// l'état optimiste de la réservation, par la même règle que les listes.
Map<String, dynamic> applyBookingAction(
  Map<String, dynamic> booking,
  PendingAction action,
) {
  final p = action.payload;
  final next = Map<String, dynamic>.of(booking);

  switch (action.type) {
    case PendingActionType.bookingCheckOut:
      next['status'] = 'completed';
      next['actual_check_out_at'] = p['actual_check_out_at'];

    case PendingActionType.bookingCheckOutEarly:
      final at = p['actual_check_out_at'];
      final finalAmount = (p['final_amount'] as num?)?.toDouble();
      final paid =
          (booking['received_amount'] as num?)?.toDouble() ??
          (booking['total_amount'] as num?)?.toDouble() ??
          0;
      next
        ..['status'] = 'completed'
        ..['actual_check_out_at'] = at
        ..['planned_check_out_at'] =
            booking['check_out_at'] ?? booking['end_date']
        ..['planned_total_amount'] = booking['total_amount']
        ..['check_out_at'] = at
        ..['end_date'] = at;
      if (finalAmount != null) {
        next
          ..['total_amount'] = finalAmount
          ..['received_amount'] = finalAmount
          ..['refunded_amount'] = paid - finalAmount;
      }

    case PendingActionType.bookingExtend:
      next
        ..['check_out_at'] = p['check_out_at']
        ..['end_date'] = p['check_out_at'];
      final amount = p['received_amount'];
      if (amount != null) {
        next
          ..['received_amount'] = amount
          ..['total_amount'] = amount;
      }

    case PendingActionType.bookingUpdate:
      next
        ..['property_id'] = p['property_id'] ?? booking['property_id']
        ..['stay_type'] = p['stay_type'] ?? booking['stay_type']
        ..['check_in_at'] = p['check_in_at']
        ..['start_date'] = p['check_in_at']
        ..['check_out_at'] = p['check_out_at']
        ..['end_date'] = p['check_out_at']
        ..['deposit_amount'] = p['deposit_amount']
        ..['message'] = p['message'];
      final amount = p['received_amount'];
      if (amount != null) {
        next
          ..['received_amount'] = amount
          ..['total_amount'] = amount;
      }

    case PendingActionType.clientCreate ||
        PendingActionType.clientUpdate ||
        PendingActionType.expenseCreate:
      return booking;
  }

  next['sync_status'] = _worst(booking['sync_status'], action.state);
  return next;
}

Map<String, dynamic> _bookings(
  Map<String, dynamic> response,
  Map<String, dynamic> query,
  OverlaySnapshot snapshot,
) {
  final items = response['data'];
  if (items is! List) return response;

  final status = query['status'] as String?;
  final propertyId = query['property_id'] as String?;
  final firstPage = (query['page'] ?? 1).toString() == '1';

  bool matches(Map<String, dynamic> booking) =>
      (status == null || booking['status'] == status) &&
      (propertyId == null || booking['property_id'] == propertyId);

  final updated = [
    for (final item in items)
      if (item is Map<String, dynamic>) _withBookingActions(item, snapshot),
  ].where(matches).toList();

  // Une saisie hors ligne n'a pas de rang dans la pagination du serveur :
  // elle se montre en tête de la première page, la plus récente d'abord.
  final added = firstPage
      ? snapshot.pendingBookings.reversed
            .map((b) => _withBookingActions(b, snapshot))
            .where(matches)
            .toList()
      : const <Map<String, dynamic>>[];

  return _withItems(response, [...added, ...updated], added.length);
}

Map<String, dynamic> _withBookingActions(
  Map<String, dynamic> booking,
  OverlaySnapshot snapshot,
) {
  var current = booking;
  for (final action in snapshot.actions) {
    if (action.type.targetsBooking && action.targetRef == booking['id']) {
      current = applyBookingAction(current, action);
    }
  }
  return current;
}

/// Compteurs de l'accueil : un séjour saisi ou clos hors ligne doit s'y voir.
Map<String, dynamic> _bookingStats(
  Map<String, dynamic> response,
  OverlaySnapshot snapshot,
) {
  final stats = response['data'];
  if (stats is! Map<String, dynamic>) return response;

  var inProgress = (stats['in_progress'] as num?)?.toInt() ?? 0;
  var upcoming = (stats['upcoming'] as num?)?.toInt() ?? 0;

  for (final booking in snapshot.pendingBookings) {
    if (booking['sync_status'] != PendingActionState.pending.code) continue;
    if (booking['status'] == 'in_progress') {
      inProgress++;
    } else if (booking['status'] == 'confirmed') {
      upcoming++;
    }
  }

  // Un départ en file ne concerne qu'un séjour en cours : la clôture d'une
  // réservation à venir est refusée, au comptoir comme au serveur.
  final checkOuts = snapshot.actions.where(
    (a) =>
        a.state == PendingActionState.pending &&
        (a.type == PendingActionType.bookingCheckOut ||
            a.type == PendingActionType.bookingCheckOutEarly),
  );
  inProgress -= checkOuts.length;

  return {
    ...response,
    'data': {
      ...stats,
      'in_progress': inProgress < 0 ? 0 : inProgress,
      'upcoming': upcoming,
    },
  };
}

// ── Clients ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _clients(
  Map<String, dynamic> response,
  Map<String, dynamic> query,
  OverlaySnapshot snapshot,
) {
  final items = response['data'];
  if (items is! List) return response;

  final status = query['status'] as String?;
  final term = (query['q'] as String?)?.trim().toLowerCase() ?? '';
  final firstPage = (query['page'] ?? 1).toString() == '1';

  bool matches(Map<String, dynamic> client) {
    if (status != null && (client['status'] ?? 'active') != status) {
      return false;
    }
    if (term.isEmpty) return true;
    final name = (client['full_name'] as String? ?? '').toLowerCase();
    final phone = client['phone'] as String? ?? '';
    return name.contains(term) || phone.contains(term);
  }

  final updated = [
    for (final item in items)
      if (item is Map<String, dynamic>) _withClientActions(item, snapshot),
  ].where(matches).toList();

  final added = firstPage
      ? snapshot.actions.reversed
            .where((a) => a.type == PendingActionType.clientCreate)
            .map((a) => _withClientActions(_createdClient(a), snapshot))
            .where(matches)
            .toList()
      : const <Map<String, dynamic>>[];

  return _withItems(response, [...added, ...updated], added.length);
}

Map<String, dynamic> _clientDetailOverlay(
  Map<String, dynamic> response,
  String id,
  OverlaySnapshot snapshot,
) {
  final client = response['data'];
  if (client is! Map<String, dynamic>) return response;
  return {...response, 'data': _withClientActions(client, snapshot)};
}

/// Fiche d'un client créé hors ligne, au format de l'API.
Map<String, dynamic> _createdClient(PendingAction action) => {
  ..._sendable(action.payload),
  'id': action.targetRef ?? '$localIdPrefix${action.id}',
  'status': 'active',
  'has_document_front': action.filePaths.containsKey('id_document_front'),
  'has_document_back': action.filePaths.containsKey('id_document_back'),
  'stats': const {'total_stays': 0, 'total_paid': 0},
  'sync_status': action.state.code,
};

Map<String, dynamic> _withClientActions(
  Map<String, dynamic> client,
  OverlaySnapshot snapshot,
) {
  var current = client;
  for (final action in snapshot.actions) {
    if (action.type != PendingActionType.clientUpdate ||
        action.targetRef != client['id']) {
      continue;
    }
    current = {
      ...current,
      ..._sendable(action.payload),
      if (action.filePaths.containsKey('id_document_front'))
        'has_document_front': true,
      if (action.filePaths.containsKey('id_document_back'))
        'has_document_back': true,
      'sync_status': _worst(current['sync_status'], action.state),
    };
  }
  return current;
}

// ── Dépenses ────────────────────────────────────────────────────────────────

Iterable<Map<String, dynamic>> _pendingExpenses(
  Map<String, dynamic> query,
  OverlaySnapshot snapshot,
) {
  final propertyId = query['property_id'] as String?;
  final residenceId = query['residence_id'] as String?;
  final category = query['category'] as String?;
  final from = DateTime.tryParse(query['from']?.toString() ?? '');
  final to = DateTime.tryParse(query['to']?.toString() ?? '');

  return snapshot.actions.reversed
      .where((a) => a.type == PendingActionType.expenseCreate)
      .map(
        (a) => {
          ..._sendable(a.payload),
          ...?(a.payload['_display'] as Map<String, dynamic>?),
          'id': '$localIdPrefix${a.id}',
          'sync_status': a.state.code,
        },
      )
      .where((e) {
        final spentAt = DateTime.tryParse(e['spent_at']?.toString() ?? '');
        return (propertyId == null || e['property_id'] == propertyId) &&
            (residenceId == null || e['residence_id'] == residenceId) &&
            (category == null || e['category'] == category) &&
            (from == null || spentAt == null || !spentAt.isBefore(from)) &&
            (to == null || spentAt == null || !spentAt.isAfter(to));
      });
}

Map<String, dynamic> _expenses(
  Map<String, dynamic> response,
  Map<String, dynamic> query,
  OverlaySnapshot snapshot,
) {
  final items = response['data'];
  if (items is! List) return response;
  if ((query['page'] ?? 1).toString() != '1') return response;

  final added = _pendingExpenses(query, snapshot).toList();
  return _withItems(response, [...added, ...items], added.length);
}

Map<String, dynamic> _expenseSummary(
  Map<String, dynamic> response,
  Map<String, dynamic> query,
  OverlaySnapshot snapshot,
) {
  final summary = response['data'];
  if (summary is! Map<String, dynamic>) return response;

  final added = _pendingExpenses(
    query,
    snapshot,
  ).where((e) => e['sync_status'] == PendingActionState.pending.code);
  if (added.isEmpty) return response;

  final total = added.fold<double>(
    (summary['total'] as num?)?.toDouble() ?? 0,
    (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0),
  );

  return {
    ...response,
    'data': {
      ...summary,
      'total': total,
      'count': ((summary['count'] as num?)?.toInt() ?? 0) + added.length,
      'by_category': _withPendingCategories(
        summary['by_category'],
        added,
        total,
      ),
    },
  };
}

/// Ventilation complétée des dépenses en attente, parts recalculées.
///
/// Sans elle, le total intégrait une saisie hors ligne que la ventilation
/// ignorait : les catégories ne sommaient plus au total affiché au-dessus, et
/// la dépense semblait n'avoir été comptée qu'à moitié.
List<Map<String, dynamic>> _withPendingCategories(
  Object? raw,
  Iterable<Map<String, dynamic>> pending,
  double total,
) {
  final buckets = <String, Map<String, dynamic>>{
    if (raw is List)
      for (final entry in raw.whereType<Map<String, dynamic>>())
        if (entry['category'] is String)
          entry['category'] as String: Map<String, dynamic>.of(entry),
  };

  for (final expense in pending) {
    final category = expense['category'] as String? ?? 'other';
    final bucket = buckets.putIfAbsent(
      category,
      () => {'category': category, 'amount': 0, 'count': 0},
    );
    bucket['amount'] =
        ((bucket['amount'] as num?) ?? 0) + ((expense['amount'] as num?) ?? 0);
    bucket['count'] = ((bucket['count'] as num?)?.toInt() ?? 0) + 1;
  }

  // Même règle que le serveur : part arrondie au pourcent, nulle sur un
  // total nul, catégories les plus lourdes d'abord.
  final list = buckets.values.toList()
    ..sort(
      (a, b) =>
          ((b['amount'] as num?) ?? 0).compareTo((a['amount'] as num?) ?? 0),
    );
  for (final bucket in list) {
    final amount = ((bucket['amount'] as num?) ?? 0).toDouble();
    bucket['share_percent'] = total > 0 ? (amount / total * 100).round() : 0;
  }
  return list;
}

// ── Outils ──────────────────────────────────────────────────────────────────

/// Charge utile sans ses champs d'affichage (`_display`), qui ne partent
/// jamais au serveur.
Map<String, dynamic> _sendable(Map<String, dynamic> payload) => {
  for (final entry in payload.entries)
    if (!entry.key.startsWith('_')) entry.key: entry.value,
};

/// Garde l'état le plus grave : un conflit ne doit pas être masqué par une
/// action suivante encore en attente.
String _worst(Object? current, PendingActionState next) {
  const rank = {'pending': 1, 'rejected': 2, 'conflict': 3};
  final now = current is String ? rank[current] ?? 0 : 0;
  return (rank[next.code] ?? 0) >= now ? next.code : current! as String;
}

Map<String, dynamic> _withItems(
  Map<String, dynamic> response,
  List<dynamic> items,
  int added,
) {
  final meta = response['meta'];
  return {
    ...response,
    'data': items,
    if (meta is Map<String, dynamic> && added > 0)
      'meta': {
        ...meta,
        'total': ((meta['total'] as num?)?.toInt() ?? 0) + added,
      },
  };
}
