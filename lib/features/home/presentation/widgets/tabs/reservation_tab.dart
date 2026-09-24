import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<ReservationCubit>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes réservations',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Les compteurs et le bloc revenus lisent le même état que la
                // liste : servis séparément, ils pourraient afficher des
                // chiffres qui contredisent les réservations juste en dessous.
                BlocBuilder<ReservationCubit, ReservationState>(
                  builder: (context, state) {
                    final stats = state is ReservationLoaded
                        ? state.stats
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Les quatre chiffres portent tous sur le mois en
                        // cours : sans cet intitulé, une tuile de comptage
                        // posée à côté d'un revenu mensuel se lit comme un
                        // total de tous les temps.
                        Text(
                          'Ce mois-ci',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ReservationStatsRow(stats: stats),
                        const SizedBox(height: 24),
                        RevenueCard(revenue: stats?.revenue),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'En cours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                BlocBuilder<ReservationCubit, ReservationState>(
                  builder: (context, state) => switch (state) {
                    ReservationInitial() ||
                    ReservationLoading() => const PropertyListSkeleton(
                      itemCount: 3,
                      padding: EdgeInsets.zero,
                    ),
                    ReservationError(:final message) => _Notice(
                      message: message,
                    ),
                    ReservationLoaded(:final items) when items.isEmpty =>
                      const _Notice(
                        message: 'Aucune réservation pour le moment.',
                      ),
                    ReservationLoaded(:final items) => Column(
                      children: items
                          .map(
                            (r) => ReservationItem(
                              reservation: r,
                              onChanged: () =>
                                  context.read<ReservationCubit>().load(),
                            ),
                          )
                          .toList(),
                    ),
                  },
                ),

                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Message discret tenant la place de la liste.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grey500),
        ),
      ),
    );
  }
}
