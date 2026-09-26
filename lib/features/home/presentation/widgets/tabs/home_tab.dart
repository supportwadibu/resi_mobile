import 'package:flutter/material.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../shared/widgets/app_sheet.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../feedback/presentation/widgets/feedback_sheet.dart';
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
      // 88 en bas : le bouton « + » flotte au-dessus du dernier bloc.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
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
          const SizedBox(height: 24),
          // L'avis sur l'application n'est pas un chiffre : il quitte la
          // grille des tuiles pour une ligne d'action à part.
          AppCard(
            padding: EdgeInsets.zero,
            child: AppSheetAction(
              icon: AppSectionIcons.reviews,
              label: 'Donner mon avis',
              description: 'Une idée, un problème : dites-le à l\'équipe RESI',
              onTap: () => showFeedbackSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}
