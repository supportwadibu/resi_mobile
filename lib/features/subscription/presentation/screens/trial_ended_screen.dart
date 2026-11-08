import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_logo.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/plan_access.dart';
import '../widgets/plan_feature_line.dart';
import '../widgets/plan_style.dart';

/// Fin de l'essai gratuit : continuer avec le forfait essayé, ou en changer.
///
/// Après un essai Pro, l'écran met en avant ce que Pro+ ajoute ; après un
/// essai Pro+, il propose de rester sur Pro+ ou de passer à Pro. Chaque choix
/// mène à l'écran des forfaits, le forfait visé mis en avant : la durée et le
/// paiement Wave s'y choisissent. Affiché une fois par appareil.
@RoutePage()
class TrialEndedScreen extends StatefulWidget {
  const TrialEndedScreen({required this.tier, super.key});

  /// Forfait essayé : RESI Pro ou RESI Pro+.
  final PlanAccess tier;

  @override
  State<TrialEndedScreen> createState() => _TrialEndedScreenState();
}

class _TrialEndedScreenState extends State<TrialEndedScreen> {
  @override
  void initState() {
    super.initState();
    sl<LocalStorage>().markTrialEndedSeen();
  }

  void _goToPlans(PlanAccess focus) {
    context.router.replace(SubscriptionPlansRoute(focus: focus));
  }

  @override
  Widget build(BuildContext context) {
    final triedPro = widget.tier == PlanAccess.pro;
    final tried = PlanStyle.of(widget.tier) ?? PlanStyle.proPlus;
    final other = triedPro ? PlanStyle.proPlus : PlanStyle.pro;

    return Scaffold(
      body: SafeArea(
        child: Center(
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
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PlanIconBadge(style: tried, size: 56),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'trial.ended_title'.tr(args: [tried.label]),
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    triedPro
                        ? 'trial.ended_body_pro'.tr()
                        : 'trial.ended_body_pro_plus'.tr(),
                    style: context.mutedText.copyWith(height: 1.5),
                  ),
                  // Ce que Pro+ ajoute à Pro : la raison de monter.
                  if (triedPro) ...[
                    const SizedBox(height: 16),
                    for (final key in const [
                      'trial.extra_managers',
                      'trial.extra_invoices',
                      'trial.extra_reports',
                    ])
                      PlanFeatureLine(
                        text: key.tr(),
                        color: other.colorOf(context),
                      ),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'trial.continue_with'.tr(args: [tried.label]),
                    onPressed: () => _goToPlans(widget.tier),
                    expand: true,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: triedPro
                        ? 'trial.discover_pro_plus'.tr()
                        : 'trial.switch_to'.tr(args: [other.label]),
                    icon: other.icon,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _goToPlans(
                      triedPro ? PlanAccess.proPlus : PlanAccess.pro,
                    ),
                    expand: true,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'trial.stay_free'.tr(),
                    icon: LucideIcons.house,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.router.maybePop(),
                    expand: true,
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
