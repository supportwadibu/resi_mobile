import '../data/models/expense_model.dart';

/// États de l'enregistrement d'une dépense.
sealed class AddExpenseState {
  const AddExpenseState();
}

final class AddExpenseIdle extends AddExpenseState {
  const AddExpenseIdle();
}

final class AddExpenseSubmitting extends AddExpenseState {
  const AddExpenseSubmitting();
}

final class AddExpenseSuccess extends AddExpenseState {
  const AddExpenseSuccess(this.expense);

  final ExpenseModel expense;
}

final class AddExpenseFailure extends AddExpenseState {
  const AddExpenseFailure(this.message);

  final String message;
}
