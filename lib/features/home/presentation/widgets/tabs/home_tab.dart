import 'package:flutter/material.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../home/header_propertys_widget.dart';
import '../home/property_grid_widget.dart';
import '../home/stats_row_widget.dart';
import '../home/top_bar_widget.dart';
import '../../../../subscription/presentation/widgets/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_style.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.onSeeAllProperties});

  final VoidCallback? onSeeAllProperties;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // La barre des onglets flotte au-dessus du dernier bloc : l'accueil en
      // `extendBody` reporte sa hauteur dans la marge basse.
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TopBarWidget(),
          const SizedBox(height: 20),
          const SectionHeading(title: 'Ce mois-ci', icon: AppSectionIcons.home),
          const SizedBox(height: 8),
          // Parc, séjours du mois et bénéfice sont des statistiques : forfait
          // complet seulement.
          const PlanGate(
            feature: PremiumFeature.statistics,
            compact: true,
            child: StatsRowWidget(),
          ),
          const SizedBox(height: 24),
          HeaderPropertyWidget(onSeeAll: onSeeAllProperties),
          const SizedBox(height: 8),
          const PropertyGridWidget(),
        ],
      ),
    );
  }
}
