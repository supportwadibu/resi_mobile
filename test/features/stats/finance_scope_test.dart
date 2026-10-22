import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/features/expense/business_logic/expense_state.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/features/stats/business_logic/finance_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/finance_state.dart';
import 'package:resi_africa/features/stats/data/models/finance/finance_scope.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';

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
              'ca_brut': 120000,
              'depenses': 35000,
              'benefice_net': 85000,
              'taux_occupation': 0.42,
              'reservations': 4,
              'moyen_sejour': 3.5,
            },
            'revenue_points': <Map<String, Object?>>[],
          },
        },
      ),
    );
  }
}

const _adja = FinanceScope.residence(id: 'resi-adja', name: 'Resi Adja');
const _studio = FinanceScope.property(id: 'studio-1', name: 'Studio 1');

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
  group('FinanceCubit — périmètre', () {
    test('sans filtre, ni residence_id ni property_id ne partent', () async {
      final built = _build();

      await built.cubit.load();

      final sent = built.spy.captured.single;
      expect(sent.queryParameters.containsKey('residence_id'), isFalse);
      expect(sent.queryParameters.containsKey('property_id'), isFalse);
      expect(built.cubit.scope.isPortfolio, isTrue);
      expect(built.cubit.state, isA<FinanceLoaded>());
    });

    test('filtrer sur une résidence envoie le residence_id seul', () async {
      final built = _build();

      await built.cubit.filterByScope(_adja);

      final params = built.spy.captured.single.queryParameters;
      expect(params['residence_id'], 'resi-adja');
      expect(params.containsKey('property_id'), isFalse);
      expect(built.cubit.scope.residenceId, 'resi-adja');
    });

    test('filtrer sur un logement envoie le property_id seul', () async {
      // Résidence et logement sont exclusifs : envoyer les deux laisserait le
      // serveur arbitrer entre deux périmètres que l'écran n'a pas combinés.
      final built = _build();

      await built.cubit.filterByScope(_studio);

      final params = built.spy.captured.single.queryParameters;
      expect(params['property_id'], 'studio-1');
      expect(params.containsKey('residence_id'), isFalse);
      expect(built.cubit.scope.propertyId, 'studio-1');
    });

    test('passer d’une résidence à l’un de ses logements', () async {
      final built = _build();

      await built.cubit.filterByScope(_adja);
      await built.cubit.filterByScope(_studio);

      expect(built.spy.captured, hasLength(2));
      final params = built.spy.captured.last.queryParameters;
      expect(params['property_id'], 'studio-1');
      expect(params.containsKey('residence_id'), isFalse);
    });

    test('le périmètre survit à un rechargement', () async {
      // L'écran appelle `load()` sans argument à chaque retour de navigation :
      // un filtre porté par le widget serait perdu au premier aller-retour vers
      // la saisie d'une dépense.
      final built = _build();

      await built.cubit.filterByScope(_studio);
      await built.cubit.load();

      expect(built.spy.captured, hasLength(2));
      expect(
        built.spy.captured.last.queryParameters['property_id'],
        'studio-1',
      );
    });

    test('revenir à « tout le parc » retire le filtre', () async {
      final built = _build();

      await built.cubit.filterByScope(_studio);
      await built.cubit.filterByScope(const FinanceScope.portfolio());

      expect(built.cubit.scope.isPortfolio, isTrue);
      final params = built.spy.captured.last.queryParameters;
      expect(params.containsKey('residence_id'), isFalse);
      expect(params.containsKey('property_id'), isFalse);
    });

    test('resélectionner le même périmètre ne relance rien', () async {
      // `load()` émet `FinanceLoading` : recharger pour rien ferait clignoter
      // l'écran sur un appui sans effet.
      final built = _build();

      await built.cubit.filterByScope(_adja);
      await built.cubit.filterByScope(_adja);

      expect(built.spy.captured, hasLength(1));
    });

    test('les bornes de période accompagnent le filtre', () async {
      // Le taux d'occupation a besoin d'une fenêtre pour avoir un dénominateur.
      final built = _build();

      await built.cubit.filterByScope(_studio);

      final params = built.spy.captured.single.queryParameters;
      expect(params.containsKey('from'), isTrue);
      expect(params.containsKey('to'), isTrue);
    });
  });

  group('FinanceScope', () {
    test('l’égalité ignore le libellé', () {
      // Un logement renommé entre deux ouvertures de la feuille reste le même
      // périmètre : le recharger ne changerait aucun chiffre.
      expect(
        const FinanceScope.property(id: 'studio-1', name: 'Studio 1'),
        const FinanceScope.property(id: 'studio-1', name: 'Studio A'),
      );
    });

    test('une résidence et un logement de même id restent distincts', () {
      expect(
        const FinanceScope.property(id: 'x', name: 'X'),
        isNot(const FinanceScope.residence(id: 'x', name: 'X')),
      );
    });

    test('tout le parc n’a pas de libellé', () {
      expect(const FinanceScope.portfolio().label, isNull);
    });
  });

  group('ExpenseFilters — périmètre résidence', () {
    test('le filtre résidence compte comme un filtre actif', () {
      const filters = ExpenseFilters(residenceId: 'resi-adja');

      expect(filters.isEmpty, isFalse);
      expect(filters.activeCount, 1);
    });

    test('copyWith pose le périmètre', () {
      final filters = const ExpenseFilters().copyWith(residenceId: 'resi-adja');

      expect(filters.residenceId, 'resi-adja');
    });

    test('clearResidence lève le périmètre sans toucher au reste', () {
      // C'est ce que fait le retour à « tout le parc » : `copyWith(residenceId:
      // null)` ne suffirait pas, `null` signifiant « ne pas toucher ».
      final filters = const ExpenseFilters(
        residenceId: 'resi-adja',
        category: ExpenseCategory.electricity,
      ).copyWith(clearResidence: true);

      expect(filters.residenceId, isNull);
      expect(filters.category, ExpenseCategory.electricity);
    });

    test('un filtre vide reste vide', () {
      expect(const ExpenseFilters().isEmpty, isTrue);
      expect(const ExpenseFilters().activeCount, 0);
    });
  });
}
