import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/wallet_transactions_cubit.dart';
import '../../business_logic/wallet_transactions_state.dart';
import '../../data/models/wallet_model.dart';

/// Journal d'un portefeuille : ce qui l'a crédité et débité, et le solde
/// après chaque mouvement — de quoi justifier le chiffre de la carte.
@RoutePage()
class WalletTransactionsScreen extends StatelessWidget {
  const WalletTransactionsScreen({required this.wallet, super.key});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletTransactionsCubit>(param1: wallet.id)..load(),
      child: Scaffold(
        appBar: AppTopBar(title: wallet.residenceName ?? 'wallet.general'.tr()),
        body: const _TransactionsBody(),
      ),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletTransactionsCubit>();

    return BlocBuilder<WalletTransactionsCubit, WalletTransactionsState>(
      builder: (context, state) => switch (state) {
        WalletTransactionsInitial() ||
        WalletTransactionsLoading() => const SimpleListSkeleton(itemCount: 6),
        WalletTransactionsError(:final message) => ErrorState(
          message: message,
          onRetry: cubit.load,
        ),
        WalletTransactionsLoaded(:final items) when items.isEmpty => EmptyState(
          icon: LucideIcons.arrowLeftRight,
          title: 'wallet.movements_empty_title'.tr(),
          message: 'wallet.movements_empty_body'.tr(),
        ),
        WalletTransactionsLoaded(:final items, :final isLoadingMore) =>
          RefreshIndicator(
            onRefresh: cubit.load,
            child: NotificationListener<ScrollNotification>(
              // Charge la suite avant le bas, pour que le défilement ne
              // marque pas d'arrêt.
              onNotification: (notification) {
                final metrics = notification.metrics;
                if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                  cubit.loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: items.length + (isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: AppLoader(size: 24)),
                    );
                  }
                  return _TransactionTile(transaction: items[i]);
                },
              ),
            ),
          ),
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final date = DateFormat(
      'd MMM y · HH:mm',
    ).format(transaction.createdAt.toLocal());
    final sign = transaction.isCredit ? '+' : '−';

    return AppCard(
      child: Row(
        children: [
          IconChip(
            icon: transaction.type.icon,
            accent: transaction.isCredit ? AppAccent.green : AppAccent.neutral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.labelKey.tr(),
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(date, style: context.mutedText),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${CurrencyFormatter.fcfa(transaction.amount.abs())}',
                style: context.text.amount.copyWith(
                  color: transaction.isCredit ? tokens.accentGreen : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'wallet.balance_after'.tr(
                  namedArgs: {
                    'amount': CurrencyFormatter.fcfa(transaction.balanceAfter),
                  },
                ),
                style: context.mutedText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
