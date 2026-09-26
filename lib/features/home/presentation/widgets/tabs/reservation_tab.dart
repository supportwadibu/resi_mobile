import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_state.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import '../reservations/reservation_item.dart';
import '../reservations/reservation_stats_row.dart';
import '../reservations/revenue_card.dart';

class ReservationTab extends StatelessWidget {
  const ReservationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReservationCubit>()..load(),
      child: const _ReservationTabView(),
    );
  }
}

class _ReservationTabView extends StatelessWidget {
  const _ReservationTabView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<ReservationCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            const PageHeader(title: 'Réservations'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Les quatre chiffres portent tous sur le mois en cours :
                  // sans cet intitulé, une tuile de comptage posée à côté
                  // d'un revenu mensuel se lit comme un total de tous les
                  // temps.
                  const SectionHeading(
                    title: 'Ce mois-ci',
                    icon: AppSectionIcons.stats,
                  ),
                  const SizedBox(height: 8),
                  // Les compteurs et le bloc revenus lisent le même état que
                  // la liste : servis séparément, ils pourraient afficher des
                  // chiffres qui contredisent les réservations juste en
                  // dessous.
                  BlocBuilder<ReservationCubit, ReservationState>(
                    builder: (context, state) {
                      final stats = state is ReservationLoaded
                          ? state.stats
                          : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RevenueCard(revenue: stats?.revenue),
                          const SizedBox(height: 8),
                          ReservationStatsRow(stats: stats),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionHeading(
                    title: 'Séjours',
                    icon: AppSectionIcons.bookings,
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<ReservationCubit, ReservationState>(
                    builder: (context, state) => switch (state) {
                      ReservationInitial() ||
                      ReservationLoading() => const PropertyListSkeleton(
                        itemCount: 3,
                        padding: EdgeInsets.zero,
                      ),
                      ReservationError(:final message) => ErrorState(
                        message: message,
                        onRetry: () => context.read<ReservationCubit>().load(),
                      ),
                      ReservationLoaded(:final items) when items.isEmpty =>
                        const AppCard(
                          child: EmptyState(
                            message: 'Aucune réservation pour le moment.',
                            icon: AppSectionIcons.bookings,
                          ),
                        ),
                      ReservationLoaded(:final items) => Column(
                        children: [
                          for (final r in items)
                            ReservationItem(
                              reservation: r,
                              onChanged: () =>
                                  context.read<ReservationCubit>().load(),
                            ),
                        ],
                      ),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
