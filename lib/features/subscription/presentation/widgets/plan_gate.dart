import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/session/session_role.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';
import 'plan_style.dart';

/// Palier de la session, `null` hors conteneur.
///
/// Même garde que `_currentRole` du profil : les tests d'écran montent les vues
/// sans service locator, et un verrou ne doit pas les faire échouer — l'accès
/// complet y est supposé.
PlanCubit? planCubitOrNull() =>
    sl.isRegistered<PlanCubit>() ? sl<PlanCubit>() : null;

/// L'accès courant ouvre-t-il le forfait Premium ?
bool hasFullPlan() => planCubitOrNull()?.access.isFull ?? true;

/// Le gérant ne souscrit pas : c'est l'abonnement de son propriétaire qui
/// compte, et lui proposer les forfaits le mènerait à un écran fermé.
bool _canSubscribe() =>
    !sl.isRegistered<SessionRole>() || sl<SessionRole>().value != 'gerant';

/// Laisse passer un geste Premium, ou explique le verrou.
///
/// À appeler avant de naviguer : l'entrée reste visible au forfait Pro — la
/// masquer cacherait ce que Premium apporte —, et l'appui ouvre l'explication
/// plutôt qu'un écran que l'API refuserait.
bool ensureFullPlan(BuildContext context, PremiumFeature feature) {
  if (hasFullPlan()) return true;
  showLockedFeatureSheet(context, feature);
  return false;
}

/// Feuille « Disponible avec Premium », au format des feuilles du projet.
Future<void> showLockedFeatureSheet(
  BuildContext context,
  PremiumFeature feature,
) {
  final canSubscribe = _canSubscribe();

  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => AppSheet(
      title: 'premium.title'.tr(),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: (canSubscribe ? 'premium.see_plans' : 'premium.ok').tr(),
            icon: canSubscribe ? PlanStyle.full.icon : null,
            expand: true,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              if (canSubscribe) context.router.push(SubscriptionPlansRoute());
            },
          ),
          if (canSubscribe) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'premium.later'.tr(),
              variant: AppButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureBadge(feature: feature),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canSubscribe
                  ? '${'premium.body'.tr(args: [feature.title])} ${feature.body}'
                  : 'premium.manager_body'.tr(),
              style: context.mutedText.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Poignée des feuilles du projet. Les feuilles ouvertes par `showAppSheet`
/// portent déjà la leur (`bottomSheetTheme`) ; celle-ci sert aux feuilles
/// dessinées à la main.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 32, height: 4, color: context.tokens.border);
  }
}

/// Rend [child] au forfait Premium, et l'encart de verrou sinon.
///
/// Écoute le `PlanCubit` : un refus de l'API reçu ailleurs bascule l'écran
/// sans rechargement.
class PlanGate extends StatelessWidget {
  const PlanGate({
    required this.feature,
    required this.child,
    this.compact = false,
    super.key,
  });

  final PremiumFeature feature;
  final Widget child;

  /// Bandeau d'une ligne plutôt qu'encart : pour une surface où l'encart
  /// prendrait trop de place, comme la rangée de chiffres de l'accueil.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final plan = planCubitOrNull();
    if (plan == null) return child;

    return BlocBuilder<PlanCubit, PlanState>(
      bloc: plan,
      builder: (context, state) {
        if (state.access.isFull) return child;
        return compact
            ? LockedFeatureBanner(feature: feature)
            : LockedFeatureCard(feature: feature);
      },
    );
  }
}

/// Encart d'une fonction Premium, à la place de son contenu.
class LockedFeatureCard extends StatelessWidget {
  const LockedFeatureCard({required this.feature, super.key});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final canSubscribe = _canSubscribe();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _FeatureBadge(feature: feature),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(feature.title, style: context.text.titleMedium),
              ),
              const SizedBox(width: 8),
              const PremiumBadge(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canSubscribe ? feature.body : 'premium.manager_body'.tr(),
            textAlign: TextAlign.center,
            style: context.mutedText.copyWith(height: 1.5),
          ),
          if (canSubscribe) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'premium.see_plans'.tr(),
              icon: PlanStyle.full.icon,
              onPressed: () => context.router.push(SubscriptionPlansRoute()),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bandeau d'une ligne d'une fonction Premium.
class LockedFeatureBanner extends StatelessWidget {
  const LockedFeatureBanner({required this.feature, super.key});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showLockedFeatureSheet(context, feature),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _FeatureBadge(feature: feature, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const PremiumBadge(),
        ],
      ),
    );
  }
}

/// Pastille de la fonction, au ton du forfait qui l'ouvre.
class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.feature, this.size = 48});

  final PremiumFeature feature;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconChip(
      icon: feature.icon,
      accent: PlanStyle.full.accent,
      size: size,
    );
  }
}
