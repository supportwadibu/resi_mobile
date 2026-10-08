import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/expense/business_logic/expense_state.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';

void main() {
  group('ExpenseFilters — période', () {
    test('l’écran s’ouvre sur le mois en cours, sans filtre actif', () {
      final now = DateTime.now();
      final filters = ExpenseFilters.initial();

      expect(filters.periodKind, ExpensePeriodKind.month);
      expect(filters.from, DateTime(now.year, now.month));
      expect(filters.to, DateTime(now.year, now.month + 1, 0));
      expect(filters.isDefault, isTrue);
      expect(filters.activeCount, 0);
    });

    test('un mois va du 1er au dernier jour, février bissextile compris', () {
      final filters = const ExpenseFilters().withMonth(DateTime(2028, 2, 17));

      expect(filters.from, DateTime(2028, 2, 1));
      expect(filters.to, DateTime(2028, 2, 29));
      expect(filters.month, DateTime(2028, 2));
    });

    test('un autre mois compte comme un filtre', () {
      final filters = const ExpenseFilters().withMonth(DateTime(2020, 1));

      expect(filters.isDefault, isFalse);
      expect(filters.activeCount, 1);
    });

    test('changer de mois garde le bien et la catégorie', () {
      final filters = const ExpenseFilters(
        residenceId: 'resi-adja',
        category: ExpenseCategory.electricity,
      ).withMonth(DateTime(2026, 3));

      expect(filters.residenceId, 'resi-adja');
      expect(filters.category, ExpenseCategory.electricity);
    });

    test('des bornes posées par copyWith forment une plage libre', () {
      final filters = ExpenseFilters.initial().copyWith(
        from: DateTime(2026, 1, 5),
        to: DateTime(2026, 2, 10),
      );

      expect(filters.periodKind, ExpensePeriodKind.range);
      expect(filters.month, isNull);
      expect(filters.activeCount, 1);
    });

    test('tout l’historique n’envoie aucune borne', () {
      const filters = ExpenseFilters();

      expect(filters.periodKind, ExpensePeriodKind.all);
      expect(filters.from, isNull);
      expect(filters.to, isNull);
      expect(filters.isDefault, isFalse);
    });
  });
}
