import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/gerant/data/models/gerant_overview_model.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_repository.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_cubit.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_state.dart';
import 'package:resi_africa/features/home/presentation/widgets/home/stats_row_widget.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';
import 'package:resi_africa/features/stats/data/repositories/property_stats_repository.dart';

import '../../support/session_role_fixture.dart';

/// Cubit piloté par le test : évite le service locator et le réseau.
class _FakeStatsCubit extends Cubit<HomeStatsState> implements HomeStatsCubit {
  _FakeStatsCubit(super.initialState);

  @override
  Future<void> load() async {}
}

Widget _statsRow(HomeStatsState state) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<HomeStatsCubit>(
        create: (_) => _FakeStatsCubit(state),
        child: const StatsRowWidget(),
      ),
    ),
  );
}

/// Répond sans réseau, et retient chaque route appelée.
///
/// Les routes propriétaires répondent normalement : un test qui les verrait
/// appelées par un gérant doit échouer sur la route appelée, pas sur une panne.
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor({this.managerFails = false});

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
              'revenue_points': [
                {'month': 'Oct', 'value': 380000},
              ],
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

    if (options.path.contains('bookings/stats')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: const {
            'data': {'upcoming': 3, 'in_progress': 2, 'completed': 7},
          },
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

({HomeStatsCubit cubit, _CapturingInterceptor spy}) _build(
  String role, {
  bool managerFails = false,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor(managerFails: managerFails);
  dio.interceptors.add(spy);
  final session = sessionRoleFixture(role);

  return (
    cubit: HomeStatsCubit(
      PropertyStatsRepository(dio),
      ReservationRepository(dio, session),
      FinanceRepository(dio, session),
      GerantRepository(dio, session),
      () => session.value,
    ),
    spy: spy,
  );
}

void main() {
  group('GerantOverviewModel', () {
    test('lit le relevé du serveur', () {
      final model = GerantOverviewModel.fromJson(const {
        'bookings_count': 12,
        'gross_revenue': 380000,
        'expenses_total': 45000,
        'occupancy_rate': 0.42,
        'revenue_points': [
          {'month': 'Oct', 'value': 380000},
        ],
      });

      expect(model.bookingsCount, 12);
      expect(model.grossRevenue, 380000);
      expect(model.expensesTotal, 45000);
      expect(model.occupancyRate, 0.42);
      expect(model.revenuePoints, hasLength(1));
    });

    test('supporte un relevé vide', () {
      // Un gérant fraîchement affecté n'a encore aucune réservation.
      final model = GerantOverviewModel.fromJson(const {});

      expect(model.bookingsCount, 0);
      expect(model.grossRevenue, 0);
      expect(model.occupancyRate, 0);
      expect(model.revenuePoints, isEmpty);
    });

    test('le relevé du gérant ne porte aucun revenu net', () {
      // Le net déduirait des charges qui ne relèvent pas du gérant :
      // abonnement du propriétaire, charges communes, dépenses d'autres
      // logements. Sur un périmètre partiel, ce n'est pas une marge partielle
      // mais un chiffre faux.
      final model = GerantOverviewModel.fromJson(const {
        'gross_revenue': 380000,
        'expenses_total': 45000,
      });

      expect(model.toJson().containsKey('net_revenue'), isFalse);
      expect(model.toJson().containsKey('benefice_net'), isFalse);
    });

    test('le modèle ne porte que les cinq champs du relevé gérant', () {
      // Verrou de forme : le jour où un champ serait ajouté au modèle, ce test
      // tombe avant qu'un net reconstitué n'atteigne l'écran du gérant.
      final model = GerantOverviewModel.fromJson(const {
        'gross_revenue': 380000,
        'expenses_total': 45000,
      });

      expect(model.toJson().keys.toSet(), <String>{
        'bookings_count',
        'gross_revenue',
        'expenses_total',
        'occupancy_rate',
        'revenue_points',
      });
    });
  });

  group('HomeStatsCubit — accueil du gérant', () {
    test('un seul appel, sur la route gérant', () async {
      // Deux des trois relevés du propriétaire n'ont pas d'équivalent gérant :
      // les appeler rendrait deux 403 et des tirets à l'écran.
      final built = _build('gerant');

      await built.cubit.load();

      expect(built.spy.captured, hasLength(1));
      expect(
        built.spy.captured.single.path,
        contains('/gerant/finance/overview'),
      );
    });

    test('la rangée porte ses trois chiffres du mois', () async {
      final built = _build('gerant');

      await built.cubit.load();

      final state = built.cubit.state;
      expect(state, isA<HomeStatsManagerLoaded>());

      final loaded = state as HomeStatsManagerLoaded;
      expect(loaded.bookingsCount, 12);
      expect(loaded.grossRevenue, 380000);
      expect(loaded.occupancyRate, 0.42);
    });

    test('l’état du gérant ne porte aucun bénéfice net', () async {
      // `HomeStatsLoaded` en porte un, que `StatsRowWidget` affiche. Un état
      // distinct est la garantie qu'aucun oubli ne le lui fasse afficher.
      final built = _build('gerant');

      await built.cubit.load();

      expect(built.cubit.state, isNot(isA<HomeStatsLoaded>()));
    });

    test('une panne du relevé laisse la rangée sans valeur', () async {
      // Un tiret vaut mieux qu'un zéro, qui se lirait comme un fait.
      final built = _build('gerant', managerFails: true);

      await built.cubit.load();

      final state = built.cubit.state;
      expect(state, isA<HomeStatsManagerLoaded>());

      final loaded = state as HomeStatsManagerLoaded;
      expect(loaded.bookingsCount, isNull);
      expect(loaded.grossRevenue, isNull);
      expect(loaded.occupancyRate, isNull);
    });
  });

  group('HomeStatsCubit — accueil du propriétaire', () {
    test('garde ses trois relevés et son bénéfice net', () async {
      final built = _build('proprio');

      await built.cubit.load();

      expect(built.spy.captured, hasLength(3));

      final state = built.cubit.state;
      expect(state, isA<HomeStatsLoaded>());

      final loaded = state as HomeStatsLoaded;
      expect(loaded.propertiesCount, 20);
      expect(loaded.activeBookings, 5);
      expect(loaded.netIncome, 918840);
    });

    test('aucune route gérant n’est appelée pour un propriétaire', () async {
      final built = _build('proprio');

      await built.cubit.load();

      expect(
        built.spy.captured.any((r) => r.path.contains('/gerant/')),
        isFalse,
      );
    });
  });

  group('StatsRowWidget — rangée du gérant', () {
    testWidgets('montre ses trois chiffres du mois', (tester) async {
      await tester.pumpWidget(
        _statsRow(
          const HomeStatsManagerLoaded(
            bookingsCount: 12,
            grossRevenue: 380000,
            occupancyRate: 0.42,
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Réservations ce mois'), findsOneWidget);
      expect(find.text('Encaissé ce mois'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Occupation'), findsOneWidget);
    });

    testWidgets('aucun bénéfice net ne paraît à l’écran', (tester) async {
      // Le verrou qui compte : la tuile du bénéfice net du propriétaire ne
      // doit avoir aucun équivalent chez le gérant, et le brut ne doit pas s'y
      // retrouver sous ce libellé.
      await tester.pumpWidget(
        _statsRow(
          const HomeStatsManagerLoaded(
            bookingsCount: 12,
            grossRevenue: 380000,
            occupancyRate: 0.42,
          ),
        ),
      );

      expect(find.text('Bénéfice ce mois'), findsNothing);
      expect(find.text('Mes biens'), findsNothing);
    });

    testWidgets('un relevé en panne laisse des tirets', (tester) async {
      await tester.pumpWidget(_statsRow(const HomeStatsManagerLoaded()));

      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('la rangée du propriétaire reste inchangée', (tester) async {
      // Garde-fou de non-régression : la bifurcation ne doit rien retirer au
      // propriétaire, dont la tuile du bénéfice net reste sa troisième.
      await tester.pumpWidget(
        _statsRow(
          const HomeStatsLoaded(
            propertiesCount: 20,
            activeBookings: 5,
            netIncome: 918840,
          ),
        ),
      );

      expect(find.text('Mes biens'), findsOneWidget);
      expect(find.text('Réservations ce mois'), findsOneWidget);
      expect(find.text('Bénéfice ce mois'), findsOneWidget);
      expect(find.text('Occupation'), findsNothing);
    });
  });
}
