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
import '../../../../core/router/app_router.gr.dart';
import '../../business_logic/wallet_cubit.dart';
import '../../business_logic/wallet_state.dart';
import '../../data/models/wallet_model.dart';
import '../widgets/payout_numbers_sheet.dart';
import '../widgets/wave_logo.dart';
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

  /// Retrait vers un numéro Wave enregistré. Sans numéro, la feuille des
  /// numéros s'ouvre d'abord : un retrait ne part que vers un numéro que le
  /// propriétaire a pris le temps d'enregistrer.
  Future<void> _withdraw(
    BuildContext context,
    WalletModel wallet,
    PayoutSettings settings,
  ) async {
    final cubit = context.read<WalletCubit>();
    var current = settings;

    if (current.numbers.isEmpty) {
      final saved = await PayoutNumbersSheet.show(context, const []);
      if (saved == null || saved.isEmpty || !context.mounted) return;
      current = PayoutSettings(
        minimumWithdrawal: settings.minimumWithdrawal,
        numbers: saved,
      );
      cubit.load();
    }

    final done = await WithdrawalSheet.show(context, wallet, current);
    if (done == null || !context.mounted) return;

    AppToast.success('wallet.withdraw_sent'.tr());
    // Le solde a été débité au serveur : il est relu plutôt que recalculé.
    await cubit.load();
  }

  Future<void> _editNumbers(
    BuildContext context,
    PayoutSettings settings,
  ) async {
    final cubit = context.read<WalletCubit>();
    final saved = await PayoutNumbersSheet.show(context, settings.numbers);
    if (saved == null || !context.mounted) return;

    AppToast.success('wallet.payout_numbers_saved'.tr());
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
                  note: 'wallet.fee_note_min'.tr(
                    args: [
                      CurrencyFormatter.fcfa(
                        state.payoutSettings.minimumWithdrawal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: 'wallet.payout_numbers'.tr()),
                const SizedBox(height: 8),
                _PayoutNumbersCard(
                  numbers: state.payoutSettings.numbers,
                  onEdit: () => _editNumbers(context, state.payoutSettings),
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
                      minimum: state.payoutSettings.minimumWithdrawal,
                      onWithdraw:
                          wallet.balance >=
                              state.payoutSettings.minimumWithdrawal
                          ? () =>
                                _withdraw(context, wallet, state.payoutSettings)
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

/// Numéros Wave enregistrés pour les retraits, et leur modification.
class _PayoutNumbersCard extends StatelessWidget {
  const _PayoutNumbersCard({required this.numbers, required this.onEdit});

  final List<PayoutNumber> numbers;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WaveLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'wallet.payout_wave_only'.tr(),
                  style: context.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (numbers.isEmpty)
            Text('wallet.payout_numbers_empty'.tr(), style: context.mutedText)
          else
            for (final number in numbers) ...[
              Text(
                'wallet.payout_number_line'.tr(
                  args: ['${number.slot}', number.phone],
                ),
                style: context.text.titleSmall,
              ),
              if (number.holderName case final name?)
                Text(name, style: context.mutedText),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 4),
          AppButton(
            label: numbers.isEmpty
                ? 'wallet.payout_numbers_add'.tr()
                : 'wallet.payout_numbers_edit'.tr(),
            icon: numbers.isEmpty ? LucideIcons.plus : LucideIcons.pencil,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Solde d'une résidence et son bouton de retrait.
class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.minimum,
    required this.onWithdraw,
  });

  final WalletModel wallet;

  /// Retrait minimal réglé par l'équipe, rappelé sous le bouton désactivé.
  final int minimum;

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
          // Hors du solde retirable : sans cette ligne, un acompte reçu
          // n'apparaîtrait nulle part avant l'arrivée du client.
          if (wallet.heldBalance > 0) ...[
            const SizedBox(height: 12),
            AppCallout(
              icon: LucideIcons.lock,
              tone: AppAccent.blue,
              title:
                  '${'wallet_held.label'.tr()} : ${CurrencyFormatter.fcfa(wallet.heldBalance)}',
              message: 'wallet_held.hint'.tr(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'wallet.movements'.tr(),
                  icon: LucideIcons.history,
                  variant: AppButtonVariant.ghost,
                  expand: true,
                  onPressed: () => context.router.push(
                    WalletTransactionsRoute(wallet: wallet),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'wallet.withdraw'.tr(),
                  icon: LucideIcons.arrowDownToLine,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: onWithdraw,
                ),
              ),
            ],
          ),
          // Sans ce rappel, un bouton grisé ne dit pas ce qui manque.
          if (onWithdraw == null && wallet.balance > 0) ...[
            const SizedBox(height: 8),
            Text(
              'wallet.minimum_hint'.tr(args: [CurrencyFormatter.fcfa(minimum)]),
              style: context.mutedText,
            ),
          ],
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
