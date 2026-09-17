import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/router/app_router.gr.dart';
import '../../../../../core/router/role_guard.dart';
import '../../../../../core/session/session_role.dart';

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  static const _actions = [
    StatsAction(
      key: 'expenses',
      icon: FontAwesomeIcons.moneyBillWave,
      label: 'Gestion des dépenses',
      color: Color(0xFFF59E0B),
      route: ExpenseRoute(),
    ),
    StatsAction(
      key: 'finance',
      icon: FontAwesomeIcons.scaleBalanced,
      label: 'Gestion financière',
      color: Color(0xFF3322AC),
      route: FinanceRoute(),
    ),
    StatsAction(
      key: 'reports',
      icon: FontAwesomeIcons.fileInvoice,
      label: 'Rapports PDF',
      color: Color(0xFFEF4444),
      route: ReportRoute(),
    ),
    StatsAction(
      key: 'clients',
      icon: FontAwesomeIcons.users,
      label: 'Gestion des clients',
      color: Color(0xFF0EA5E9),
      route: ClientsRoute(),
    ),
    StatsAction(
      key: 'residences',
      icon: FontAwesomeIcons.building,
      label: 'Mes résidences',
      color: Color(0xFF10B981),
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: actions.map((a) => ActionCard(action: a)).toList(),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.action});
  final StatsAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (action.route != null) {
          context.pushRoute(action.route!);
        } else {
          AppToast.info('Bientôt disponible', context: context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(action.icon, size: 16, color: action.color),
            ),
            Text(
              action.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsAction {
  const StatsAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
    this.route,
  });

  /// Identifiant stable, indépendant du libellé affiché : c'est lui que le
  /// filtrage par rôle regarde.
  final String key;

  final FaIconData icon;
  final String label;
  final Color color;
  final PageRouteInfo? route;
}
