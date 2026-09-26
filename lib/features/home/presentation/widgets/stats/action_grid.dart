import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
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

/// Accès aux écrans de gestion, en liste : chaque entrée porte l'icône de sa
/// section et une ligne d'explication. Une grille de pavés colorés faisait
/// d'une simple navigation une série de statistiques.
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
      builder: (context, plan) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ActionCard(
                action: actions[i],
                locked: plan.access.isFull ? null : _premiumActions[actions[i].key],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.action, this.locked});
  final StatsAction action;

  /// Fonction Premium que l'entrée ouvre, `null` si elle est accessible :
  /// l'appui explique alors le verrou au lieu d'ouvrir un écran que l'API
  /// refuserait.
  final PremiumFeature? locked;

  @override
  Widget build(BuildContext context) {
    return AppSheetAction(
      icon: action.icon,
      label: action.label,
      description: action.description,
      trailing: locked != null ? const PremiumBadge() : null,
      onTap: () {
        if (locked case final feature?) {
          showLockedFeatureSheet(context, feature);
          return;
        }
        if (action.route != null) {
          context.pushRoute(action.route!);
        } else {
          AppToast.info('Bientôt disponible', context: context);
        }
      },
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
