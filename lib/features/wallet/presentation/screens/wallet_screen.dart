import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/wallet_cubit.dart';
import '../../business_logic/wallet_state.dart';
import '../../data/models/wallet_model.dart';
import '../widgets/withdrawal_sheet.dart';

/// Portefeuille : l'argent payé par Wave par les clients, résidence par
/// résidence, et les demandes de retrait.
@RoutePage()
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletCubit>()..load(),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  Future<void> _withdraw(BuildContext context, WalletModel wallet) async {
    final cubit = context.read<WalletCubit>();
    final done = await WithdrawalSheet.show(context, wallet);
    if (done == null || !context.mounted) return;

    AppToast.success('wallet.withdraw_sent'.tr());
    // Le solde a été débité au serveur : il est relu plutôt que recalculé.
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'wallet.title'.tr()),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) => switch (state) {
          WalletInitial() ||
          WalletLoading() => const Center(child: AppLoader()),
          WalletError(:final message) => ErrorState(
            message: message,
            onRetry: () => context.read<WalletCubit>().load(),
          ),
          WalletLoaded() => RefreshIndicator(
            onRefresh: () => context.read<WalletCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                StatTile(
                  label: 'wallet.total_balance'.tr(),
                  value: CurrencyFormatter.fcfa(state.totalBalance),
                  icon: LucideIcons.wallet,
                  accent: AppAccent.green,
                  note: 'wallet.fee_note'.tr(),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: 'wallet.residences'.tr()),
                const SizedBox(height: 8),
                if (state.wallets.isEmpty)
                  EmptyState(
                    icon: LucideIcons.wallet,
                    title: 'wallet.empty_title'.tr(),
                    message: 'wallet.empty_body'.tr(),
                  )
                else
                  for (final wallet in state.wallets) ...[
                    _WalletCard(
                      wallet: wallet,
                      onWithdraw: wallet.balance >= WithdrawalRules.minimum
                          ? () => _withdraw(context, wallet)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                if (state.withdrawals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionHeading(title: 'wallet.withdrawals'.tr()),
                  const SizedBox(height: 8),
                  for (final withdrawal in state.withdrawals) ...[
                    _WithdrawalTile(withdrawal: withdrawal),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// Solde d'une résidence et son bouton de retrait.
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.onWithdraw});

  final WalletModel wallet;

  /// `null` sous le retrait minimal : le bouton reste visible, désactivé.
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconChip(icon: LucideIcons.building2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallet.residenceName ?? 'wallet.general'.tr(),
                  style: context.text.titleSmall,
                ),
              ),
              Text(
                CurrencyFormatter.fcfa(wallet.balance),
                style: context.text.amount,
              ),
            ],
          ),
          if (wallet.pendingWithdrawals > 0) ...[
            const SizedBox(height: 12),
            AppCallout(
              icon: LucideIcons.hourglass,
              tone: AppAccent.amber,
              message: 'wallet.pending_note'.tr(
                namedArgs: {
                  'amount': CurrencyFormatter.fcfa(wallet.pendingWithdrawals),
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'wallet.withdraw'.tr(),
            icon: LucideIcons.arrowDownToLine,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onWithdraw,
          ),
        ],
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({required this.withdrawal});

  final WithdrawalModel withdrawal;

  /// Même grammaire que les autres statuts : ambre en attente, vert abouti,
  /// rouge arrêté par une décision.
  static StatusTone _tone(WithdrawalStatus status) => switch (status) {
    WithdrawalStatus.pending => StatusTone.waiting,
    WithdrawalStatus.paid => StatusTone.done,
    WithdrawalStatus.rejected => StatusTone.stopped,
  };

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y').format(withdrawal.createdAt.toLocal());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  withdrawal.residenceName ?? 'wallet.general'.tr(),
                  style: context.text.titleSmall,
                ),
              ),
              AppBadge(
                label: 'wallet.status.${withdrawal.status.code}'.tr(),
                tone: _tone(withdrawal.status).accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'wallet.withdrawal_line'.tr(
              namedArgs: {
                'net': CurrencyFormatter.fcfa(withdrawal.netAmount),
                'phone': withdrawal.payoutPhone,
                'date': date,
              },
            ),
            style: context.mutedText,
          ),
          if (withdrawal.rejectionReason case final reason?) ...[
            const SizedBox(height: 6),
            Text(reason, style: context.mutedText),
          ],
        ],
      ),
    );
  }
}
