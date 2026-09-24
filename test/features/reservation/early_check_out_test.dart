import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/reservation/business_logic/early_check_out_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/early_check_out_state.dart';
import 'package:resi_africa/features/reservation/data/models/early_check_out_quote.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

const _quote = {
  'actual_check_out_at': '2026-09-26T09:00:00.000Z',
  'planned_check_out_at': '2026-09-29T09:00:00.000Z',
  'planned_days': 5,
  'billed_days': 2,
  'paid_amount': 100000,
  'proposed_amount': 40000,
  'refund_amount': 60000,
};

const _closed = {
  'id': 'book_1',
  'property_id': 'studio-1',
  'status': 'completed',
  'start_date': '2026-09-24T09:00:00.000Z',
  'end_date': '2026-09-26T09:00:00.000Z',
  'days_count': 2,
  'daily_price': 20000,
  'total_amount': 40000,
  'received_amount': 40000,
  'refunded_amount': 60000,
  'planned_total_amount': 100000,
  'planned_check_out_at': '2026-09-29T09:00:00.000Z',
};

/// Répond au chiffrage et à la clôture, ou rejette avec [status].
class _StubInterceptor extends Interceptor {
  _StubInterceptor({this.previewStatus = 200, this.checkOutStatus = 200});

  final int previewStatus;
  final int checkOutStatus;
  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);

    final isPreview = options.path.endsWith('/preview');
    final status = isPreview ? previewStatus : checkOutStatus;

    if (status == 200) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': isPreview ? _quote : _closed},
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
            'code': 'not_early_departure',
            'message': 'Cette sortie n’intervient pas avant la fin prévue.',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

({EarlyCheckOutCubit cubit, _StubInterceptor spy}) _build({
  int previewStatus = 200,
  int checkOutStatus = 200,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _StubInterceptor(
    previewStatus: previewStatus,
    checkOutStatus: checkOutStatus,
  );
  dio.interceptors.add(spy);
  return (
    cubit: EarlyCheckOutCubit(ReservationRepository(dio, sessionRoleFixture())),
    spy: spy,
  );
}

void main() {
  group('EarlyCheckOutQuote', () {
    test('le remboursement suit le montant retouché, sans devenir négatif', () {
      final quote = EarlyCheckOutQuote.fromJson(_quote);

      expect(quote.refundFor(35000), 65000);
      expect(quote.refundFor(120000), 0);
    });
  });

  group('ReservationModel', () {
    test('lit la vente d’origine d’un séjour écourté', () {
      final reservation = ReservationModel.fromJson(_closed);

      expect(reservation.isEarlyCheckOut, isTrue);
      expect(reservation.refundedAmount, 60000);
      expect(reservation.plannedTotalAmount, 100000);
    });

    test('un séjour mené à terme n’a ni remboursement ni vente d’origine', () {
      final reservation = ReservationModel.fromJson(const {
        'id': 'book_2',
        'status': 'completed',
        'total_amount': 50000,
      });

      expect(reservation.isEarlyCheckOut, isFalse);
      expect(reservation.refundedAmount, 0);
    });
  });

  group('EarlyCheckOutCubit', () {
    test('chiffre sur la route de simulation, à l’heure choisie', () async {
      final built = _build();
      final at = DateTime.utc(2026, 9, 26, 9);

      await built.cubit.quote('book_1', at);

      final sent = built.spy.captured.single;
      expect(sent.method, 'GET');
      expect(sent.path, contains('/proprio/bookings/book_1/check-out/preview'));
      expect(sent.queryParameters['at'], at.toIso8601String());

      final state = built.cubit.state;
      expect(state, isA<EarlyCheckOutLoaded>());
      expect((state as EarlyCheckOutLoaded).quote.proposedAmount, 40000);
    });

    test('une heure refusée est une erreur sans chiffrage', () async {
      final built = _build(previewStatus: 422);

      await built.cubit.quote('book_1', DateTime.now());

      final state = built.cubit.state;
      expect(state, isA<EarlyCheckOutError>());
      expect((state as EarlyCheckOutError).quote, isNull);
    });

    test('clôture à l’heure du chiffrage et au montant retenu', () async {
      final built = _build();
      await built.cubit.quote('book_1', DateTime.utc(2026, 9, 26, 9));

      await built.cubit.submit('book_1', 35000);

      final sent = built.spy.captured.last;
      expect(sent.method, 'PATCH');
      expect(sent.path, contains('/proprio/bookings/book_1/check-out'));
      expect(sent.data, {
        'full_stay': false,
        'actual_check_out_at': '2026-09-26T09:00:00.000Z',
        'final_amount': 35000,
      });
      expect(built.cubit.state, isA<EarlyCheckOutSuccess>());
    });

    test('un échec à l’envoi garde le chiffrage pour réessayer', () async {
      final built = _build(checkOutStatus: 422);
      await built.cubit.quote('book_1', DateTime.utc(2026, 9, 26, 9));

      await built.cubit.submit('book_1', 35000);

      final state = built.cubit.state;
      expect(state, isA<EarlyCheckOutError>());
      expect((state as EarlyCheckOutError).quote, isNotNull);
    });

    test('sans chiffrage, rien n’est envoyé', () async {
      final built = _build();

      await built.cubit.submit('book_1', 35000);

      expect(built.spy.captured, isEmpty);
    });
  });
}
