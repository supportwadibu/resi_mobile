import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../../core/router/app_router.gr.dart';

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  static const _actions = [
    StatsAction(
      icon: FontAwesomeIcons.moneyBillWave,
      label: 'Gestion des dépenses',
      color: Color(0xFFF59E0B),
      route: ExpenseRoute(),
    ),
    StatsAction(
      icon: FontAwesomeIcons.scaleBalanced,
      label: 'Gestion financière',
      color: Color(0xFF3322AC),
      route: FinanceRoute(),
    ),
    StatsAction(
      icon: FontAwesomeIcons.fileInvoice,
      label: 'Rapports PDF',
      color: Color(0xFFEF4444),
      route: ReportRoute(),
    ),
    StatsAction(
      icon: FontAwesomeIcons.users,
      label: 'Gestion des clients',
      color: Color(0xFF0EA5E9),
      route: ClientsRoute(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: _actions.map((a) => ActionCard(action: a)).toList(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bientôt disponible'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
    required this.icon,
    required this.label,
    required this.color,
    this.route,
  });

  final FaIconData icon;
  final String label;
  final Color color;
  final PageRouteInfo? route;
}
