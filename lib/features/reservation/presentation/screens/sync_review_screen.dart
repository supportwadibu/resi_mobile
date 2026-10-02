import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/sync_state_badge.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/sync_review_cubit.dart';

/// Saisies hors ligne refusées à l'envoi, à arbitrer une par une.
@RoutePage()
class SyncReviewScreen extends StatelessWidget {
  const SyncReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SyncReviewCubit>()..load(),
      child: Scaffold(
        appBar: AppTopBar(title: 'arbitration.title'.tr()),
        body: SafeArea(
          child: BlocBuilder<SyncReviewCubit, SyncReviewState>(
            builder: (context, state) => switch (state) {
              SyncReviewLoading() => const Center(child: AppLoader()),
              SyncReviewError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<SyncReviewCubit>().load(),
              ),
              SyncReviewLoaded(:final items) when items.isEmpty => EmptyState(
                title: 'arbitration.empty_title'.tr(),
                message: 'arbitration.empty_body'.tr(),
                icon: LucideIcons.circleCheck,
              ),
              SyncReviewLoaded(:final items) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => index == 0
                    ? AppCallout(
                        icon: LucideIcons.circleAlert,
                        tone: AppAccent.amber,
                        message: 'arbitration.intro'.tr(),
                      )
                    : _ReviewCard(item: items[index - 1]),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final ReviewItem item;

  Future<void> _discard(BuildContext context) async {
    final cubit = context.read<SyncReviewCubit>();
    final amount = item.amount;
    // Le montant est rappelé : une saisie abandonnée peut porter de l'argent
    // encaissé au comptoir, que plus rien ne retracera.
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'arbitration.discard_title'.tr(),
      message: 'arbitration.discard_body'.tr(
        args: [
          amount == null
              ? ''
              : 'arbitration.discard_amount'.tr(
                  args: [CurrencyFormatter.format(amount.toDouble())],
                ),
        ],
      ),
      confirmLabel: 'arbitration.discard'.tr(),
      danger: true,
    );
    if (!confirmed) return;

    await cubit.discard(item);
    AppToast.success('arbitration.discarded'.tr());
  }

  Future<void> _retry(BuildContext context) async {
    final cubit = context.read<SyncReviewCubit>();
    await cubit.retry(item);
    AppToast.success('arbitration.retried'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final kindKey = 'arbitration.kind.${item.kind}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kindKey.trExists() ? kindKey.tr() : item.kind,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SyncStateBadge(state: item.state),
            ],
          ),
          if (item.detail case final detail?) ...[
            const SizedBox(height: 4),
            Text(detail, style: context.text.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            'arbitration.saved_at'.tr(
              args: [DateFormat.yMd().add_Hm().format(item.createdAt.toLocal())],
            ),
            style: context.mutedText,
          ),
          if (item.error case final error? when error.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCallout(
              icon: LucideIcons.circleAlert,
              tone: AppAccent.red,
              message: error,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'arbitration.retry'.tr(),
                  icon: LucideIcons.refreshCw,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _retry(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'arbitration.discard'.tr(),
                  icon: LucideIcons.trash2,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.danger,
                  onPressed: () => _discard(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
