import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';
import 'plan_gate.dart';
import 'plan_style.dart';

/// Durée d'un essai à l'ouverture, pour la jauge des jours restants. Un essai
/// prolongé par l'équipe peut la dépasser : la jauge est alors pleine.
/// Recopie de `TRIAL_DURATION_DAYS` côté API : à reporter à la main.
const _trialDays = 30;

/// Carte « Mon forfait » : le forfait en cours, son échéance, et pour un essai
/// les jours qui restent.
///
/// Même carte sur le profil et en tête de l'écran des forfaits : le
/// propriétaire lit son forfait au même format partout.
class PlanStatusCard extends StatelessWidget {
  const PlanStatusCard({this.onTap, super.key});

  /// Rend la carte cliquable — vers l'écran des forfaits, depuis le profil.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final plan = planCubitOrNull();
    if (plan == null) return const SizedBox.shrink();

    return BlocBuilder<PlanCubit, PlanState>(
      bloc: plan,
      builder: (context, state) {
        final style = currentPlanStyle(state);
        final known = state is PlanKnown ? state : null;

        if (style == null) {
          // Compte inactif : rouge, comme tout ce qu'une décision a arrêté.
          return GestureDetector(
            onTap: onTap,
            child: AppCallout(
              icon: LucideIcons.circleAlert,
              tone: AppAccent.red,
              title: 'plans.inactive_title'.tr(),
              message: 'plans.inactive_body'.tr(),
            ),
          );
        }

        return AppCard(
          onTap: onTap,
          child: _ActiveContent(
            style: style,
            daysRemaining: known?.daysRemaining,
            endDate: known?.endDate,
            showChevron: onTap != null,
          ),
        );
      },
    );
  }
}

class _ActiveContent extends StatelessWidget {
  const _ActiveContent({
    required this.style,
    required this.daysRemaining,
    required this.endDate,
    required this.showChevron,
  });

  final PlanStyle style;
  final int? daysRemaining;
  final DateTime? endDate;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final days = daysRemaining;
    final end = endDate;
    final isTrial = style == PlanStyle.trial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PlanIconBadge(style: style),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('plans.my_plan'.tr(), style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  Text(style.label, style: context.text.titleMedium),
                ],
              ),
            ),
            PlanChip(label: 'plans.in_progress'.tr(), accent: style.accent),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.tokens.muted,
              ),
            ],
          ],
        ),
        if (days != null || end != null) ...[
          const SizedBox(height: 14),
          if (isTrial && days != null) ...[
            LinearProgressIndicator(
              value: (days / _trialDays).clamp(0, 1).toDouble(),
              minHeight: 4,
              color: style.colorOf(context),
              backgroundColor: style.softOf(context),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            [
              if (days != null) 'plans.days_left'.plural(days),
              if (end != null)
                'plans.until'.tr(
                  args: [DateFormat('d MMMM y').format(end.toLocal())],
                ),
            ].join(' · '),
            style: context.text.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Étiquette colorée d'état d'un forfait : « En cours », « Actuel »,
/// « Recommandé ».
class PlanChip extends StatelessWidget {
  const PlanChip({required this.label, required this.accent, super.key});

  final String label;
  final AppAccent accent;

  @override
  Widget build(BuildContext context) => AppBadge(label: label, tone: accent);
}
