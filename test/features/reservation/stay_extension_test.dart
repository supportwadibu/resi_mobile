import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_extension_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_extension_state.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

/// Réponse du serveur, ou erreur si [status] n'est pas 200.
class _StubInterceptor extends Interceptor {
  _StubInterceptor({this.status = 200});

  final int status;
  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);

    if (status == 200) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: const {
            'data': {
              'id': 'book_1',
              'property_id': 'studio-1',
              'status': 'in_progress',
              'start_date': '2026-10-01T12:00:00.000Z',
              'end_date': '2026-10-08T12:00:00.000Z',
              'days_count': 7,
              'daily_price': 25000,
              'total_amount': 175000,
              'received_amount': 175000,
            },
          },
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: const {
            'code': 'booking_period_conflict',
            'message': 'Ce bien est déjà réservé sur la période demandée.',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

({StayExtensionCubit cubit, _StubInterceptor spy}) _build({int status = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _StubInterceptor(status: status);
  dio.interceptors.add(spy);
  return (
    cubit: StayExtensionCubit(ReservationRepository(dio, sessionRoleFixture())),
    spy: spy,
  );
}

void main() {
  final newCheckOut = DateTime.utc(2026, 10, 8, 12);

  group('StayExtensionCubit', () {
    test('envoie la nouvelle sortie sur la route de prolongation', () async {
      final built = _build();

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

      final sent = built.spy.captured.single;
      expect(sent.method, 'PATCH');
      expect(sent.path, contains('/proprio/bookings/book_1/extend'));
      expect((sent.data as Map)['check_out_at'], newCheckOut.toIso8601String());
    });

    test(
      'sans montant renégocié, aucun received_amount n’est envoyé',
      () async {
        // Le serveur réajuste alors sur le nouveau montant attendu ; imposer
        // notre calcul le ferait passer pour un prix négocié.
        final built = _build();

        await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

        expect(
          (built.spy.captured.single.data as Map).containsKey(
            'received_amount',
          ),
          isFalse,
        );
      },
    );

    test('un montant renégocié est transmis', () async {
      final built = _build();

      await built.cubit.submit(
        bookingId: 'book_1',
        checkOutAt: newCheckOut,
        receivedAmount: 150000,
      );

      expect(
        (built.spy.captured.single.data as Map)['received_amount'],
        150000,
      );
    });

    test('un succès porte la réservation réécrite par le serveur', () async {
      // C'est elle qui fait foi sur le montant dû, pas l'estimation affichée.
      final built = _build();

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

      final state = built.cubit.state;
      expect(state, isA<StayExtensionSuccess>());
      expect((state as StayExtensionSuccess).reservation.daysCount, 7);
      expect(state.reservation.receivedAmount, 175000);
    });

    test('un 409 est un conflit de période, pas une panne', () async {
      // Le propriétaire doit pouvoir raccourcir sa demande : traiter ce cas
      // comme un échec ordinaire lui dirait de réessayer à l'identique.
      final built = _build(status: 409);

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

      expect(built.cubit.state, isA<StayExtensionConflict>());
    });

    test('un 422 reste un échec ordinaire', () async {
      final built = _build(status: 422);

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

      expect(built.cubit.state, isA<StayExtensionFailure>());
      expect(built.cubit.state, isNot(isA<StayExtensionConflict>()));
    });

    test('une panne réseau est un échec ordinaire', () async {
      final built = _build(status: 500);

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);

      expect(built.cubit.state, isA<StayExtensionFailure>());
    });

    test('l’envoi passe par un état de soumission', () async {
      // L'écran s'en sert pour désactiver le bouton : sans lui, deux appuis
      // enverraient deux prolongations.
      final built = _build();
      final seen = <StayExtensionState>[];
      built.cubit.stream.listen(seen.add);

      await built.cubit.submit(bookingId: 'book_1', checkOutAt: newCheckOut);
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, isA<StayExtensionSubmitting>());
    });
  });
}
