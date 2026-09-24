import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

import 'expense_item.dart';

/// Un mois de dépenses, avec son sous-total.
class _MonthGroup {
  _MonthGroup(this.label, this.expenses);

  final String label;
  final List<ExpenseModel> expenses;

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);
}

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

  static final _monthFormat = DateFormat('MMMM yyyy', 'fr');

  /// Regroupe les dépenses par mois, en conservant l'ordre du serveur.
  ///
  /// Le sous-total ne porte que sur les dépenses **chargées** : la pagination
  /// peut couper un mois en deux, et un mois incomplet afficherait un total
  /// qui grandit en défilant. Le total général, lui, vient du serveur.
  List<_MonthGroup> get _groups {
    final groups = <_MonthGroup>[];

    for (final expense in expenses) {
      final label = _monthFormat.format(expense.spentAt);

      if (groups.isNotEmpty && groups.last.label == label) {
        groups.last.expenses.add(expense);
      } else {
        groups.add(_MonthGroup(label, [expense]));
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;

    // Une entrée de plus quand un chargement est en cours : elle porte
    // l'indicateur, en pied de liste.
    final itemCount = groups.length + (isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (_, index) {
        if (index >= groups.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return _MonthSection(
          group: groups[index],
          onEdit: onEdit,
          onDelete: onDelete,
          isFirst: index == 0,
        );
      },
    );
  }
}

/// Un mois : son en-tête, son sous-total, ses dépenses.
class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.group,
    required this.isFirst,
    this.onEdit,
    this.onDelete,
  });

  final _MonthGroup group;
  final bool isFirst;
  final Future<void> Function(ExpenseModel expense)? onEdit;
  final Future<void> Function(ExpenseModel expense)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isFirst ? 4 : 24, bottom: 10),
          child: Row(
            children: [
              Text(
                group.label,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 13),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(group.total),
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
        for (final expense in group.expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DismissibleExpense(
              expense: expense,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }
}

class _DismissibleExpense extends StatelessWidget {
  const _DismissibleExpense({
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  final ExpenseModel expense;
  final Future<void> Function(ExpenseModel expense)? onEdit;
  final Future<void> Function(ExpenseModel expense)? onDelete;

  @override
  Widget build(BuildContext context) {
    final onEdit = this.onEdit;

    final item = onEdit == null
        ? ExpenseItem(expense: expense)
        : InkWell(
            onTap: () => onEdit(expense),
            borderRadius: BorderRadius.circular(16),
            child: ExpenseItem(expense: expense, showChevron: true),
          );

    final onDelete = this.onDelete;
    if (onDelete == null) return item;

    return Dismissible(
      // La clé porte l'identifiant : un index se décalerait après
      // suppression et Flutter animerait la mauvaise ligne.
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      // Une dépense supprimée n'est pas récupérable : on demande confirmation
      // plutôt que de proposer une annulation qu'il faudrait réécrire.
      confirmDismiss: (_) => _confirm(context),
      onDismissed: (_) => onDelete(expense),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: item,
    );
  }

  Future<bool> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Supprimer cette dépense ?'),
        content: Text(
          'Cette action est définitive.',
          style: AppTextStyles.labelMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppTextStyles.valueSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
