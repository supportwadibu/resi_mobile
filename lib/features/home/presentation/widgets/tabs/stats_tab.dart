import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/service_locator.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/action_grid.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/kpi_row.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/occupancy_card.dart';
import 'package:resi_africa/features/home/presentation/widgets/stats/stats_header.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_state.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_gate.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_style.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Pas de chargement au forfait 3 000 F : l'API refuserait les trois
      // appels, et les chiffres ne s'affichent pas.
      create: (_) {
        final cubit = sl<DashboardCubit>();
        if (hasFullPlan()) cubit.load();
        return cubit;
      },
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              const PageHeader(title: 'Statistiques'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // L'en-tête reste monté pendant le chargement : le filtre
                    // de période doit rester actionnable, sinon un relevé
                    // vide sur la fenêtre choisie enfermerait le
                    // propriétaire dedans.
                    PlanGate(
                      feature: PremiumFeature.statistics,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          const SizedBox(height: 12),
                          _Indicators(state: state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeading(title: 'Gestion'),
                    const SizedBox(height: 8),
                    const ActionGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final now = DateTime.now();

    return StatsHeader(
      from: cubit.from ?? DateTime(now.year, now.month),
      to: cubit.to ?? now,
      onPeriodPicked: (range) => cubit.filterByPeriod(range.start, range.end),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      DashboardInitial() || DashboardLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: AppLoader()),
      ),
      DashboardError(:final message) => AppCard(
        child: ErrorState(
          message: message,
          onRetry: () => context.read<DashboardCubit>().load(),
        ),
      ),
      DashboardLoaded(:final overview, :final parc) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OccupancyCard(
            occupancyRate: overview.summary.tauxOccupation,
            rented: parc.rented,
            available: parc.available,
          ),
          const SizedBox(height: 12),
          KpiRow(
            entrees: overview.summary.caBrut,
            sorties: overview.summary.depenses,
          ),
        ],
      ),
      // Branche distincte, et non un `DashboardLoaded` aux champs manquants :
      // c'est le type du state qui interdit qu'un bénéfice net atteigne
      // l'écran du gérant, `GerantOverviewModel` n'en portant aucun.
      //
      // La carte d'occupation vient sans compteurs d'unités : ils sortent
      // d'une route propriétaire, et deux zéros s'y liraient comme un parc
      // vide.
      DashboardManagerLoaded(:final overview) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OccupancyCard(occupancyRate: overview.occupancyRate),
          const SizedBox(height: 12),
          KpiRow(
            entrees: overview.grossRevenue,
            sorties: overview.expensesTotal,
          ),
        ],
      ),
    };
  }
}
