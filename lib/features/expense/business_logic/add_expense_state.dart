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
  const AddExpenseSuccess(this.expense, {this.queued = false});

  /// Dépense enregistrée par le serveur, `null` quand elle est en file.
  final ExpenseModel? expense;

  /// Saisie hors ligne, envoyée au retour du réseau.
  final bool queued;
}

final class AddExpenseFailure extends AddExpenseState {
  const AddExpenseFailure(this.message);

  final String message;
}
