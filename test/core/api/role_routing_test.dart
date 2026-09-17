import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import 'package:resi_africa/features/expense/data/repositories/expense_repository.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';
import '../../support/session_role_fixture.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: const {
          'data': <Object>[],
          'meta': {'total': 0, 'current_page': 1, 'last_page': 1},
        },
      ),
    );
  }
}

({Dio dio, _CapturingInterceptor spy}) _client() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor();
  dio.interceptors.add(spy);
  return (dio: dio, spy: spy);
}

void main() {
  group('préfixe appelé selon le rôle', () {
    test('le gérant poste sur son propre préfixe', () async {
      final client = _client();
      final repo = ReservationRepository(
        client.dio,
        sessionRoleFixture('gerant'),
      );

      await repo.getReservationPage();

      expect(client.spy.captured.single.path, '/api/v1/gerant/bookings');
    });

    test('le propriétaire garde le sien', () async {
      // Aucune régression : la navigation du propriétaire doit produire
      // exactement les URLs d'avant l'ajout du rôle gérant.
      final client = _client();
      final repo = ReservationRepository(
        client.dio,
        sessionRoleFixture('proprio'),
      );

      await repo.getReservationPage();

      expect(client.spy.captured.single.path, '/api/v1/proprio/bookings');
    });

    test('le carnet clients suit le rôle', () async {
      final client = _client();
      final repo = ClientsRepository(client.dio, sessionRoleFixture('gerant'));

      await repo.getClientPage();

      expect(client.spy.captured.single.path, '/api/v1/gerant/clients');
    });

    test('les dépenses suivent le rôle', () async {
      final client = _client();
      final repo = ExpenseRepository(client.dio, sessionRoleFixture('gerant'));

      await repo.getExpensePage();

      expect(client.spy.captured.single.path, '/api/v1/gerant/expenses');
    });
  });
}
