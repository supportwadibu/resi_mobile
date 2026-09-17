import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_state.dart';
import 'package:resi_africa/features/stats/data/models/property_stats_model.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';
import 'package:resi_africa/features/stats/data/repositories/property_stats_repository.dart';

/// Répond aux deux relevés sans réseau, en distinguant la route appelée.
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor({this.financeFails = false});

  /// Simule une panne du seul relevé financier : l'état du parc, lui, répond.
  final bool financeFails;

  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);

    if (options.path.contains('properties/stats')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: const {
            'data': {
              'total': 20,
              'published': 18,
              'rented': 14,
              'draft': 2,
              'total_views': 320,
            },
          },
        ),
      );
      return;
    }

    if (financeFails) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
          type: DioExceptionType.badResponse,
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
            'summary': {
              'ca_brut': 1260840,
              'depenses': 342000,
              'benefice_net': 918840,
              'taux_occupation': 0.78,
              'reservations': 9,
              'moyen_sejour': 4.2,
            },
            'revenue_points': <Map<String, Object?>>[],
          },
        },
      ),
    );
  }
}

({DashboardCubit cubit, _CapturingInterceptor spy}) _build({
  bool financeFails = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor(financeFails: financeFails);
  dio.interceptors.add(spy);
  return (
    cubit: DashboardCubit(
      FinanceRepository(dio, sessionRoleFixture()),
      PropertyStatsRepository(dio),
    ),
    spy: spy,
  );
}

void main() {
  group('DashboardCubit — chargement', () {
    test('compose les deux relevés en un seul état', () async {
      final built = _build();

      await built.cubit.load();

      final state = built.cubit.state;
      expect(state, isA<DashboardLoaded>());

      final loaded = state as DashboardLoaded;
      expect(loaded.overview.summary.caBrut, 1260840);
      expect(loaded.overview.summary.depenses, 342000);
      expect(loaded.parc.rented, 14);
      expect(built.spy.captured, hasLength(2));
    });

    test('sans bornes, la période est le mois courant', () async {
      final built = _build();

      await built.cubit.load();

      final now = DateTime.now();
      final sent = built.spy.captured.firstWhere(
        (r) => r.path.contains('finance/overview'),
      );
      final from = sent.queryParameters['from'] as String;

      expect(from, '${now.year}-${now.month.toString().padLeft(2, '0')}-01');
    });

    test('la période choisie accompagne le relevé financier', () async {
      final built = _build();

      await built.cubit.filterByPeriod(
        DateTime(2026, 3, 5),
        DateTime(2026, 4, 20),
      );

      final sent = built.spy.captured.firstWhere(
        (r) => r.path.contains('finance/overview'),
      );
      expect(sent.queryParameters['from'], '2026-03-05');
      expect(sent.queryParameters['to'], '2026-04-20');
    });

    test('la période survit à un rechargement sans bornes', () async {
      final built = _build();

      await built.cubit.filterByPeriod(
        DateTime(2026, 3, 5),
        DateTime(2026, 4, 20),
      );
      await built.cubit.load();

      final sent = built.spy.captured.lastWhere(
        (r) => r.path.contains('finance/overview'),
      );
      expect(sent.queryParameters['from'], '2026-03-05');
    });

    test('une panne d’un seul relevé fait échouer l’ensemble', () async {
      final built = _build(financeFails: true);

      await built.cubit.load();

      expect(built.cubit.state, isA<DashboardError>());
    });
  });

  group('PropertyStatsModel — unités disponibles', () {
    test('les disponibles sont les publiées non louées', () {
      const parc = PropertyStatsModel(
        total: 20,
        published: 18,
        rented: 14,
        draft: 2,
        totalViews: 0,
      );

      expect(parc.available, 4);
    });

    test('un parc entièrement loué n’a aucune disponibilité', () {
      const parc = PropertyStatsModel(
        total: 5,
        published: 5,
        rented: 5,
        draft: 0,
        totalViews: 0,
      );

      expect(parc.available, 0);
    });

    test('un décompte incohérent ne descend pas sous zéro', () {
      // `rented` dépasse `published` si une unité est dépubliée pendant un
      // séjour en cours : le compteur ne doit pas afficher un négatif.
      const parc = PropertyStatsModel(
        total: 5,
        published: 2,
        rented: 4,
        draft: 0,
        totalViews: 0,
      );

      expect(parc.available, 0);
    });

    test('les champs absents de l’historique valent zéro', () {
      final parc = PropertyStatsModel.fromJson(const {'total': 3});

      expect(parc.total, 3);
      expect(parc.published, 0);
      expect(parc.rented, 0);
    });
  });
}
