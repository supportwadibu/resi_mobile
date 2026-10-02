import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/offline/pending_action.dart';
import 'package:resi_africa/core/offline/pending_overlay.dart';

PendingAction _action(
  PendingActionType type, {
  String? target,
  Map<String, dynamic> payload = const {},
  PendingActionState state = PendingActionState.pending,
  String id = 'a1',
}) => PendingAction(
  id: id,
  type: type,
  targetRef: target,
  payload: payload,
  createdAt: DateTime(2026, 10, 1, 10),
  state: state,
);

Map<String, dynamic> _booking(String id, {String status = 'in_progress'}) => {
  'id': id,
  'property_id': 'p1',
  'status': status,
  'check_in_at': '2026-09-30T12:00:00.000Z',
  'check_out_at': '2026-10-04T12:00:00.000Z',
  'end_date': '2026-10-04T12:00:00.000Z',
  'total_amount': 40000,
  'received_amount': 40000,
};

Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'data': items,
  'meta': {'total': items.length, 'currentPage': 1, 'lastPage': 1},
};

List<Map<String, dynamic>> _items(dynamic response) =>
    ((response as Map<String, dynamic>)['data'] as List)
        .cast<Map<String, dynamic>>();

void main() {
  group('réservations', () {
    test('un départ en file clôt la ligne et la marque en attente', () {
      final result = applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {'page': 1},
        data: _page([_booking('b1')]),
        snapshot: OverlaySnapshot(
          actions: [
            _action(
              PendingActionType.bookingCheckOut,
              target: 'b1',
              payload: {'actual_check_out_at': '2026-10-02T11:00:00.000Z'},
            ),
          ],
        ),
      );

      final row = _items(result).single;
      expect(row['status'], 'completed');
      expect(row['actual_check_out_at'], '2026-10-02T11:00:00.000Z');
      expect(localSyncState(row['sync_status']), PendingActionState.pending);
    });

    test('la réponse d’origine n’est pas modifiée — c’est elle qui est en '
        'cache', () {
      final original = _page([_booking('b1')]);
      applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {},
        data: original,
        snapshot: OverlaySnapshot(
          actions: [_action(PendingActionType.bookingCheckOut, target: 'b1')],
        ),
      );

      expect(_items(original).single['status'], 'in_progress');
    });

    test('une réservation saisie hors ligne apparaît en tête de la première '
        'page', () {
      final pending = {
        ..._booking('local-r1', status: 'confirmed'),
        'sync_status': 'pending',
      };
      final snapshot = OverlaySnapshot(pendingBookings: [pending]);

      final first = applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {'page': 1},
        data: _page([_booking('b1')]),
        snapshot: snapshot,
      );
      final second = applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {'page': 2},
        data: _page([_booking('b2')]),
        snapshot: snapshot,
      );

      expect(_items(first).map((b) => b['id']), ['local-r1', 'b1']);
      expect((first as Map)['meta']['total'], 2);
      expect(_items(second).map((b) => b['id']), ['b2']);
    });

    test('le filtre de statut s’applique après l’action', () {
      final result = applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {'status': 'in_progress'},
        data: _page([_booking('b1'), _booking('b2')]),
        snapshot: OverlaySnapshot(
          actions: [_action(PendingActionType.bookingCheckOut, target: 'b1')],
        ),
      );

      expect(_items(result).map((b) => b['id']), ['b2']);
    });

    test('l’historique d’un client ne reçoit pas les saisies des autres', () {
      final data = _page([_booking('b1')]);
      final result = applyOverlay(
        path: '/api/v1/proprio/clients/c1/bookings',
        query: const {},
        data: data,
        snapshot: OverlaySnapshot(
          pendingBookings: [
            {..._booking('local-r1'), 'sync_status': 'pending'},
          ],
        ),
      );

      expect(_items(result).map((b) => b['id']), ['b1']);
    });

    test('un départ anticipé ramène la période et le montant', () {
      final row = applyBookingAction(
        _booking('b1'),
        _action(
          PendingActionType.bookingCheckOutEarly,
          target: 'b1',
          payload: {
            'actual_check_out_at': '2026-10-02T11:00:00.000Z',
            'final_amount': 30000,
          },
        ),
      );

      expect(row['status'], 'completed');
      expect(row['check_out_at'], '2026-10-02T11:00:00.000Z');
      expect(row['planned_check_out_at'], '2026-10-04T12:00:00.000Z');
      expect(row['total_amount'], 30000);
      expect(row['refunded_amount'], 10000);
    });

    test('un conflit n’est pas masqué par une action suivante en attente', () {
      final result = applyOverlay(
        path: '/api/v1/proprio/bookings',
        query: const {},
        data: _page([_booking('b1')]),
        snapshot: OverlaySnapshot(
          actions: [
            _action(
              PendingActionType.bookingExtend,
              target: 'b1',
              id: 'a1',
              state: PendingActionState.conflict,
              payload: {'check_out_at': '2026-10-06T12:00:00.000Z'},
            ),
            _action(
              PendingActionType.bookingCheckOut,
              target: 'b1',
              id: 'a2',
            ),
          ],
        ),
      );

      expect(_items(result).single['sync_status'], 'conflict');
    });

    test('les compteurs de l’accueil suivent les saisies en file', () {
      final result = applyOverlay(
        path: '/api/v1/proprio/bookings/stats',
        query: const {},
        data: const {
          'data': {'in_progress': 2, 'upcoming': 1},
        },
        snapshot: OverlaySnapshot(
          pendingBookings: [
            {..._booking('local-r1', status: 'confirmed'), 'sync_status': 'pending'},
          ],
          actions: [_action(PendingActionType.bookingCheckOut, target: 'b1')],
        ),
      );

      final stats = (result as Map)['data'] as Map;
      expect(stats['in_progress'], 1);
      expect(stats['upcoming'], 2);
    });
  });

  group('clients', () {
    test('une fiche créée hors ligne apparaît, filtrée comme les autres', () {
      final snapshot = OverlaySnapshot(
        actions: [
          _action(
            PendingActionType.clientCreate,
            target: 'local-c9',
            payload: {'full_name': 'Awa Koné', 'phone': '0707070707'},
          ),
        ],
      );

      final all = applyOverlay(
        path: '/api/v1/proprio/clients',
        query: const {'page': 1},
        data: _page([
          {'id': 'c1', 'full_name': 'Jean', 'phone': '01'},
        ]),
        snapshot: snapshot,
      );
      final search = applyOverlay(
        path: '/api/v1/proprio/clients',
        query: const {'page': 1, 'q': 'jean'},
        data: _page([
          {'id': 'c1', 'full_name': 'Jean', 'phone': '01'},
        ]),
        snapshot: snapshot,
      );

      expect(_items(all).first['id'], 'local-c9');
      expect(_items(all).first['sync_status'], 'pending');
      expect(_items(search).map((c) => c['id']), ['c1']);
    });

    test('une modification s’applique à la fiche, sans champ d’affichage', () {
      final result = applyOverlay(
        path: '/api/v1/proprio/clients/c1',
        query: const {},
        data: const {
          'data': {'id': 'c1', 'full_name': 'Jean', 'phone': '01'},
        },
        snapshot: OverlaySnapshot(
          actions: [
            _action(
              PendingActionType.clientUpdate,
              target: 'c1',
              payload: {'full_name': 'Jean Kouassi', '_display': 'x'},
            ),
          ],
        ),
      );

      final client = (result as Map)['data'] as Map;
      expect(client['full_name'], 'Jean Kouassi');
      expect(client.containsKey('_display'), isFalse);
    });
  });

  group('dépenses', () {
    final snapshot = OverlaySnapshot(
      actions: [
        _action(
          PendingActionType.expenseCreate,
          payload: {
            'property_id': 'p1',
            'category': 'cleaning',
            'amount': 5000,
            'spent_at': '2026-10-01T09:00:00.000Z',
            '_display': {
              'property': {'id': 'p1', 'title': 'Studio 1', 'city': 'Abidjan'},
            },
          },
        ),
      ],
    );

    test('une dépense saisie hors ligne s’ajoute à la liste et au total', () {
      final list = applyOverlay(
        path: '/api/v1/proprio/expenses',
        query: const {'page': 1},
        data: _page([
          {'id': 'e1', 'amount': 1000, 'category': 'water'},
        ]),
        snapshot: snapshot,
      );
      final summary = applyOverlay(
        path: '/api/v1/proprio/expenses/summary',
        query: const {},
        data: const {
          'data': {'total': 1000, 'count': 1},
        },
        snapshot: snapshot,
      );

      final added = _items(list).first;
      expect(added['id'], 'local-a1');
      expect(added['property'], isA<Map<String, dynamic>>());
      expect(added.containsKey('_display'), isFalse);
      expect(((summary as Map)['data'] as Map)['total'], 6000);
    });

    test('une dépense hors de la période filtrée n’apparaît pas', () {
      final list = applyOverlay(
        path: '/api/v1/proprio/expenses',
        query: const {'from': '2026-11-01T00:00:00.000Z'},
        data: _page(const []),
        snapshot: snapshot,
      );

      expect(_items(list), isEmpty);
    });
  });
}
