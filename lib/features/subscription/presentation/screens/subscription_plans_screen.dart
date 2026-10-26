import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/deep_links/payment_return_links.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/session/session_role.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';
import '../../business_logic/subscription_plans_cubit.dart';
import '../../business_logic/subscription_plans_state.dart';
import '../../data/models/plan_access.dart';
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
    sl<PaymentReturnLinks>().attach(_onPaymentReturn);
    sl<PlanCubit>().refresh();
  }

  @override
  void dispose() {
    sl<PaymentReturnLinks>().detach(_onPaymentReturn);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour par la page du site (`resi://abonnement?statut=…`).
  ///
  /// Le succès n'est pas annoncé ici : la confirmation le constate, et le
  /// `listener` de l'écran l'annonce avant de ramener à l'accueil. L'échec,
  /// lui, l'est tout de suite — la session Wave peut rester ouverte après une
  /// tentative refusée, et la confirmation la dirait encore « en attente ».
  void _onPaymentReturn(PaymentReturn outcome) {
    if (outcome == PaymentReturn.failure) {
      AppToast.error('subscription.return_failed'.tr());
    }
    context.read<SubscriptionPlansCubit>().confirmPending();
  }

  /// Retour de l'application Wave : le paiement est constaté aussitôt, sans
  /// attendre le webhook.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SubscriptionPlansCubit>().confirmPending();
    }
  }

  /// Paiement, précédé du détail de ce que Wave débitera : le propriétaire
  /// voit les frais de 1 % et les conditions de résiliation avant de payer.
  Future<void> _pay(SubscriptionPlanModel plan) async {
    final cubit = context.read<SubscriptionPlansCubit>();
    final state = cubit.state;
    final options = state is SubscriptionPlansLoaded
        ? state.options
        : SubscriptionOptionsModel.none;
    final quote = options.quoteFor(planId: plan.id, price: plan.price);

    final accepted = await showAppSheet<bool>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'plans.pay_title'.tr(args: [plan.name]),
        footer: AppButton(
          label: 'plans.pay_with_wave'.tr(
            args: [CurrencyFormatter.fcfa(quote.total)],
          ),
          icon: LucideIcons.wallet,
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        child: _PaymentSummary(quote: quote),
      ),
    );
    if (accepted != true || !mounted) return;

    final url = await cubit.pay(plan);
    if (url == null) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) AppToast.error('subscription.wave_unavailable'.tr());
  }

  /// Résiliation, issue annoncée avant de valider : les montants viennent du
  /// serveur, qui applique la même règle à l'envoi.
  Future<void> _confirmCancel(SubscriptionOptionsModel options) async {
    final cubit = context.read<SubscriptionPlansCubit>();
    final refund = CurrencyFormatter.fcfa(options.refundAmount);
    final credit = CurrencyFormatter.fcfa(options.refundCredit);
    final endsAt = options.accessEndsAt == null
        ? ''
        : DateFormat('d MMMM y').format(options.accessEndsAt!.toLocal());

    final message = switch (options.cancelMode) {
      CancelMode.fullRefund when options.refundCredit > 0 =>
        'plans.cancel_full_with_credit'.tr(args: [refund, credit]),
      CancelMode.fullRefund => 'plans.cancel_full'.tr(args: [refund]),
      CancelMode.partialRefund =>
        options.refundAmount > 0
            ? 'plans.cancel_partial'.tr(args: [refund, credit])
            : 'plans.cancel_partial_credit_only'.tr(args: [credit]),
      CancelMode.periodEnd ||
      null => 'plans.cancel_period_end'.tr(args: [endsAt]),
    };

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'plans.cancel_title'.tr(),
      message: message,
      confirmLabel: 'plans.cancel_confirm'.tr(),
      cancelLabel: 'plans.cancel_keep'.tr(),
      danger: true,
      onConfirm: () async => cubit.cancel(),
    );
    if (!confirmed) return;

    AppToast.success(
      options.cancelMode == CancelMode.periodEnd
          ? 'plans.cancelled_period_end'.tr(args: [endsAt])
          : options.refundAmount > 0
          ? 'plans.cancelled_refund'.tr(args: [refund])
          : 'plans.cancelled'.tr(),
    );
  }

  /// Montées possibles, au prix réduit des jours restants.
  Future<void> _showChangePlan(SubscriptionPlansLoaded state) async {
    final offers = state.plans
        .where((plan) => state.options.upgrades.containsKey(plan.id))
        .toList();
    final chosen = await showAppSheet<SubscriptionPlanModel>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'plans.change_title'.tr(),
        description: 'plans.change_body'.tr(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final plan in offers)
              AppSheetAction(
                icon: LucideIcons.circleArrowUp,
                label: 'plans.upgrade_to'.tr(args: [plan.name]),
                description: 'plans.upgrade_price'.tr(
                  args: [
                    CurrencyFormatter.fcfa(state.options.upgrades[plan.id]!),
                    CurrencyFormatter.fcfa(plan.price),
                  ],
                ),
                onTap: () => Navigator.of(sheetContext).pop(plan),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await _pay(chosen);
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
              onCancel: () => _confirmCancel(state.options),
              onChangePlan: () => _showChangePlan(state),
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
    required this.onCancel,
    required this.onChangePlan,
  });

  final SubscriptionPlansLoaded state;
  final ValueChanged<SubscriptionPlanModel> onPay;
  final VoidCallback onVerify;
  final VoidCallback onCancel;
  final VoidCallback onChangePlan;

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
            if (state.options.credit case final credit?) ...[
              const SizedBox(height: 12),
              _Notice.info(
                'plans.credit_available'.tr(
                  args: [
                    CurrencyFormatter.fcfa(credit.amount),
                    credit.expiresAt == null
                        ? ''
                        : DateFormat(
                            'd MMMM y',
                          ).format(credit.expiresAt!.toLocal()),
                  ],
                ),
              ),
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
            // Même chose pour RESI Basic : il ne se paie pas, mais le
            // propriétaire doit voir où il en est avant de choisir.
            if (current == PlanStyle.free) ...[
              const _FreeCard(),
              const SizedBox(height: 12),
            ],

            if (state.plans.isEmpty)
              _Notice.info('subscription.empty'.tr())
            else
              for (final offer in state.plans) ...[
                _PlanCard(
                  plan: offer,
                  isCurrent: current == PlanStyle.of(offer.access),
                  isPaying: state.payingPlanId == offer.id,
                  options: state.options,
                  isCancelling: state.isCancelling,
                  onPay: state.payingPlanId == null ? () => onPay(offer) : null,
                  onCancel: onCancel,
                  onChangePlan: onChangePlan,
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
    required this.options,
    required this.isCancelling,
    required this.onPay,
    required this.onCancel,
    required this.onChangePlan,
  });

  final SubscriptionPlanModel plan;
  final bool isCurrent;
  final bool isPaying;
  final SubscriptionOptionsModel options;
  final bool isCancelling;
  final VoidCallback? onPay;
  final VoidCallback onCancel;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context) {
    final style = PlanStyle.of(plan.access) ?? PlanStyle.pro;
    final isRecommended = plan.access == PlanAccess.proPlus;
    // Forfait en cours ou recommandé : filet `primary`, comme toute option
    // mise en avant.
    final highlight = isCurrent || isRecommended;
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.md,
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
              else if (isRecommended)
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
          ..._actions(highlight),
        ],
      ),
    );
  }

  /// Boutons de la carte, selon le forfait en cours.
  ///
  /// - Forfait en cours et payé : « Changer de forfait » et « Résilier » ;
  ///   « Renouveler » s'y ajoute 7 jours avant l'échéance seulement — plus
  ///   tôt, le serveur refuserait, et le renouvellement n'a pas à être
  ///   proposé au lendemain d'un paiement.
  /// - Autre forfait, pendant un forfait payé : une montée chiffrée, ou un
  ///   palier inférieur, qui attend l'échéance.
  /// - Sinon : payer.
  List<Widget> _actions(bool highlight) {
    // Le forfait mis en avant garde le bouton noir ; l'autre passe en
    // secondaire, pour qu'un seul appel à l'action domine l'écran.
    final variant = highlight
        ? AppButtonVariant.primary
        : AppButtonVariant.secondary;
    // Un forfait résilié à l'échéance court encore : ses cartes gardent les
    // règles d'un forfait payé, sans le bouton de résiliation.
    final paidPlanRunning = options.hasPaidPlan;

    if (isCurrent && paidPlanRunning) {
      return [
        if (options.renewable) ...[
          AppButton(
            label: 'plans.renew'.tr(),
            icon: LucideIcons.refreshCw,
            expand: true,
            isLoading: isPaying,
            onPressed: onPay,
          ),
          const SizedBox(height: 8),
        ],
        if (options.upgrades.isNotEmpty) ...[
          AppButton(
            label: 'plans.change_plan'.tr(),
            icon: LucideIcons.circleArrowUp,
            variant: options.renewable
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            expand: true,
            onPressed: onChangePlan,
          ),
          const SizedBox(height: 8),
        ],
        if (options.cancelScheduled)
          AppCallout(
            icon: LucideIcons.calendarX,
            tone: AppAccent.amber,
            message: 'plans.cancel_scheduled'.tr(
              args: [
                options.accessEndsAt == null
                    ? ''
                    : DateFormat(
                        'd MMMM y',
                      ).format(options.accessEndsAt!.toLocal()),
              ],
            ),
          )
        else
          AppButton(
            label: 'plans.cancel_plan'.tr(),
            icon: LucideIcons.circleX,
            variant: AppButtonVariant.ghost,
            expand: true,
            isLoading: isCancelling,
            onPressed: isCancelling ? null : onCancel,
          ),
      ];
    }

    if (!isCurrent && paidPlanRunning) {
      final upgradeAmount = options.upgrades[plan.id];
      if (upgradeAmount == null) {
        return [
          AppButton(
            label: 'plans.at_renewal'.tr(),
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: null,
          ),
        ];
      }
      return [
        AppButton(
          label: 'plans.upgrade_for'.tr(
            args: [CurrencyFormatter.fcfa(upgradeAmount)],
          ),
          icon: LucideIcons.circleArrowUp,
          variant: variant,
          expand: true,
          isLoading: isPaying,
          onPressed: onPay,
        ),
      ];
    }

    return [
      AppButton(
        label: (isCurrent ? 'plans.renew' : 'subscription.pay').tr(),
        variant: variant,
        expand: true,
        isLoading: isPaying,
        onPressed: onPay,
      ),
    ];
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

/// RESI Basic en cours, présenté comme un forfait : gratuit, sans bouton.
class _FreeCard extends StatelessWidget {
  const _FreeCard();

  @override
  Widget build(BuildContext context) {
    const style = PlanStyle.free;

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
              PlanChip(label: 'plans.current'.tr(), accent: style.accent),
            ],
          ),
          const SizedBox(height: 14),
          // Les lignes de l'offre RESI Basic, dans son ordre. Pro et Pro+
          // tiennent les leurs du plan servi par l'API (`node ace plans:sync`).
          for (final key in const [
            'plans.free_bookings',
            'plans.free_dashboard',
            'plans.free_revenue',
            'plans.free_occupancy',
            'plans.free_wallet',
          ])
            _FeatureLine(text: key.tr(), color: style.colorOf(context)),
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

/// Détail d'un paiement d'abonnement : prix, crédit déduit, frais Wave, total,
/// puis les conditions de résiliation — à lire avant de payer.
class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.quote});

  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailList(
          items: [
            DetailItem(
              'plans.pay_price'.tr(),
              CurrencyFormatter.fcfa(quote.price),
            ),
            if (quote.credit > 0)
              DetailItem(
                'plans.pay_credit'.tr(),
                '− ${CurrencyFormatter.fcfa(quote.credit)}',
              ),
            DetailItem('plans.pay_fee'.tr(), CurrencyFormatter.fcfa(quote.fee)),
            DetailItem(
              'plans.pay_total'.tr(),
              CurrencyFormatter.fcfa(quote.total),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCallout(
          icon: LucideIcons.info,
          tone: AppAccent.neutral,
          message: 'plans.pay_conditions'.tr(),
        ),
      ],
    );
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
