import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/features/expense/data/repositories/expense_repository.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor(this.body);

  /// Corps que le faux serveur renvoie, selon la route interrogée.
  final Object? Function(RequestOptions options) body;

  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: body(options),
      ),
    );
  }
}

CreateExpensePayload _payload({
  ExpenseCategory category = ExpenseCategory.electricity,
  double amount = 25000,
  String? note,
}) {
  return CreateExpensePayload(
    propertyId: 'prop_1',
    category: category,
    amount: amount,
    spentAt: DateTime(2026, 3, 14),
    note: note,
  );
}

const _expenseJson = {
  'id': 'exp_1',
  'owner_id': 'own_1',
  'property_id': 'prop_1',
  'category': 'electricity',
  'amount': 25000,
  'spent_at': '2026-03-14T00:00:00.000Z',
  'note': 'Facture de mars',
  'property': {'id': 'prop_1', 'title': 'Villa Belvédère', 'city': 'Abidjan'},
};

void main() {
  late Dio dio;
  late _CapturingInterceptor interceptor;
  late ExpenseRepository repository;

  void arrange(Object? Function(RequestOptions options) body) {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _CapturingInterceptor(body);
    dio.interceptors.add(interceptor);
    repository = ExpenseRepository(dio);
  }

  setUp(() {
    arrange((_) => const {'data': [_expenseJson]});
  });

  group('Contrat de création', () {
    setUp(() => arrange((_) => const {'data': _expenseJson}));

    test('la charge utile porte les champs exigés par l’API', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body['property_id'], 'prop_1');
      expect(body['category'], 'electricity');
      expect(body['amount'], 25000);
    });

    test('la date part en date simple, pas en instant ISO', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      // `vine.date()` attend `YYYY-MM-DD`.
      expect(body['spent_at'], '2026-03-14');
    });

    test('une note vide est omise plutôt qu’envoyée à blanc', () async {
      await repository.create(_payload(note: '   '));
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body.containsKey('note'), isFalse);
    });

    test('une note renseignée est transmise sans espaces superflus', () async {
      await repository.create(_payload(note: '  Facture de mars  '));
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body['note'], 'Facture de mars');
    });

    test('cible la route propriétaire', () async {
      await repository.create(_payload());

      expect(interceptor.captured!.path, '/api/v1/proprio/expenses');
    });
  });

  group('Lecture de la réponse', () {
    test('reconstruit la dépense et le bien joint', () async {
      final page = await repository.getExpensePage();

      expect(page.items, hasLength(1));
      final expense = page.items.first;
      expect(expense.id, 'exp_1');
      expect(expense.category, ExpenseCategory.electricity);
      expect(expense.amount, 25000);
      expect(expense.spentAt.year, 2026);
      expect(expense.property?.title, 'Villa Belvédère');
    });

    test('une catégorie inconnue retombe sur « Autre »', () async {
      arrange(
        (_) => const {
          'data': [
            {'id': 'exp_2', 'category': 'crypto_mining', 'amount': 100},
          ],
        },
      );

      final page = await repository.getExpensePage();

      // Un code non reconnu ne doit pas faire échouer la lecture de la liste.
      expect(page.items.first.category, ExpenseCategory.other);
    });

    test('un bien supprimé laisse la dépense sans rattachement', () async {
      arrange(
        (_) => const {
          'data': [
            {'id': 'exp_3', 'category': 'water', 'amount': 8000},
          ],
        },
      );

      final page = await repository.getExpensePage();

      expect(page.items.first.property, isNull);
    });
  });

  group('Filtres de liste', () {
    test('sans filtre, seule la pagination est envoyée', () async {
      await repository.getExpensePage();

      expect(interceptor.captured!.queryParameters, {'page': 1, 'per_page': 20});
    });

    test('les filtres fournis partent en paramètres', () async {
      await repository.getExpensePage(
        propertyId: 'prop_9',
        category: ExpenseCategory.maintenance,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );

      expect(interceptor.captured!.queryParameters, {
        'property_id': 'prop_9',
        'category': 'maintenance',
        'from': '2026-01-01',
        'to': '2026-01-31',
        'page': 1,
        'per_page': 20,
      });
    });

    test('la page demandée est transmise', () async {
      await repository.getExpensePage(page: 3);

      expect(interceptor.captured!.queryParameters['page'], 3);
    });
  });

  group('Pagination', () {
    test('`meta` renseigne la page courante et la dernière', () async {
      arrange(
        (_) => const {
          'data': [_expenseJson],
          'meta': {'total': 45, 'perPage': 20, 'currentPage': 2, 'lastPage': 3},
        },
      );

      final page = await repository.getExpensePage(page: 2);

      expect(page.currentPage, 2);
      expect(page.lastPage, 3);
      expect(page.hasMore, isTrue);
    });

    test('sur la dernière page, il ne reste rien à charger', () async {
      arrange(
        (_) => const {
          'data': [_expenseJson],
          'meta': {'total': 3, 'perPage': 20, 'currentPage': 1, 'lastPage': 1},
        },
      );

      final page = await repository.getExpensePage();

      expect(page.hasMore, isFalse);
    });

    test('sans `meta`, une page unique est supposée', () async {
      arrange((_) => const {'data': [_expenseJson]});

      final page = await repository.getExpensePage();

      // Supposer « il en reste » ferait boucler l'export indéfiniment.
      expect(page.hasMore, isFalse);
    });

    test('`getAllExpenses` parcourt toutes les pages', () async {
      // Le faux serveur pagine : deux pages d'une dépense chacune.
      arrange((options) {
        final page = options.queryParameters['page'] as int;
        return {
          'data': [
            {..._expenseJson, 'id': 'exp_page_$page'},
          ],
          'meta': {'total': 2, 'perPage': 1, 'currentPage': page, 'lastPage': 2},
        };
      });

      final all = await repository.getAllExpenses();

      expect(all.map((e) => e.id), ['exp_page_1', 'exp_page_2']);
    });
  });

  group('Contrat de modification', () {
    setUp(() => arrange((_) => const {'data': _expenseJson}));

    test('seules les clés fournies partent', () async {
      await repository.update(
        'exp_1',
        const UpdateExpensePayload(amount: 30000),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body, {'amount': 30000});
      expect(interceptor.captured!.method, 'PATCH');
    });

    test('une note effacée part explicitement à `null`', () async {
      await repository.update(
        'exp_1',
        const UpdateExpensePayload(clearNote: true),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;

      // `null` explicite : omettre la clé laisserait la note en place.
      expect(body.containsKey('note'), isTrue);
      expect(body['note'], isNull);
    });

    test('la date part en date simple', () async {
      await repository.update(
        'exp_1',
        UpdateExpensePayload(spentAt: DateTime(2026, 7, 9)),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body['spent_at'], '2026-07-09');
    });

    test('cible la dépense visée', () async {
      await repository.update(
        'exp_1',
        const UpdateExpensePayload(amount: 1),
      );

      expect(interceptor.captured!.path, '/api/v1/proprio/expenses/exp_1');
    });
  });

  group('Total et ventilation', () {
    setUp(() {
      arrange(
        (_) => const {
          'data': {
            'total': 40000,
            'count': 3,
            'by_category': [
              {
                'category': 'electricity',
                'amount': 25000,
                'count': 2,
                'share_percent': 63,
              },
              {
                'category': 'water',
                'amount': 15000,
                'count': 1,
                'share_percent': 37,
              },
            ],
          },
        },
      );
    });

    test('reprend le total du serveur, sans le recalculer', () async {
      final summary = await repository.getSummary();

      // Le total porte sur l'ensemble des dépenses ; le recalculer sur la page
      // courante donnerait un montant tronqué.
      expect(summary.total, 40000);
      expect(summary.count, 3);
    });

    test('la ventilation conserve l’ordre décroissant du serveur', () async {
      final summary = await repository.getSummary();

      expect(
        summary.byCategory.map((b) => b.category),
        [ExpenseCategory.electricity, ExpenseCategory.water],
      );
      expect(summary.byCategory.first.sharePercent, 63);
    });

    test('cible la route de synthèse', () async {
      await repository.getSummary();

      expect(interceptor.captured!.path, '/api/v1/proprio/expenses/summary');
    });
  });

  group('Suppression', () {
    setUp(() => arrange((_) => null));

    test('cible la dépense visée', () async {
      await repository.delete('exp_1');

      expect(interceptor.captured!.path, '/api/v1/proprio/expenses/exp_1');
      expect(interceptor.captured!.method, 'DELETE');
    });
  });

  group('Correspondance des catégories avec le serveur', () {
    test('les codes couvrent exactement EXPENSE_CATEGORIES', () {
      // Doit rester aligné sur `api_resi/app/models/expense.ts`.
      expect(ExpenseCategory.values.map((c) => c.code).toSet(), {
        'electricity',
        'water',
        'internet',
        'tv',
        'cleaning',
        'maintenance',
        'taxes',
        'other',
      });
    });
  });
}
