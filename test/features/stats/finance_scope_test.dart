import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/expense/business_logic/expense_state.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/features/stats/business_logic/finance_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/finance_state.dart';
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

({FinanceCubit cubit, _CapturingInterceptor spy}) _build() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor();
  dio.interceptors.add(spy);
  return (cubit: FinanceCubit(FinanceRepository(dio)), spy: spy);
}

void main() {
  group('FinanceCubit — périmètre', () {
    test('sans filtre, aucun residence_id n’est envoyé', () async {
      final built = _build();

      await built.cubit.load();

      final sent = built.spy.captured.single;
      expect(sent.queryParameters.containsKey('residence_id'), isFalse);
      expect(built.cubit.state, isA<FinanceLoaded>());
    });

    test('filtrer envoie le residence_id', () async {
      final built = _build();

      await built.cubit.filterByResidence('resi-adja');

      expect(built.spy.captured.single.queryParameters['residence_id'], 'resi-adja');
      expect(built.cubit.residenceId, 'resi-adja');
    });

    test('le périmètre survit à un rechargement', () async {
      // L'écran appelle `load()` sans argument à chaque retour de navigation :
      // un filtre porté par le widget serait perdu au premier aller-retour vers
      // la saisie d'une dépense.
      final built = _build();

      await built.cubit.filterByResidence('resi-adja');
      await built.cubit.load();

      expect(built.spy.captured, hasLength(2));
      expect(built.spy.captured.last.queryParameters['residence_id'], 'resi-adja');
    });

    test('revenir à « tout le parc » retire le filtre', () async {
      final built = _build();

      await built.cubit.filterByResidence('resi-adja');
      await built.cubit.filterByResidence(null);

      expect(built.cubit.residenceId, isNull);
      expect(
        built.spy.captured.last.queryParameters.containsKey('residence_id'),
        isFalse,
      );
    });

    test('resélectionner le même périmètre ne relance rien', () async {
      // `load()` émet `FinanceLoading` : recharger pour rien ferait clignoter
      // l'écran sur un appui sans effet.
      final built = _build();

      await built.cubit.filterByResidence('resi-adja');
      await built.cubit.filterByResidence('resi-adja');

      expect(built.spy.captured, hasLength(1));
    });

    test('les bornes de période accompagnent le filtre', () async {
      // Le taux d'occupation a besoin d'une fenêtre pour avoir un dénominateur.
      final built = _build();

      await built.cubit.filterByResidence('resi-adja');

      final params = built.spy.captured.single.queryParameters;
      expect(params.containsKey('from'), isTrue);
      expect(params.containsKey('to'), isTrue);
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
