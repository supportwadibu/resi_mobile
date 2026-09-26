import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/session/session_role.dart';
import '../../business_logic/plan_cubit.dart';
import '../../business_logic/plan_state.dart';

/// L'accès courant ouvre-t-il le forfait complet ?
bool hasFullPlan() => sl<PlanCubit>().access.isFull;

/// Laisse passer un geste réservé au forfait 5 000 F, ou explique le verrou.
///
/// À appeler avant de naviguer : l'entrée reste visible au forfait 3 000 F —
/// la masquer cacherait au propriétaire ce que le forfait complet apporte —,
/// et l'appui ouvre l'explication plutôt que l'écran, qui ne recevrait de
/// l'API qu'un refus.
bool ensureFullPlan(BuildContext context) {
  if (hasFullPlan()) return true;
  showLockedFeatureSheet(context);
  return false;
}

Future<void> showLockedFeatureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: LockedFeatureCard(
          onSeePlans: () => Navigator.of(sheetContext).pop(),
          flat: true,
        ),
      ),
    ),
  );
}

/// Rend [child] au forfait complet, et l'encart de verrou sinon.
///
/// Écoute le `PlanCubit` : un refus de l'API reçu ailleurs bascule l'écran
/// sans rechargement.
class PlanGate extends StatelessWidget {
  const PlanGate({required this.child, this.locked, super.key});

  final Widget child;

  /// Remplaçant au forfait 3 000 F. Par défaut, l'encart de verrou.
  final Widget? locked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanCubit, PlanState>(
      bloc: sl<PlanCubit>(),
      builder: (context, state) =>
          state.access.isFull ? child : (locked ?? const LockedFeatureCard()),
    );
  }
}

/// Encart « Réservé au forfait 5 000 F », avec l'accès aux forfaits.
class LockedFeatureCard extends StatelessWidget {
  const LockedFeatureCard({this.onSeePlans, this.flat = false, super.key});

  /// Appelé avant la navigation — pour fermer une feuille, par exemple.
  final VoidCallback? onSeePlans;

  /// Sans fond ni bordure, quand l'encart est déjà dans une feuille.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Le gérant ne souscrit pas : c'est l'abonnement du propriétaire qui
    // compte, et le lui proposer le mènerait à un écran qui lui est fermé.
    final canSubscribe = sl<SessionRole>().value != 'gerant';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, size: 32, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'locked.title'.tr(),
          textAlign: TextAlign.center,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'locked.body'.tr(),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (canSubscribe) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              onSeePlans?.call();
              context.router.push(SubscriptionPlansRoute());
            },
            child: Text('locked.see_plans'.tr()),
          ),
        ],
      ],
    );

    if (flat) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: content,
    );
  }
}

/// Bandeau compact du verrou, pour une surface où l'encart prendrait trop de
/// place — la rangée de chiffres de l'accueil.
class LockedFeatureBanner extends StatelessWidget {
  const LockedFeatureBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSubscribe = sl<SessionRole>().value != 'gerant';

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canSubscribe
            ? () => context.router.push(SubscriptionPlansRoute())
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'locked.title'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (canSubscribe)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
