import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_check_out_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_check_out_state.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
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
              'status': 'completed',
              'start_date': '2026-09-01T12:00:00.000Z',
              'end_date': '2026-09-08T12:00:00.000Z',
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
            'code': 'stay_not_started',
            'message': 'Le séjour n’a pas encore commencé.',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

({StayCheckOutCubit cubit, _StubInterceptor spy}) _build({int status = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _StubInterceptor(status: status);
  dio.interceptors.add(spy);
  return (
    cubit: StayCheckOutCubit(ReservationRepository(dio, sessionRoleFixture())),
    spy: spy,
  );
}

void main() {
  group('StayCheckOutCubit', () {
    test('clôture sur la route de check-out, sans corps', () async {
      final built = _build();

      await built.cubit.submit('book_1');

      final sent = built.spy.captured.single;
      expect(sent.method, 'PATCH');
      expect(sent.path, contains('/proprio/bookings/book_1/check-out'));
      expect(sent.data, isNull);
    });

    test('un succès porte la réservation clôturée par le serveur', () async {
      final built = _build();

      await built.cubit.submit('book_1');

      final state = built.cubit.state;
      expect(state, isA<StayCheckOutSuccess>());
      expect(
        (state as StayCheckOutSuccess).reservation.status,
        ReservationStatus.completed,
      );
    });

    test('un refus métier remonte le message du serveur', () async {
      final built = _build(status: 422);

      await built.cubit.submit('book_1');

      final state = built.cubit.state;
      expect(state, isA<StayCheckOutFailure>());
      expect((state as StayCheckOutFailure).message, isNotEmpty);
    });

    test('une panne réseau est un échec', () async {
      final built = _build(status: 500);

      await built.cubit.submit('book_1');

      expect(built.cubit.state, isA<StayCheckOutFailure>());
    });

    test('l’envoi passe par un état de soumission', () async {
      // L'écran s'en sert pour désactiver les boutons : sans lui, deux appuis
      // enverraient deux clôtures.
      final built = _build();
      final seen = <StayCheckOutState>[];
      built.cubit.stream.listen(seen.add);

      await built.cubit.submit('book_1');
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, isA<StayCheckOutSubmitting>());
    });
  });

  group('ReservationModel.hasStarted', () {
    final reservation = ReservationModel.fromJson(const {
      'id': 'book_1',
      'property_id': 'studio-1',
      'status': 'confirmed',
      'start_date': '2026-10-01T00:00:00.000Z',
      'check_in_at': '2026-10-01T14:00:00.000Z',
      'end_date': '2026-10-03T12:00:00.000Z',
    });

    test('faux avant l’heure d’entrée, même le jour même', () {
      expect(reservation.hasStarted(DateTime.utc(2026, 10, 1, 9)), isFalse);
    });

    test('vrai à partir de l’heure d’entrée', () {
      expect(reservation.hasStarted(DateTime.utc(2026, 10, 1, 14)), isTrue);
    });
  });
}
