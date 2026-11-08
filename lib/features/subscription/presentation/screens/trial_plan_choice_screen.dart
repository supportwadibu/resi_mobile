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
import 'package:resi_africa/shared/widgets/app_logo.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/trial_choice_cubit.dart';
import '../../business_logic/trial_choice_state.dart';
import '../../data/models/plan_access.dart';
import '../../data/models/subscription_plan_model.dart';
import '../widgets/plan_feature_line.dart';
import '../widgets/plan_style.dart';

/// Choix du forfait de l'essai gratuit : RESI Pro ou RESI Pro+.
///
/// Aucun forfait n'est attribué d'office : tant que le propriétaire n'a pas
/// choisi, cet écran remplace l'application (garde de `app.dart`). Seule la
/// déconnexion permet d'en sortir autrement.
@RoutePage()
class TrialPlanChoiceScreen extends StatelessWidget {
  const TrialPlanChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TrialChoiceCubit>()..load(),
      child: const _TrialPlanChoiceView(),
    );
  }
}

class _TrialPlanChoiceView extends StatelessWidget {
  const _TrialPlanChoiceView();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<TrialChoiceCubit, TrialChoiceState>(
            listener: (context, state) {
              if (state is TrialChoiceStarted) {
                context.router.replaceAll([const TrialWelcomeRoute()]);
              }
            },
            builder: (context, state) => switch (state) {
              TrialChoiceLoaded() => _Offers(state: state),
              TrialChoiceError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<TrialChoiceCubit>().load(),
              ),
              _ => const Center(child: AppLoader()),
            },
          ),
        ),
      ),
    );
  }
}

class _Offers extends StatelessWidget {
  const _Offers({required this.state});

  final TrialChoiceLoaded state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: AppLogo(height: 28),
              ),
              const SizedBox(height: 32),
              Text(
                'trial.choose_title'.tr(),
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'trial.choose_body'.tr(),
                style: context.mutedText.copyWith(height: 1.5),
              ),
              if (state.message != null) ...[
                const SizedBox(height: 16),
                AppCallout(
                  icon: LucideIcons.circleAlert,
                  tone: AppAccent.red,
                  message: state.message,
                ),
              ],
              const SizedBox(height: 24),
              if (state.offers.isEmpty)
                AppCallout(
                  icon: LucideIcons.info,
                  message: 'subscription.empty'.tr(),
                )
              else
                for (final offer in state.offers) ...[
                  _OfferCard(
                    plan: offer,
                    starting: state.starting,
                    onChoose: () =>
                        context.read<TrialChoiceCubit>().choose(offer.access),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 8),
              AppButton(
                label: 'subscription.logout'.tr(),
                icon: LucideIcons.logOut,
                variant: AppButtonVariant.ghost,
                onPressed: state.starting == null
                    ? () => _logout(context)
                    : null,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final router = context.router;
    await sl<AuthService>().logout();
    await sl<PlanCubit>().clear();
    await router.replaceAll([const LoginRoute()]);
  }
}

/// Carte d'un forfait à l'essai : son nom, ce qu'il ouvre, son prix ensuite.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.plan,
    required this.starting,
    required this.onChoose,
  });

  final SubscriptionPlanModel plan;

  /// Palier dont l'essai s'ouvre : tous les boutons attendent.
  final PlanAccess? starting;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final style = PlanStyle.of(plan.access) ?? PlanStyle.pro;
    final t = context.tokens;

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
              PlanIconBadge(style: style),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style.label, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'trial.then_price'.tr(
                        args: [
                          CurrencyFormatter.short(plan.price),
                          '${plan.durationDays}',
                        ],
                      ),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            for (final line in plan.features)
              PlanFeatureLine(text: line, color: style.colorOf(context)),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'trial.try_plan'.tr(args: [style.label]),
            icon: LucideIcons.gift,
            isLoading: starting == plan.access,
            onPressed: starting == null ? onChoose : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}
