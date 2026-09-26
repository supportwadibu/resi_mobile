import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/session/session_role.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';
import '../../business_logic/subscription_plans_cubit.dart';
import '../../business_logic/subscription_plans_state.dart';
import '../../data/models/subscription_plan_model.dart';
import '../widgets/plan_status_card.dart';
import '../widgets/plan_style.dart';

/// Forfaits : le forfait en cours, puis Pro et Premium, payables par Wave.
///
/// [blocking] : le compte est inactif, l'écran remplace l'application. Pas de
/// retour possible — l'API refuserait tout le reste —, seulement la
/// souscription ou la déconnexion.
@RoutePage()
class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({this.blocking = false, super.key});

  final bool blocking;

  @override
  Widget build(BuildContext context) {
    // Le gérant ne souscrit pas : `GET /proprio/plans` lui est fermé, et c'est
    // l'abonnement de son propriétaire qui décide de son accès.
    if (sl<SessionRole>().value == 'gerant') {
      return _ManagerBlockedView(blocking: blocking);
    }

    return BlocProvider(
      create: (_) => sl<SubscriptionPlansCubit>()..load(),
      child: _PlansView(blocking: blocking),
    );
  }
}

class _PlansView extends StatefulWidget {
  const _PlansView({required this.blocking});

  final bool blocking;

  @override
  State<_PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<_PlansView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<PlanCubit>().refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour de l'application Wave : le paiement est constaté aussitôt, sans
  /// attendre le webhook.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SubscriptionPlansCubit>().confirmPending();
    }
  }

  Future<void> _pay(SubscriptionPlanModel plan) async {
    final url = await context.read<SubscriptionPlansCubit>().pay(plan);
    if (url == null) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) AppToast.error('subscription.wave_unavailable'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.blocking,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'subscription.title'.tr(),
          // Écran bloquant : pas de retour, l'API refuserait tout le reste.
          showBack: !widget.blocking,
          actions: [
            if (widget.blocking)
              AppButton(
                label: 'subscription.logout'.tr(),
                icon: LucideIcons.logOut,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: () => _logout(context),
              ),
          ],
        ),
        body: BlocConsumer<SubscriptionPlansCubit, SubscriptionPlansState>(
          listenWhen: (previous, current) =>
              current is SubscriptionPlansLoaded &&
              current.outcome == CheckoutOutcome.paid &&
              (previous is! SubscriptionPlansLoaded ||
                  previous.outcome != CheckoutOutcome.paid),
          listener: (context, _) {
            AppToast.success('subscription.paid'.tr());
            context.router.replaceAll([const HomeRoute()]);
          },
          builder: (context, state) => switch (state) {
            SubscriptionPlansInitial() ||
            SubscriptionPlansLoading() => const Center(child: AppLoader()),
            SubscriptionPlansError(:final message) => ErrorState(
              message: message,
              onRetry: () => context.read<SubscriptionPlansCubit>().load(),
            ),
            SubscriptionPlansLoaded() => _LoadedView(
              state: state,
              onPay: _pay,
              onVerify: () =>
                  context.read<SubscriptionPlansCubit>().confirmPending(),
            ),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.onPay,
    required this.onVerify,
  });

  final SubscriptionPlansLoaded state;
  final ValueChanged<SubscriptionPlanModel> onPay;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanCubit, PlanState>(
      bloc: sl<PlanCubit>(),
      builder: (context, plan) {
        final current = currentPlanStyle(plan);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const PlanStatusCard(),

            if (state.message != null) ...[
              const SizedBox(height: 12),
              _Notice.error(state.message!),
            ],
            if (state.outcome == CheckoutOutcome.waiting) ...[
              const SizedBox(height: 12),
              _WaitingNotice(onVerify: onVerify),
            ],
            if (state.outcome == CheckoutOutcome.failed) ...[
              const SizedBox(height: 12),
              _Notice.error('subscription.failed'.tr()),
            ],

            const SizedBox(height: 24),
            SectionHeading(title: 'plans.choose'.tr()),
            const SizedBox(height: 8),

            // L'essai est un forfait à part entière : affiché tant qu'il
            // court, sans bouton — il ne s'achète pas.
            if (current == PlanStyle.trial) ...[
              const _TrialCard(),
              const SizedBox(height: 12),
            ],

            if (state.plans.isEmpty)
              _Notice.info('subscription.empty'.tr())
            else
              for (final offer in state.plans) ...[
                _PlanCard(
                  plan: offer,
                  isCurrent:
                      current != null &&
                      current != PlanStyle.trial &&
                      (current == PlanStyle.full) == offer.isFull,
                  isPaying: state.payingPlanId == offer.id,
                  onPay: state.payingPlanId == null ? () => onPay(offer) : null,
                ),
                const SizedBox(height: 12),
              ],

            const SizedBox(height: 8),
            const _SecureNote(),
          ],
        );
      },
    );
  }
}

/// Carte d'un forfait payant.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isPaying,
    required this.onPay,
  });

  final SubscriptionPlanModel plan;
  final bool isCurrent;
  final bool isPaying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final style = plan.isFull ? PlanStyle.full : PlanStyle.basic;
    // Forfait en cours ou recommandé : filet `primary`, comme toute option
    // mise en avant.
    final highlight = isCurrent || plan.isFull;
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(
          color: highlight ? t.primary : t.border,
          width: highlight ? 1.5 : 1,
        ),
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
                    Text(plan.name, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(style.tagline, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (isCurrent)
                PlanChip(label: 'plans.current'.tr(), accent: style.accent)
              else if (plan.isFull)
                PlanChip(label: 'plans.recommended'.tr(), accent: style.accent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.short(plan.price),
                style: context.text.figure,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'plans.per_days'.tr(args: ['${plan.durationDays}']),
                  style: context.mutedText,
                ),
              ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: context.mutedText.copyWith(height: 1.45),
            ),
          ],
          // Les lignes saisies dans le backoffice : c'est là que l'équipe
          // décrit chaque forfait.
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            for (final line in plan.features)
              _FeatureLine(text: line, color: style.colorOf(context)),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: (isCurrent ? 'plans.renew' : 'subscription.pay').tr(),
            // Le forfait mis en avant garde le bouton noir ; l'autre passe en
            // secondaire, pour qu'un seul appel à l'action domine l'écran.
            variant: highlight
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            expand: true,
            isLoading: isPaying,
            onPressed: onPay,
          ),
        ],
      ),
    );
  }
}

/// L'essai en cours, présenté comme un forfait.
class _TrialCard extends StatelessWidget {
  const _TrialCard();

  @override
  Widget build(BuildContext context) {
    const style = PlanStyle.trial;

    return Container(
      padding: const EdgeInsets.all(16),
      color: style.softOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PlanIconBadge(style: style),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style.label, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(style.tagline, style: context.text.bodySmall),
                  ],
                ),
              ),
              PlanChip(label: 'plans.in_progress'.tr(), accent: style.accent),
            ],
          ),
          const SizedBox(height: 14),
          _FeatureLine(
            text: 'plans.trial_body'.tr(),
            color: style.colorOf(context),
          ),
          _FeatureLine(
            text: 'plans.trial_then'.tr(),
            color: style.colorOf(context),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.circleCheck, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// Paiement ouvert chez Wave, en attente du retour du propriétaire.
class _WaitingNotice extends StatelessWidget {
  const _WaitingNotice({required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return AppCallout(
      icon: LucideIcons.hourglass,
      tone: AppAccent.blue,
      message: 'subscription.waiting'.tr(),
      action: AppButton(
        label: 'subscription.verify'.tr(),
        icon: LucideIcons.refreshCw,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.sm,
        onPressed: onVerify,
      ),
    );
  }
}

/// Bandeau d'information ou d'erreur, au format des bandeaux du profil.
class _Notice extends StatelessWidget {
  const _Notice.error(this.message)
    : tone = AppAccent.red,
      icon = LucideIcons.circleAlert;

  const _Notice.info(this.message)
    : tone = AppAccent.blue,
      icon = LucideIcons.info;

  final String message;
  final AppAccent tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCallout(icon: icon, tone: tone, message: message);
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(LucideIcons.lock, size: 11, color: context.tokens.muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'plans.secure_note'.tr(),
            style: context.text.bodySmall!.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// Gérant d'un propriétaire inactif ou au forfait Pro.
class _ManagerBlockedView extends StatelessWidget {
  const _ManagerBlockedView({required this.blocking});

  final bool blocking;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !blocking,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconChip(
                    icon: LucideIcons.hourglass,
                    accent: AppAccent.amber,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'subscription.gerant_title'.tr(),
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'subscription.gerant_body'.tr(),
                    textAlign: TextAlign.center,
                    style: context.mutedText.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'common.retry'.tr(),
                    icon: LucideIcons.rotateCw,
                    expand: true,
                    onPressed: () =>
                        context.router.replaceAll([const HomeRoute()]),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'subscription.logout'.tr(),
                    icon: LucideIcons.logOut,
                    variant: AppButtonVariant.ghost,
                    expand: true,
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  final router = context.router;
  await sl<AuthService>().logout();
  await sl<PlanCubit>().clear();
  await router.replaceAll([const LoginRoute()]);
}
