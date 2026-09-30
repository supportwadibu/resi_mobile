import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/router/app_router.gr.dart';
import '../../../../../core/router/role_guard.dart';
import '../../../../../core/session/session_role.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../subscription/business_logic/plan_cubit.dart';
import '../../../../subscription/business_logic/plan_state.dart';
import '../../../../subscription/presentation/widgets/plan_gate.dart';

import '../../../../subscription/presentation/widgets/plan_style.dart';

/// Entrées réservées au forfait Premium, et la fonction que chacune ouvre.
/// Les résidences restent ouvertes : leur enregistrement fait partie de Pro.
const _premiumActions = <String, PremiumFeature>{
  'expenses': PremiumFeature.expenses,
  'finance': PremiumFeature.finance,
  'reports': PremiumFeature.reports,
  'clients': PremiumFeature.clients,
};

/// Accès aux écrans de gestion, en cartes deux par ligne : chaque entrée porte
/// l'icône de sa section et une ligne d'explication.
///
/// Pastilles neutres, sans accent : une grille de pavés colorés faisait d'une
/// simple navigation une série de statistiques.
class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  static const _actions = [
    StatsAction(
      key: 'expenses',
      icon: AppSectionIcons.expenses,
      label: 'Dépenses',
      description: 'Charges par bien et par catégorie',
      route: ExpenseRoute(),
    ),
    StatsAction(
      key: 'finance',
      icon: LucideIcons.scale,
      label: 'Finances',
      description: 'Revenus, charges et bénéfice',
      route: FinanceRoute(),
    ),
    StatsAction(
      key: 'reports',
      icon: AppSectionIcons.reports,
      label: 'Rapports PDF',
      description: 'Relevés à partager ou imprimer',
      route: ReportRoute(),
    ),
    StatsAction(
      key: 'clients',
      icon: AppSectionIcons.clients,
      label: 'Clients',
      description: 'Carnet et historique des séjours',
      route: ClientsRoute(),
    ),
    StatsAction(
      key: 'residences',
      icon: AppSectionIcons.residences,
      label: 'Résidences',
      description: 'Regrouper les logements d\'un immeuble',
      route: ResidenceRoute(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Le rôle se lit sur la session, comme partout ailleurs dans le projet :
    // l'état de l'`AuthCubit` ne le porte pas, et il doit rester lisible sans
    // reconnexion après un redémarrage.
    final role = sl<SessionRole>().value;
    final visible = actionsForRole(role, _actions.map((a) => a.key).toList());
    final actions = _actions.where((a) => visible.contains(a.key)).toList();

    return BlocBuilder<PlanCubit, PlanState>(
      bloc: sl<PlanCubit>(),
      builder: (context, plan) {
        Widget card(StatsAction action) => ActionCard(
          action: action,
          locked: plan.access.isFull ? null : _premiumActions[action.key],
        );

        return Column(
          children: [
            for (var i = 0; i < actions.length; i += 2) ...[
              if (i > 0) const SizedBox(height: _gap),
              // Même hauteur pour les deux cartes d'une rangée : une
              // description plus longue d'un côté décalait sinon les bords.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card(actions[i])),
                    const SizedBox(width: _gap),
                    // Une entrée seule garde la demi-largeur : étirée, elle
                    // romprait la grille.
                    Expanded(
                      child: i + 1 < actions.length
                          ? card(actions[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static const _gap = 12.0;
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.action, this.locked});
  final StatsAction action;

  /// Fonction Premium que l'entrée ouvre, `null` si elle est accessible :
  /// l'appui explique alors le verrou au lieu d'ouvrir un écran que l'API
  /// refuserait.
  final PremiumFeature? locked;

  void _open(BuildContext context) {
    if (locked case final feature?) {
      showLockedFeatureSheet(context, feature);
      return;
    }
    if (action.route != null) {
      context.pushRoute(action.route!);
    } else {
      AppToast.info('Bientôt disponible', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(icon: action.icon),
              const Spacer(),
              if (locked != null)
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topRight,
                    child: PremiumBadge(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            action.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class StatsAction {
  const StatsAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.description,
    this.route,
  });

  /// Identifiant stable, indépendant du libellé affiché : c'est lui que le
  /// filtrage par rôle regarde.
  final String key;

  final IconData icon;
  final String label;
  final String description;
  final PageRouteInfo? route;
}
