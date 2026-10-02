import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/occupancy_card.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_repository.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_state.dart';
import 'package:resi_africa/features/stats/data/models/property_stats_model.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';
import 'package:resi_africa/features/stats/data/repositories/property_stats_repository.dart';

/// Répond aux relevés sans réseau, en distinguant la route appelée.
///
/// Les routes propriétaires répondent normalement, y compris pour un gérant :
/// un test qui les verrait appelées par lui doit échouer sur la route appelée,
/// et non sur une panne simulée.
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor({this.financeFails = false, this.managerFails = false});

  /// Simule une panne du seul relevé financier : l'état du parc, lui, répond.
  final bool financeFails;

  /// Simule une panne du seul relevé gérant.
  final bool managerFails;

  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);

    if (options.path.contains('/gerant/finance/overview')) {
      if (managerFails) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 500),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }

      // Le `ManagerOverviewDto` du serveur : cinq champs, sans clé `summary`.
      // C'est cette forme qui, lue par `FinanceOverviewModel`, rendait des
      // zéros silencieux.
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: const {
            'data': {
              'bookings_count': 12,
              'gross_revenue': 380000,
              'expenses_total': 45000,
              'occupancy_rate': 0.42,
              'revenue_points': <Map<String, Object?>>[],
            },
          },
        ),
      );
      return;
    }

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
  String role = 'proprio',
  bool financeFails = false,
  bool managerFails = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor(
    financeFails: financeFails,
    managerFails: managerFails,
  );
  dio.interceptors.add(spy);
  final session = sessionRoleFixture(role);

  return (
    cubit: DashboardCubit(
      FinanceRepository(dio, session),
      PropertyStatsRepository(dio),
      GerantRepository(dio, session),
      () => session.value,
    ),
    spy: spy,
  );
}

Widget _card(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

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
      // Dernier jour inclus : l'API traite `to` comme exclusive.
      expect(sent.queryParameters['to'], '2026-04-20 23:59:59');
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
      // Vrai du seul propriétaire, et voulu : ses deux relevés nourrissent la
      // même carte d'occupation, dont le taux et les compteurs d'unités se
      // lisent l'un par l'autre. Le gérant, lui, n'appelle pas ces routes —
      // sans quoi la panne serait systématique plutôt qu'accidentelle.
      final built = _build(financeFails: true);

      await built.cubit.load();

      expect(built.cubit.state, isA<DashboardError>());
    });

    test('aucune route gérant n’est appelée pour un propriétaire', () async {
      final built = _build();

      await built.cubit.load();

      expect(
        built.spy.captured.any((r) => r.path.contains('/gerant/')),
        isFalse,
      );
    });
  });

  group('DashboardCubit — onglet Stats du gérant', () {
    test('un seul appel, sur la route gérant', () async {
      // `/proprio/properties/stats` n'a pas d'équivalent gérant : l'appeler
      // rendait un 403 `forbidden_role`, et le `Future.wait` faisait échouer
      // tout l'onglet sur une erreur pleine page.
      final built = _build(role: 'gerant');

      await built.cubit.load();

      expect(built.spy.captured, hasLength(1));
      expect(
        built.spy.captured.single.path,
        contains('/gerant/finance/overview'),
      );
      expect(
        built.spy.captured.any((r) => r.path.contains('properties/stats')),
        isFalse,
      );
    });

    test('l’onglet porte ses chiffres réels', () async {
      final built = _build(role: 'gerant');

      await built.cubit.load();

      final state = built.cubit.state;
      expect(state, isA<DashboardManagerLoaded>());

      final loaded = state as DashboardManagerLoaded;
      expect(loaded.overview.bookingsCount, 12);
      expect(loaded.overview.grossRevenue, 380000);
      expect(loaded.overview.expensesTotal, 45000);
      expect(loaded.overview.occupancyRate, 0.42);
    });

    test('aucun zéro silencieux sur le relevé du gérant', () async {
      // Le défaut que ce test verrouille : `/gerant/finance/overview` rend un
      // `ManagerOverviewDto` sans clé `summary`, que `FinanceOverviewModel`
      // lisait entièrement à zéro sans lever la moindre erreur.
      final built = _build(role: 'gerant');

      await built.cubit.load();

      final loaded = built.cubit.state as DashboardManagerLoaded;
      expect(loaded.overview.grossRevenue, isNot(0));
      expect(loaded.overview.occupancyRate, isNot(0));
      expect(loaded.overview.bookingsCount, isNot(0));
    });

    test('l’état du gérant ne porte aucun bénéfice net', () async {
      // `DashboardLoaded` porte un `FinanceOverviewModel`, dont le
      // `summary.beneficeNet` se demande en un accès de champ. Un type
      // distinct est la garantie qu'aucun oubli ne le lui fasse afficher.
      final built = _build(role: 'gerant');

      await built.cubit.load();

      expect(built.cubit.state, isNot(isA<DashboardLoaded>()));
    });

    test('aucun état du propriétaire pendant le chargement', () async {
      // `load()` n'est pas attendu : on observe ce qui est émis pendant que le
      // relevé est en vol, c'est-à-dire ce que voit l'écran sur une connexion
      // lente.
      final built = _build(role: 'gerant');
      final seen = <DashboardState>[];
      final sub = built.cubit.stream.listen(seen.add);

      final pending = built.cubit.load();
      await Future<void>.delayed(Duration.zero);
      await pending;
      // Le flux d'un cubit livre de façon asynchrone : sans ce tour de boucle,
      // la dernière émission n'aurait pas atteint l'abonné avant l'annulation.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen.whereType<DashboardLoaded>(), isEmpty);
      expect(seen.last, isA<DashboardManagerLoaded>());
    });

    test('la période choisie accompagne le relevé gérant', () async {
      final built = _build(role: 'gerant');

      await built.cubit.filterByPeriod(
        DateTime(2026, 3, 5),
        DateTime(2026, 4, 20),
      );

      final sent = built.spy.captured.single;
      expect(sent.queryParameters['from'], '2026-03-05');
      expect(sent.queryParameters['to'], '2026-04-20');
    });

    test('une panne du relevé reste une erreur affichée', () async {
      // Une panne réseau se signale ; elle ne se replie pas sur des zéros.
      final built = _build(role: 'gerant', managerFails: true);

      await built.cubit.load();

      expect(built.cubit.state, isA<DashboardError>());
    });
  });

  group('OccupancyCard — carte du gérant', () {
    testWidgets('sans compteurs, aucune unité n’est inventée', (tester) async {
      // Ils viennent de `/proprio/properties/stats`, fermée à son rôle. Deux
      // zéros s'y liraient comme un parc vide.
      await tester.pumpWidget(_card(const OccupancyCard(occupancyRate: 0.42)));

      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Unités louées'), findsNothing);
      expect(find.text('Disponibles'), findsNothing);
    });

    testWidgets('la carte du propriétaire garde ses compteurs', (tester) async {
      // Non-régression : la bifurcation ne doit rien retirer au propriétaire.
      await tester.pumpWidget(
        _card(
          const OccupancyCard(occupancyRate: 0.78, rented: 14, available: 4),
        ),
      );

      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Unités louées'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Disponibles'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
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
