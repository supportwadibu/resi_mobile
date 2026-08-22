import 'package:flutter/material.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';

import 'expense_item.dart';

class ExpenseList extends StatelessWidget {
  final List<ExpenseModel> expenses;

  /// Suppression d'une dépense. Laissé à `null` pour une liste en lecture.
  final Future<void> Function(ExpenseModel expense)? onDelete;

  /// Ouverture en modification.
  final Future<void> Function(ExpenseModel expense)? onEdit;

  final ScrollController? controller;

  /// Une page supplémentaire est en cours de chargement : un indicateur est
  /// ajouté en pied de liste.
  final bool isLoadingMore;

  const ExpenseList({
    super.key,
    required this.expenses,
    this.onDelete,
    this.onEdit,
    this.controller,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    // Une entrée de plus quand un chargement est en cours : elle porte
    // l'indicateur, en pied de liste.
    final itemCount = expenses.length + (isLoadingMore ? 1 : 0);

    return ListView.separated(
      controller: controller,
      itemCount: itemCount,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, _) => Divider(color: Colors.grey.shade100),
      itemBuilder: (_, index) {
        if (index >= expenses.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final expense = expenses[index];
        final item = onEdit == null
            ? ExpenseItem(expense: expense)
            : InkWell(
                onTap: () => onEdit!(expense),
                child: ExpenseItem(expense: expense, showChevron: true),
              );

        if (onDelete == null) return item;

        return Dismissible(
          // La clé porte l'identifiant : un index se décalerait après
          // suppression et Flutter animerait la mauvaise ligne.
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          // Une dépense supprimée n'est pas récupérable : on demande confirmation
          // plutôt que de proposer une annulation qu'il faudrait réécrire.
          confirmDismiss: (_) => _confirm(context),
          onDismissed: (_) => onDelete!(expense),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.shade50,
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          child: item,
        );
      },
    );
  }

  Future<bool> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette dépense ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
