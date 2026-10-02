import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/stats/business_logic/finance_cubit.dart';
import 'package:resi_africa/features/stats/data/models/finance/finance_period.dart';
import 'package:resi_africa/features/stats/data/models/finance/revenue_point_model.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';
import 'package:resi_africa/features/stats/presentation/widgets/finance/revenue_chart.dart';

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
          'data': {
            'summary': {
              'ca_brut': 0,
              'depenses': 0,
              'benefice_net': 0,
              'taux_occupation': 0,
              'reservations': 0,
              'moyen_sejour': 0,
            },
            'revenue_points': <Map<String, Object?>>[],
          },
        },
      ),
    );
  }
}

({FinanceCubit cubit, _CapturingInterceptor spy}) _build() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor();
  dio.interceptors.add(spy);
  return (
    cubit: FinanceCubit(FinanceRepository(dio, sessionRoleFixture())),
    spy: spy,
  );
}

void main() {
  final now = DateTime(2026, 10, 1, 15, 30);

  group('FinancePeriod — bornes', () {
    test('douze mois glissants jusqu’à aujourd’hui, heure retirée', () {
      final b = const FinancePeriod.rolling().bounds(now);

      expect(b.from, DateTime(2025, 10, 1));
      expect(b.to, DateTime(2026, 10, 1));
    });

    test('une année va du 1er janvier au 31 décembre', () {
      final b = const FinancePeriod.year(2025).bounds(now);

      expect(b.from, DateTime(2025, 1, 1));
      expect(b.to, DateTime(2025, 12, 31));
    });

    test('l’année en cours va jusqu’à son terme, pas jusqu’à aujourd’hui', () {
      expect(
        const FinancePeriod.year(2026).bounds(now).to,
        DateTime(2026, 12, 31),
      );
    });

    test('un mois s’arrête à son dernier jour', () {
      final b = const FinancePeriod.month(2026, 9).bounds(now);

      expect(b.from, DateTime(2026, 9, 1));
      expect(b.to, DateTime(2026, 9, 30));
    });

    test('février bissextile et décembre', () {
      expect(
        const FinancePeriod.month(2028, 2).bounds(now).to,
        DateTime(2028, 2, 29),
      );
      expect(
        const FinancePeriod.month(2026, 12).bounds(now).to,
        DateTime(2026, 12, 31),
      );
    });

    test('deux périodes identiques sont égales', () {
      expect(
        const FinancePeriod.month(2026, 9),
        const FinancePeriod.month(2026, 9),
      );
      expect(
        const FinancePeriod.year(2026) == const FinancePeriod.month(2026, 1),
        isFalse,
      );
      expect(const FinancePeriod.rolling().isRolling, isTrue);
    });
  });

  group('FinanceCubit — période', () {
    test(
      'un mois envoie son premier jour et son dernier jour en fin de journée',
      () async {
        // L'API traite `to` comme exclusive : envoyé à minuit, le 30 septembre
        // sortirait du relevé de septembre.
        final built = _build();

        await built.cubit.filterByPeriod(const FinancePeriod.month(2026, 9));

        final params = built.spy.captured.single.queryParameters;
        expect(params['from'], '2026-09-01');
        expect(params['to'], '2026-09-30 23:59:59');
        expect(built.cubit.from, DateTime(2026, 9, 1));
        expect(built.cubit.to, DateTime(2026, 9, 30));
      },
    );

    test('une année envoie le 1er janvier et le 31 décembre', () async {
      final built = _build();

      await built.cubit.filterByPeriod(const FinancePeriod.year(2025));

      final params = built.spy.captured.single.queryParameters;
      expect(params['from'], '2025-01-01');
      expect(params['to'], '2025-12-31 23:59:59');
    });

    test('la période survit à un rechargement', () async {
      // `load()` est rappelé sans argument à chaque retour de navigation.
      final built = _build();

      await built.cubit.filterByPeriod(const FinancePeriod.month(2026, 9));
      await built.cubit.load();

      expect(built.spy.captured, hasLength(2));
      expect(built.spy.captured.last.queryParameters['from'], '2026-09-01');
    });

    test('la période se combine au périmètre', () async {
      final built = _build();

      await built.cubit.filterByPeriod(const FinancePeriod.year(2025));
      await built.cubit.filterByResidence('resi-adja');

      final params = built.spy.captured.last.queryParameters;
      expect(params['residence_id'], 'resi-adja');
      expect(params['from'], '2025-01-01');
    });

    test('resélectionner la même période ne relance rien', () async {
      final built = _build();

      await built.cubit.filterByPeriod(const FinancePeriod.month(2026, 9));
      await built.cubit.filterByPeriod(const FinancePeriod.month(2026, 9));

      expect(built.spy.captured, hasLength(1));
    });
  });

  group('Graphique — année civile', () {
    test('les douze mois, à zéro faute de revenu', () {
      final window = buildYearWindow([
        const RevenuePointModel(month: 'Mar', value: 5000),
        const RevenuePointModel(month: 'Sep', value: 12000),
      ]);

      expect(window, hasLength(12));
      expect(window.first.month, 'Jan');
      expect(window[2].value, 5000);
      expect(window[8].value, 12000);
      expect(window.last.value, 0);
    });

    test('la courbe s’arrête au mois courant de l’année en cours', () {
      expect(yearLastDataIndex(2026, now), 9);
      expect(yearLastDataIndex(2025, now), 11);
    });
  });
}
