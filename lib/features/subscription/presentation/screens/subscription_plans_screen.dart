import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/session/session_role.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';
import '../../business_logic/subscription_plans_cubit.dart';
import '../../business_logic/subscription_plans_state.dart';
import '../../data/models/plan_access.dart';
import '../../data/models/subscription_plan_model.dart';

/// Choix d'un forfait et paiement Wave.
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
    final messenger = ScaffoldMessenger.of(context);
    final url = await context.read<SubscriptionPlansCubit>().pay(plan);
    if (url == null) return;

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text('subscription.wave_unavailable'.tr())),
      );
    }
  }

  void _continue() => context.router.replaceAll([const HomeRoute()]);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.blocking,
      child: Scaffold(
        appBar: AppBar(
          title: Text('subscription.title'.tr()),
          automaticallyImplyLeading: !widget.blocking,
          actions: [
            if (widget.blocking)
              TextButton(
                onPressed: () => _logout(context),
                child: Text('subscription.logout'.tr()),
              ),
          ],
        ),
        body: BlocConsumer<SubscriptionPlansCubit, SubscriptionPlansState>(
          listenWhen: (previous, current) =>
              current is SubscriptionPlansLoaded &&
              current.outcome == CheckoutOutcome.paid &&
              (previous is! SubscriptionPlansLoaded ||
                  previous.outcome != CheckoutOutcome.paid),
          listener: (context, state) => _continue(),
          builder: (context, state) => switch (state) {
            SubscriptionPlansInitial() || SubscriptionPlansLoading() =>
              const Center(child: CircularProgressIndicator()),
            SubscriptionPlansError(:final message) => _ErrorView(
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<PlanCubit, PlanState>(
      bloc: sl<PlanCubit>(),
      builder: (context, plan) {
        final access = plan.access;
        final days = plan is PlanKnown ? plan.daysRemaining : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              switch (access) {
                PlanAccess.inactive => 'subscription.inactive_title'.tr(),
                _ => 'subscription.upgrade_title'.tr(),
              },
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              switch (access) {
                PlanAccess.inactive => 'subscription.inactive_body'.tr(),
                _ when days != null && days <= 7 =>
                  'subscription.renew_body'.tr(args: ['$days']),
                _ => 'subscription.upgrade_body'.tr(),
              },
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (state.message != null) ...[
              _Notice(message: state.message!, isError: true),
              const SizedBox(height: 12),
            ],
            if (state.outcome == CheckoutOutcome.waiting) ...[
              _Notice(message: 'subscription.waiting'.tr()),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onVerify,
                child: Text('subscription.verify'.tr()),
              ),
              const SizedBox(height: 12),
            ],
            if (state.outcome == CheckoutOutcome.failed) ...[
              _Notice(message: 'subscription.failed'.tr(), isError: true),
              const SizedBox(height: 12),
            ],
            if (state.plans.isEmpty)
              Text('subscription.empty'.tr(), style: text.bodyMedium)
            else
              for (final plan in state.plans) ...[
                _PlanCard(
                  plan: plan,
                  isCurrent:
                      access != PlanAccess.inactive &&
                      plan.isFull == access.isFull,
                  isPaying: state.payingPlanId == plan.id,
                  onPay: state.payingPlanId == null ? () => onPay(plan) : null,
                ),
                const SizedBox(height: 14),
              ],
          ],
        );
      },
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Contenu fixe du palier, et non les seules lignes saisies par
    // l'administrateur : la différence entre les deux forfaits doit se lire
    // même sur un plan dont la présentation n'a pas été renseignée.
    final includes =
        (plan.isFull
                ? 'subscription.includes_full'
                : 'subscription.includes_basic')
            .tr()
            .split('\n');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isFull ? scheme.primary : scheme.outlineVariant,
          width: plan.isFull ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCurrent)
                Chip(
                  label: Text('subscription.current'.tr()),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'subscription.per_period'.tr(
              args: [
                CurrencyFormatter.short(plan.price),
                '${plan.durationDays}',
              ],
            ),
            style: text.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.description,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          for (final line in includes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPay,
              child: isPaying
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text('subscription.pay'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? scheme.onErrorContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gérant d'un propriétaire inactif ou au forfait 3 000 F.
class _ManagerBlockedView extends StatelessWidget {
  const _ManagerBlockedView({required this.blocking});

  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: !blocking,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: !blocking),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  'subscription.gerant_title'.tr(),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'subscription.gerant_body'.tr(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () =>
                      context.router.replaceAll([const HomeRoute()]),
                  child: Text('common.retry'.tr()),
                ),
                TextButton(
                  onPressed: () => _logout(context),
                  child: Text('subscription.logout'.tr()),
                ),
              ],
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
