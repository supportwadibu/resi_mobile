import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/reservation/business_logic/edit_reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/edit_reservation_state.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

/// Faux serveur : répond par le statut demandé, sans réseau.
class _FakeServer extends Interceptor {
  _FakeServer(this.statusCode);

  final int statusCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (statusCode == 409) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 409,
            data: const {
              'code': 'booking_period_conflict',
              'message': 'Ce bien est déjà réservé sur cette période.',
            },
          ),
        ),
      );
      return;
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: const {
          'data': {
            'id': 'b1',
            'property_id': 'p1',
            'status': 'confirmed',
            'start_date': '2026-10-10T12:00:00.000Z',
            'end_date': '2026-10-13T12:00:00.000Z',
            'days_count': 3,
            'total_amount': 60000,
          },
        },
      ),
    );
  }
}

ReservationModel _reservation({double discount = 0, double total = 60000}) {
  return ReservationModel(
    id: 'b1',
    propertyId: 'p1',
    clientId: 'c1',
    status: ReservationStatus.confirmed,
    startDate: DateTime.utc(2026, 10, 10, 12),
    endDate: DateTime.utc(2026, 10, 13, 12),
    checkInAt: DateTime.utc(2026, 10, 10, 12),
    checkOutAt: DateTime.utc(2026, 10, 13, 12),
    daysCount: 3,
    dailyPrice: 20000,
    totalAmount: total,
    expectedAmount: 60000,
    discountAmount: discount,
    source: ReservationSource.offline,
  );
}

EditReservationCubit _cubit(ReservationModel reservation, {int status = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(_FakeServer(status));
  return EditReservationCubit(
    ReservationRepository(dio, sessionRoleFixture()),
    reservation,
  );
}

void main() {
  group('EditReservationState.from', () {
    test('un séjour au tarif suit le tarif : pas de prix convenu figé', () {
      final state = EditReservationState.from(_reservation());
      expect(state.agreedAmount, isNull);
      expect(state.expectedAmount, 60000);
    });

    test('un prix négocié est repris, et un prix aberrant est signalé', () {
      // La fiche signalée : 15 000 F enregistrés pour 60 000 F attendus.
      final state = EditReservationState.from(
        _reservation(discount: 45000, total: 15000),
      );
      expect(state.agreedAmount, 15000);
      expect(state.looksLikePayment, isTrue);
    });
  });

  group('EditReservationCubit', () {
    test('déplacer l’entrée garde la durée du séjour', () {
      final cubit = _cubit(_reservation());
      cubit.setCheckIn(DateTime.utc(2026, 10, 20, 12));

      expect(cubit.state.checkOutAt, DateTime.utc(2026, 10, 23, 12));
      expect(cubit.state.quote.daysCount, 3);
    });

    test('rallonger les dates recalcule le montant attendu', () {
      final cubit = _cubit(_reservation());
      cubit.setCheckOut(DateTime.utc(2026, 10, 15, 12));

      expect(cubit.state.expectedAmount, 100000);
      expect(cubit.state.effectiveAmount, 100000);
    });

    test('un 409 est un conflit à arbitrer, pas une panne', () async {
      final cubit = _cubit(_reservation(), status: 409);
      await cubit.submit();

      expect(cubit.state.status, EditReservationStatus.conflict);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('un envoi réussi rend la réservation réécrite', () async {
      final cubit = _cubit(_reservation());
      await cubit.submit();

      expect(cubit.state.status, EditReservationStatus.success);
      expect(cubit.state.updated?.id, 'b1');
    });
  });
}
