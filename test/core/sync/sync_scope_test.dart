import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/storage/app_database.dart';
import 'package:resi_africa/core/sync/sync_service.dart';
import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

import '../../support/session_role_fixture.dart';

/// Store espion : il note ce qui a ete demande, sans ouvrir de base.
///
/// `AppDatabase` n'ouvre son fichier qu'au premier acces a `database`, et
/// aucune des deux methodes redefinies ici n'y touche : le test reste unitaire.
class _SpyStore extends ReservationLocalStore {
  _SpyStore() : super(AppDatabase.instance);

  final dequeued = <String>[];
  final marked = <String, PendingSyncStatus>{};

  @override
  Future<void> dequeue(String clientRequestId) async {
    dequeued.add(clientRequestId);
  }

  @override
  Future<void> markFailure(
    String clientRequestId, {
    required String error,
    required PendingSyncStatus status,
  }) async {
    marked[clientRequestId] = status;
  }
}

PendingBooking _booking() => PendingBooking(
  clientRequestId: 'req-1',
  propertyId: 'villa',
  stayType: StayType.fullDay,
  checkInAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  remoteClientId: 'client-1',
);

/// Les dependances reseau ne sont jamais appelees par `_handleFailure` : le
/// refus est deja construit quand il y entre.
SyncService _service(_SpyStore store) {
  final dio = Dio();
  final role = sessionRoleFixture();

  return SyncService(
    store,
    ReservationRepository(dio, role),
    ClientsRepository(dio, role),
    Connectivity(),
  );
}

void main() {
  group('isDefinitiveRejection', () {
    test('un logement sorti du perimetre ne se rejoue pas', () {
      // Le proprietaire a retire le logement au gerant entre la saisie et
      // l'envoi. Rejouer bloquerait la file indefiniment.
      expect(isDefinitiveRejection(403, 'out_of_scope'), isTrue);
    });

    test('un gerant suspendu ne se rejoue pas', () {
      expect(isDefinitiveRejection(403, 'manager_not_assigned'), isTrue);
    });

    test('un conflit de periode se rejoue', () {
      // Le proprietaire arbitre, la saisie reste dans la file.
      expect(isDefinitiveRejection(409, 'booking_period_conflict'), isFalse);
    });

    test('une panne reseau se rejoue', () {
      expect(isDefinitiveRejection(null, null), isFalse);
      expect(isDefinitiveRejection(500, null), isFalse);
      expect(isDefinitiveRejection(503, null), isFalse);
    });

    test('un 403 sans code connu se rejoue', () {
      // Un refus qu'on ne sait pas nommer peut etre transitoire — un jeton
      // expire, par exemple. Le supprimer perdrait une saisie du gerant.
      expect(isDefinitiveRejection(403, null), isFalse);
      expect(isDefinitiveRejection(403, 'autre_chose'), isFalse);
    });

    test('un code definitif sous un autre statut ne suffit pas', () {
      // Le couple statut + code fait foi. Un `out_of_scope` renvoye sous un
      // 500 signale une anomalie serveur, pas une decision metier arretee :
      // la saisie se rejoue plutot que d'etre perdue.
      expect(isDefinitiveRejection(500, 'out_of_scope'), isFalse);
      expect(isDefinitiveRejection(409, 'out_of_scope'), isFalse);
      expect(isDefinitiveRejection(null, 'out_of_scope'), isFalse);
    });

    test('un 401 ne se rejoue jamais comme un rejet definitif', () {
      // Le jeton expire est le cas transitoire par excellence : l'interceptor
      // le rafraichit et la passe suivante repart.
      expect(isDefinitiveRejection(401, null), isFalse);
      expect(isDefinitiveRejection(401, 'out_of_scope'), isFalse);
    });
  });

  group('classifyFailure', () {
    // La decision se lit sur le couple (statusCode, code) porte par
    // `AppFailure`, jamais sur le texte du message.

    test('un hors perimetre sort de la file', () {
      final outcome = classifyFailure(
        AppFailure.forbidden(
          message: 'Ce logement ne fait pas partie de votre perimetre.',
          code: 'out_of_scope',
        ),
      );

      expect(outcome, FailureDisposition.rejected);
    });

    test('un gerant suspendu sort de la file', () {
      final outcome = classifyFailure(
        AppFailure.forbidden(code: 'manager_not_assigned'),
      );

      expect(outcome, FailureDisposition.rejected);
    });

    test('un conflit de periode reste en file pour arbitrage', () {
      final outcome = classifyFailure(
        AppFailure.serverError(
          code: 409,
          businessCode: 'booking_period_conflict',
        ),
      );

      expect(outcome, FailureDisposition.conflict);
    });

    test('un 403 sans code connu reste en file et se rejoue', () {
      // Sans cette branche, un jeton expire ferait perdre la saisie du gerant.
      expect(
        classifyFailure(AppFailure.forbidden()),
        FailureDisposition.conflict,
      );
    });

    test('une panne reseau se rejoue', () {
      expect(
        classifyFailure(AppFailure.noInternet()),
        FailureDisposition.retry,
      );
      expect(
        classifyFailure(AppFailure.serverError(code: 500)),
        FailureDisposition.retry,
      );
    });

    test('un refus de validation reste en file pour arbitrage', () {
      // Comportement anterieur, a ne pas casser : la saisie porte de l'argent
      // encaisse et ne doit pas disparaitre sans que le proprietaire le sache.
      expect(
        classifyFailure(AppFailure.validation(errors: const {})),
        FailureDisposition.conflict,
      );
    });
  });

  group('effet reel sur la file', () {
    // La classification ne dit rien de ce qui est ecrit en base. C'est le
    // retrait — pas la valeur rendue — qui debloque la file, et lui seul.

    test('un hors perimetre sort de la file sans etre detruit', () async {
      final store = _SpyStore();

      await _service(store).handleFailureForTest(
        _booking(),
        AppFailure.forbidden(code: 'out_of_scope'),
      );

      // Conservee : la saisie porte de l'argent encaisse au comptoir, et le
      // gerant doit pouvoir la montrer au proprietaire.
      expect(store.dequeued, isEmpty);
      expect(store.marked['req-1'], PendingSyncStatus.rejected);
      // Surtout pas remise en attente : elle repartirait a la passe suivante
      // et bloquerait de nouveau tout ce qui la suit.
      expect(store.marked['req-1'], isNot(PendingSyncStatus.pending));
    });

    test('un gerant suspendu sort de la file sans etre detruit', () async {
      final store = _SpyStore();

      await _service(store).handleFailureForTest(
        _booking(),
        AppFailure.forbidden(code: 'manager_not_assigned'),
      );

      expect(store.dequeued, isEmpty);
      expect(store.marked['req-1'], PendingSyncStatus.rejected);
    });

    test('aucun refus ne detruit jamais une saisie', () async {
      // Verrou transversal : c'est la regle que tout le reste du code protege
      // — « elle porte de l'argent encaisse, la perdre serait pire que tout ».
      final refus = [
        AppFailure.forbidden(code: 'out_of_scope'),
        AppFailure.forbidden(code: 'manager_not_assigned'),
        AppFailure.forbidden(),
        AppFailure.serverError(code: 409),
        AppFailure.validation(errors: const {}),
        AppFailure.noInternet(),
      ];

      for (final failure in refus) {
        final store = _SpyStore();
        await _service(store).handleFailureForTest(_booking(), failure);

        expect(
          store.dequeued,
          isEmpty,
          reason: 'un refus ${failure.statusCode} a detruit la saisie',
        );
      }
    });

    test('un conflit de periode reste en base, jamais retire', () async {
      // Comportement anterieur, a ne pas casser : la saisie porte de l'argent
      // encaisse et attend l'arbitrage du proprietaire.
      final store = _SpyStore();

      await _service(store).handleFailureForTest(
        _booking(),
        AppFailure.serverError(
          code: 409,
          businessCode: 'booking_period_conflict',
        ),
      );

      expect(store.dequeued, isEmpty);
      expect(store.marked['req-1'], PendingSyncStatus.conflict);
    });

    test('un 403 sans code connu n’est jamais retire', () async {
      // Le cas qui ferait perdre le travail du gerant : un jeton expire ne
      // doit pas effacer une saisie.
      final store = _SpyStore();

      await _service(
        store,
      ).handleFailureForTest(_booking(), AppFailure.forbidden());

      expect(store.dequeued, isEmpty);
    });

    test('une panne reseau laisse la saisie en attente', () async {
      final store = _SpyStore();

      await _service(
        store,
      ).handleFailureForTest(_booking(), AppFailure.noInternet());

      expect(store.dequeued, isEmpty);
      expect(store.marked['req-1'], PendingSyncStatus.pending);
    });
  });

  group('SyncReport', () {
    test('un rejet compte comme du travail a annoncer', () {
      // Sans cela, une passe qui n'aurait que des rejets resterait muette et
      // le gerant croirait ses saisies transmises.
      expect(const SyncReport(rejected: 1).hasWork, isTrue);
    });

    test('une passe vide ne dit rien', () {
      expect(const SyncReport().hasWork, isFalse);
    });

    test('les rejets ne se confondent pas avec les conflits', () {
      const report = SyncReport(sent: 1, conflicts: 2, rejected: 3, failed: 4);

      expect(report.sent, 1);
      expect(report.conflicts, 2);
      expect(report.rejected, 3);
      expect(report.failed, 4);
    });
  });
}
