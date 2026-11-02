import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import 'expense_item.dart';

/// Historique des dépenses, à plat, la plus récente d'abord.
///
/// Sans regroupement par mois : la période se choisit dans les filtres et son
/// total ouvre l'écran. Des sous-totaux mensuels calculés sur les seules pages
/// chargées grandissaient en défilant, et faisaient double emploi avec lui.
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
      // Toujours défilable : sans cela, une première page qui ne remplit pas
      // l'écran ne produirait aucun défilement, et la suivante ne serait
      // jamais demandée.
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.only(bottom: 24),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        if (index >= expenses.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: AppLoader(size: 24)),
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: _DismissibleExpense(
            expense: expenses[index],
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        );
      },
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
        color: context.tokens.dangerSurface,
        child: Icon(LucideIcons.trash2, color: context.tokens.danger),
      ),
      child: item,
    );
  }

  Future<bool> _confirm(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: 'expense.delete_title'.tr(),
      message: 'expense.delete_body'.tr(),
      confirmLabel: 'common.delete'.tr(),
      danger: true,
    );
  }
}
