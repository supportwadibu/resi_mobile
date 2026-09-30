import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: const {
          'data': {
            'id': 'b1',
            'property_id': 'p2',
            'status': 'confirmed',
            'source': 'offline',
            'start_date': '2026-10-10T12:00:00.000Z',
            'end_date': '2026-10-13T12:00:00.000Z',
            'days_count': 3,
            'total_amount': 50000,
          },
        },
      ),
    );
  }
}

void main() {
  late _CapturingInterceptor interceptor;
  late ReservationRepository repository;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _CapturingInterceptor();
    dio.interceptors.add(interceptor);
    repository = ReservationRepository(dio, sessionRoleFixture());
  });

  Future<void> send({double? agreed, String message = ''}) => repository.update(
    'b1',
    propertyId: 'p2',
    stayType: StayType.fullDay,
    checkInAt: DateTime.utc(2026, 10, 10, 12),
    checkOutAt: DateTime.utc(2026, 10, 13, 12),
    agreedAmount: agreed,
    depositAmount: 10000,
    message: message,
  );

  test('envoie la réservation entière en PUT sur sa ressource', () async {
    await send(agreed: 50000, message: 'Côté jardin');

    final request = interceptor.captured!;
    expect(request.method, 'PUT');
    expect(request.path, endsWith('/proprio/bookings/b1'));
    expect(request.data, {
      'property_id': 'p2',
      'stay_type': 'full_day',
      'check_in_at': '2026-10-10T12:00:00.000Z',
      'check_out_at': '2026-10-13T12:00:00.000Z',
      'received_amount': 50000.0,
      'deposit_amount': 10000.0,
      'message': 'Côté jardin',
    });
  });

  test('sans prix convenu, la clé est absente : le tarif s’applique', () async {
    await send();

    final data = interceptor.captured!.data as Map<String, dynamic>;
    expect(data.containsKey('received_amount'), isFalse);
  });

  test('un message vidé part à null pour être effacé', () async {
    await send(message: '   ');

    final data = interceptor.captured!.data as Map<String, dynamic>;
    expect(data['message'], isNull);
  });

  test('rend la réservation telle que le serveur l’a réécrite', () async {
    final updated = await repository.update(
      'b1',
      propertyId: 'p2',
      stayType: StayType.fullDay,
      checkInAt: DateTime.utc(2026, 10, 10, 12),
      checkOutAt: DateTime.utc(2026, 10, 13, 12),
      depositAmount: 0,
      message: '',
    );

    expect(updated.propertyId, 'p2');
    expect(updated.totalAmount, 50000);
  });
}
