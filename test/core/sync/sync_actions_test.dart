import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/offline/pending_action.dart';
import 'package:resi_africa/core/offline/pending_action_store.dart';
import 'package:resi_africa/core/sync/pending_action_sender.dart';
import 'package:resi_africa/core/sync/sync_service.dart';
import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import 'package:resi_africa/features/expense/data/repositories/expense_repository.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

import '../../support/memory_database.dart';
import '../../support/session_role_fixture.dart';
import '../../support/translations_fixture.dart';

class _Online implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => const [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

/// Serveur des réservations : rend un identifiant serveur à la création.
class _Reservations extends ReservationRepository {
  _Reservations() : super(Dio(), sessionRoleFixture());

  final created = <String>[];

  @override
  Future<ReservationModel> createOwnerBooking({
    required String propertyId,
    required String clientId,
    required StayType stayType,
    required DateTime checkInAt,
    DateTime? checkOutAt,
    double? receivedAmount,
    double? depositAmount,
    String? message,
    bool isCheckIn = false,
    String? clientRequestId,
    String? referrerName,
    String? referrerPhone,
  }) async {
    created.add(clientRequestId!);
    return ReservationModel.fromJson({
      'id': 'srv-$clientRequestId',
      'status': 'in_progress',
    });
  }
}

/// Envoi des actions : note ce qui part, ou lève le refus prévu.
class _Sender extends PendingActionSender {
  _Sender()
    : super(
        ReservationRepository(Dio(), sessionRoleFixture()),
        ClientsRepository(Dio(), sessionRoleFixture()),
        ExpenseRepository(Dio(), sessionRoleFixture()),
      );

  final sent = <(PendingActionType, String?)>[];
  final failures = <PendingActionType, AppFailure>{};

  @override
  Future<String?> send(PendingAction action, String? target) async {
    final failure = failures[action.type];
    if (failure != null) throw failure;
    sent.add((action.type, target));
    return action.type == PendingActionType.clientCreate ? 'srv-client' : null;
  }
}

PendingAction _action(
  String id,
  PendingActionType type, {
  String? target,
  required int at,
}) => PendingAction(
  id: id,
  type: type,
  targetRef: target,
  payload: const {},
  createdAt: DateTime.fromMillisecondsSinceEpoch(at),
);

void main() {
  setUpAll(loadTestTranslations);

  late MemoryDatabase database;
  late ReservationLocalStore bookings;
  late PendingActionStore actions;
  late _Reservations reservations;
  late _Sender sender;
  late SyncService sync;

  setUp(() async {
    database = await MemoryDatabase.open();
    bookings = ReservationLocalStore(database);
    actions = PendingActionStore(database);
    reservations = _Reservations();
    sender = _Sender();
    sync = SyncService(
      bookings,
      reservations,
      ClientsRepository(Dio(), sessionRoleFixture()),
      _Online(),
      actions: actions,
      sender: sender,
    );
  });

  tearDown(() => database.close());

  test('un départ saisi après sa réservation hors ligne part après elle, sur '
      'l’identifiant du serveur', () async {
    await bookings.enqueueBooking(
      booking: PendingBooking(
        clientRequestId: 'r1',
        propertyId: 'villa',
        stayType: StayType.fullDay,
        checkInAt: DateTime(2026, 10, 1),
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        remoteClientId: 'client-1',
      ),
    );
    await actions.enqueue(
      _action(
        'a1',
        PendingActionType.bookingCheckOut,
        target: ReservationLocalStore.localBookingId('r1'),
        at: 2000,
      ),
    );

    final report = await sync.synchronize();

    expect(reservations.created, ['r1']);
    expect(sender.sent, [(PendingActionType.bookingCheckOut, 'srv-r1')]);
    expect(report.sent, 2);
    expect(await actions.all(), isEmpty);
  });

  test('une action dont la cible n’est pas partie attend, sans bloquer le '
      'reste', () async {
    await actions.enqueue(
      _action(
        'a1',
        PendingActionType.bookingExtend,
        target: 'local-inconnue',
        at: 1000,
      ),
    );
    await actions.enqueue(
      _action('a2', PendingActionType.bookingCheckOut, target: 'b2', at: 2000),
    );

    await sync.synchronize();

    expect(sender.sent, [(PendingActionType.bookingCheckOut, 'b2')]);
    final left = await actions.all();
    expect(left.map((a) => a.id), ['a1']);
    expect(left.single.state, PendingActionState.pending);
  });

  test('un départ déjà enregistré au premier envoi vaut succès au rejeu',
      () async {
    sender.failures[PendingActionType.bookingCheckOut] = AppFailure.serverError(
      code: 409,
      businessCode: 'booking_already_completed',
    );
    await actions.enqueue(
      _action('a1', PendingActionType.bookingCheckOut, target: 'b1', at: 1),
    );

    final report = await sync.synchronize();

    expect(report.sent, 1);
    expect(await actions.all(), isEmpty);
  });

  test('un chevauchement passe en conflit, conservé', () async {
    sender.failures[PendingActionType.bookingExtend] = AppFailure.serverError(
      code: 409,
      businessCode: 'booking_period_conflict',
    );
    await actions.enqueue(
      _action('a1', PendingActionType.bookingExtend, target: 'b1', at: 1),
    );

    await sync.synchronize();

    final left = (await actions.all()).single;
    expect(left.state, PendingActionState.conflict);
    expect(sync.conflictCount.value, 1);
  });

  test('un refus de forme passe en refus, conservé', () async {
    sender.failures[PendingActionType.expenseCreate] = AppFailure.validation(
      errors: const {},
    );
    await actions.enqueue(_action('a1', PendingActionType.expenseCreate, at: 1));

    await sync.synchronize();

    expect((await actions.all()).single.state, PendingActionState.rejected);
    expect(sync.rejectedCount.value, 1);
  });

  test('une panne réseau garde l’action en attente', () async {
    sender.failures[PendingActionType.expenseCreate] = AppFailure.noInternet();
    await actions.enqueue(_action('a1', PendingActionType.expenseCreate, at: 1));

    await sync.synchronize();

    expect((await actions.all()).single.state, PendingActionState.pending);
    expect(sync.pendingCount.value, 1);
  });

  test('une fiche créée hors ligne puis modifiée part avant sa modification, '
      'qui vise son identifiant serveur', () async {
    await actions.enqueue(
      _action(
        'a1',
        PendingActionType.clientCreate,
        target: 'local-c1',
        at: 1000,
      ),
    );
    await actions.enqueue(
      _action(
        'a2',
        PendingActionType.clientUpdate,
        target: 'local-c1',
        at: 2000,
      ),
    );

    await sync.synchronize();

    expect(sender.sent, [
      (PendingActionType.clientCreate, null),
      (PendingActionType.clientUpdate, 'srv-client'),
    ]);
  });
}
