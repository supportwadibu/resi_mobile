import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import 'add_expense_state.dart';

/// Pilote l'enregistrement d'une dépense, création comme modification.
///
/// Séparé de `ExpenseCubit` : lister et écrire ont des cycles de vie distincts,
/// et un échec d'écriture ne doit pas vider la liste affichée.
class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit(this._repository) : super(const AddExpenseIdle());

  final ExpenseRepository _repository;

  /// Enregistre une dépense.
  ///
  /// Exactement un de [propertyId] et [residenceId] doit être fourni : une
  /// charge de logement, ou une charge commune du lieu. Le serveur refuse en
  /// 422 les deux autres cas.
  Future<void> submit({
    required ExpenseCategory category,
    required double amount,
    required DateTime spentAt,
    String? propertyId,
    String? residenceId,
    String? note,
  }) async {
    emit(const AddExpenseSubmitting());

    try {
      final expense = await _repository.create(
        residenceId != null
            ? CreateExpensePayload.forResidence(
                residenceId: residenceId,
                category: category,
                amount: amount,
                spentAt: spentAt,
                note: note,
              )
            : CreateExpensePayload.forProperty(
                propertyId: propertyId ?? '',
                category: category,
                amount: amount,
                spentAt: spentAt,
                note: note,
              ),
      );

      if (!isClosed) emit(AddExpenseSuccess(expense));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AddExpenseFailure(f.userMessage));
    }
  }

  /// Modifie une dépense existante.
  ///
  /// Le patch est calculé par rapport à [original] : n'envoyer que ce qui a
  /// bougé évite d'écraser un champ qu'un autre appareil vient de changer.
  Future<void> update({
    required ExpenseModel original,
    required ExpenseCategory category,
    required double amount,
    required DateTime spentAt,
    String? propertyId,
    String? residenceId,
    String? note,
  }) async {
    final trimmedNote = note?.trim() ?? '';
    final previousNote = original.note?.trim() ?? '';

    final changedCategory = category == original.category ? null : category;
    final changedAmount = amount == original.amount ? null : amount;
    final changedSpentAt = _sameDay(spentAt, original.spentAt) ? null : spentAt;
    final changedNote = trimmedNote == previousNote || trimmedNote.isEmpty
        ? null
        : trimmedNote;
    // Une note effacée doit être transmise explicitement : `null` seul
    // signifierait « inchangée ».
    final clearNote = previousNote.isNotEmpty && trimmedNote.isEmpty;

    // La bascule de cible passe par un constructeur dédié, qui envoie les deux
    // clés ensemble : le serveur valide le rattachement résultant, et poser la
    // nouvelle cible sans effacer l’ancienne les ferait coexister.
    final movesToResidence =
        residenceId != null && residenceId != original.residenceId;
    final movesToProperty =
        propertyId != null && propertyId != original.propertyId;

    final payload = movesToResidence
        ? UpdateExpensePayload.toResidence(
            residenceId,
            category: changedCategory,
            amount: changedAmount,
            spentAt: changedSpentAt,
            note: changedNote,
            clearNote: clearNote,
          )
        : movesToProperty
            ? UpdateExpensePayload.toProperty(
                propertyId,
                category: changedCategory,
                amount: changedAmount,
                spentAt: changedSpentAt,
                note: changedNote,
                clearNote: clearNote,
              )
            : UpdateExpensePayload(
                category: changedCategory,
                amount: changedAmount,
                spentAt: changedSpentAt,
                note: changedNote,
                clearNote: clearNote,
              );

    if (payload.isEmpty) {
      // Rien n'a changé : inutile d'appeler l'API, mais l'écran doit se fermer
      // comme après un enregistrement réussi.
      emit(AddExpenseSuccess(original));
      return;
    }

    emit(const AddExpenseSubmitting());

    try {
      final expense = await _repository.update(original.id, payload);
      if (!isClosed) emit(AddExpenseSuccess(expense));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AddExpenseFailure(f.userMessage));
    }
  }

  /// Compare deux dates au jour près : l'heure ne fait pas partie de la saisie.
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
