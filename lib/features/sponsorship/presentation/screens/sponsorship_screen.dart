import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/sponsorship_cubit.dart';
import '../../business_logic/sponsorship_state.dart';
import '../../data/models/sponsorship_model.dart';
import '../widgets/apply_code_sheet.dart';
import '../widgets/redemption_sheet.dart';

/// Parrainage : le code à partager, les gains et leur usage, les filleuls.
@RoutePage()
class SponsorshipScreen extends StatelessWidget {
  const SponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SponsorshipCubit>()..load(),
      child: const _SponsorshipView(),
    );
  }
}

class _SponsorshipView extends StatelessWidget {
  const _SponsorshipView();

  Future<void> _redeem(
    BuildContext context,
    SponsorshipOverview overview,
  ) async {
    final cubit = context.read<SponsorshipCubit>();
    final done = await RedemptionSheet.show(context, overview);
    if (done != true || !context.mounted) return;

    AppToast.success('sponsorship.redeem_sent'.tr());
    // Débité au serveur : relu plutôt que recalculé.
    await cubit.load();
  }

  Future<void> _applyCode(BuildContext context) async {
    final cubit = context.read<SponsorshipCubit>();
    final done = await ApplyCodeSheet.show(context);
    if (done != true || !context.mounted) return;

    AppToast.success('sponsorship.apply_done'.tr());
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'sponsorship.title'.tr()),
      body: BlocBuilder<SponsorshipCubit, SponsorshipState>(
        builder: (context, state) => switch (state) {
          SponsorshipInitial() ||
          SponsorshipLoading() => const Center(child: AppLoader()),
          SponsorshipError(:final message) => ErrorState(
            message: message,
            onRetry: () => context.read<SponsorshipCubit>().load(),
          ),
          SponsorshipLoaded(:final overview) => RefreshIndicator(
            onRefresh: () => context.read<SponsorshipCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (!overview.enabled) ...[
                  AppCallout(
                    icon: LucideIcons.pause,
                    tone: AppAccent.amber,
                    message: 'sponsorship.paused'.tr(),
                  ),
                  const SizedBox(height: 16),
                ],
                _CodeCard(code: overview.code),
                const SizedBox(height: 16),
                StatTile(
                  label: 'sponsorship.balance'.tr(),
                  value: CurrencyFormatter.fcfa(overview.balance),
                  icon: LucideIcons.gift,
                  accent: AppAccent.green,
                  note: overview.pendingBalance > 0
                      ? 'sponsorship.pending_note'.tr(
                          args: [
                            CurrencyFormatter.fcfa(overview.pendingBalance),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _ProgressCard(
                  overview: overview,
                  onRedeem: overview.canRedeem
                      ? () => _redeem(context, overview)
                      : null,
                ),
                const SizedBox(height: 24),
                SectionHeading(title: 'sponsorship.how_title'.tr()),
                const SizedBox(height: 8),
                _HowItWorksCard(overview: overview),
                if (overview.sponsorName != null || overview.canApplyCode) ...[
                  const SizedBox(height: 12),
                  _OwnSponsorCard(
                    sponsorName: overview.sponsorName,
                    onApply: overview.canApplyCode
                        ? () => _applyCode(context)
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                SectionHeading(
                  title: 'sponsorship.sponsored_title'.tr(
                    args: ['${overview.sponsoredCount}'],
                  ),
                ),
                const SizedBox(height: 8),
                if (state.sponsored.isEmpty)
                  EmptyState(
                    icon: LucideIcons.userPlus,
                    title: 'sponsorship.sponsored_empty_title'.tr(),
                    message: 'sponsorship.sponsored_empty_body'.tr(),
                  )
                else
                  for (final user in state.sponsored) ...[
                    _SponsoredTile(user: user),
                    const SizedBox(height: 8),
                  ],
                if (state.redemptions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionHeading(title: 'sponsorship.redemptions_title'.tr()),
                  const SizedBox(height: 8),
                  for (final redemption in state.redemptions) ...[
                    _RedemptionTile(redemption: redemption),
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

/// Le code, à copier ou à envoyer sur WhatsApp — le canal par lequel on se
/// recommande une adresse en Côte d'Ivoire.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    AppToast.success('sponsorship.code_copied'.tr());
  }

  /// `wa.me` sans numéro : WhatsApp ouvre le choix du destinataire, le
  /// message prérempli. Sans WhatsApp, le message part au presse-papiers.
  Future<void> _share(BuildContext context) async {
    final message = 'sponsorship.share_message'.tr(namedArgs: {'code': code});
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    await Clipboard.setData(ClipboardData(text: message));
    AppToast.info('sponsorship.share_copied'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('sponsorship.code_title'.tr(), style: context.mutedText),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: SelectableText(code, style: context.text.figure)),
              AppIconButton(
                icon: LucideIcons.copy,
                label: 'sponsorship.copy_code'.tr(),
                bordered: true,
                onPressed: () => _copy(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('sponsorship.code_hint'.tr(), style: context.mutedText),
          const SizedBox(height: 12),
          AppButton(
            label: 'sponsorship.share'.tr(),
            icon: LucideIcons.send,
            expand: true,
            onPressed: () => _share(context),
          ),
        ],
      ),
    );
  }
}

/// Progression vers le seuil, et le bouton qui l'utilise une fois atteint.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.overview, required this.onRedeem});

  final SponsorshipOverview overview;

  /// `null` sous le seuil : le bouton reste visible, désactivé.
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'sponsorship.progress'.tr(
              namedArgs: {
                'balance': CurrencyFormatter.fcfa(
                  overview.balance.clamp(0, double.infinity),
                ),
                'min': CurrencyFormatter.fcfa(overview.minimumAmount),
              },
            ),
            style: context.text.titleSmall,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: overview.progress,
            minHeight: 4,
            color: t.accent(AppAccent.green),
            backgroundColor: t.accentSoft(AppAccent.green),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'sponsorship.redeem'.tr(),
            icon: LucideIcons.gift,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onRedeem,
          ),
          // Sans ce rappel, un bouton grisé ne dit pas ce qui manque.
          if (onRedeem == null) ...[
            const SizedBox(height: 8),
            Text(
              overview.options.isEmpty
                  ? 'sponsorship.redeem_closed'.tr()
                  : 'sponsorship.redeem_threshold'.tr(
                      args: [CurrencyFormatter.fcfa(overview.minimumAmount)],
                    ),
              style: context.mutedText,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ce que rapporte chaque filleul, selon les réglages de l'équipe.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.overview});

  final SponsorshipOverview overview;

  String _reward(RewardView reward) {
    if (!reward.isPercent) return CurrencyFormatter.fcfa(reward.value);
    final percent = 'sponsorship.reward_percent'.tr(args: ['${reward.value}']);
    final cap = reward.maxAmount;
    return cap == null
        ? percent
        : 'sponsorship.reward_capped'.tr(
            args: [percent, CurrencyFormatter.fcfa(cap)],
          );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Step(icon: LucideIcons.send, text: 'sponsorship.how_share'.tr()),
          const SizedBox(height: 12),
          _Step(
            icon: LucideIcons.creditCard,
            text: 'sponsorship.how_owner'.tr(
              args: [_reward(overview.ownerReward)],
            ),
          ),
          const SizedBox(height: 12),
          _Step(
            icon: LucideIcons.calendarCheck,
            text: 'sponsorship.how_client'.tr(
              args: [_reward(overview.clientReward)],
            ),
          ),
          const SizedBox(height: 12),
          _Step(
            icon: LucideIcons.gift,
            text: 'sponsorship.how_redeem'.tr(
              args: [CurrencyFormatter.fcfa(overview.minimumAmount)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconChip(icon: icon, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    );
  }
}

/// Son propre parrain, ou la saisie de son code s'il est encore temps.
class _OwnSponsorCard extends StatelessWidget {
  const _OwnSponsorCard({required this.sponsorName, required this.onApply});

  final String? sponsorName;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    if (sponsorName case final name?) {
      return AppCard(
        child: Row(
          children: [
            const IconChip(icon: LucideIcons.userCheck),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'sponsorship.sponsored_by'.tr(args: [name]),
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return AppButton(
      label: 'sponsorship.apply_cta'.tr(),
      icon: LucideIcons.ticket,
      variant: AppButtonVariant.ghost,
      expand: true,
      onPressed: onApply,
    );
  }
}

class _SponsoredTile extends StatelessWidget {
  const _SponsoredTile({required this.user});

  final SponsoredUser user;

  /// Grammaire commune : ambre en attente d'une action du filleul, violet le
  /// temps du délai, vert acquis, rouge annulé.
  static StatusTone _tone(SponsoredStatus status) => switch (status) {
    SponsoredStatus.registered => StatusTone.waiting,
    SponsoredStatus.pending => StatusTone.ongoing,
    SponsoredStatus.earned => StatusTone.done,
    SponsoredStatus.cancelled => StatusTone.stopped,
  };

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y').format(user.createdAt.toLocal());
    final detail = switch (user.status) {
      SponsoredStatus.registered => 'sponsorship.sponsored_waiting'.tr(),
      SponsoredStatus.pending when user.availableAt != null =>
        'sponsorship.sponsored_pending'.tr(
          namedArgs: {
            'amount': CurrencyFormatter.fcfa(user.rewardAmount),
            'date': DateFormat('d MMM y').format(user.availableAt!.toLocal()),
          },
        ),
      SponsoredStatus.pending ||
      SponsoredStatus.earned => CurrencyFormatter.fcfa(user.rewardAmount),
      SponsoredStatus.cancelled => null,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconChip(
                icon: user.isOwner ? LucideIcons.building2 : LucideIcons.user,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: context.text.titleSmall),
                    Text(
                      '${(user.isOwner ? 'sponsorship.role_owner' : 'sponsorship.role_client').tr()} · $date',
                      style: context.mutedText,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: user.status.labelKey.tr(),
                tone: _tone(user.status),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, style: context.mutedText),
          ],
        ],
      ),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  const _RedemptionTile({required this.redemption});

  final RedemptionModel redemption;

  static StatusTone _tone(RedemptionStatus status) => switch (status) {
    RedemptionStatus.pending => StatusTone.waiting,
    RedemptionStatus.paid || RedemptionStatus.completed => StatusTone.done,
    RedemptionStatus.rejected => StatusTone.stopped,
  };

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y').format(redemption.createdAt.toLocal());
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  redemption.type.labelKey.tr(),
                  style: context.text.titleSmall,
                ),
              ),
              AppBadge(
                label: 'sponsorship.redemption_status.${redemption.status.code}'
                    .tr(),
                tone: _tone(redemption.status).accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              CurrencyFormatter.fcfa(redemption.amount),
              ?redemption.payoutPhone,
              date,
            ].join(' · '),
            style: context.mutedText,
          ),
          if (redemption.rejectionReason case final reason?) ...[
            const SizedBox(height: 6),
            Text(reason, style: context.mutedText),
          ],
        ],
      ),
    );
  }
}
