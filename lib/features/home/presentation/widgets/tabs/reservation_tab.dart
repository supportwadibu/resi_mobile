import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_state.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
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
      create: (_) =>
          sl<ReservationCubit>(param1: ReservationListOptions.recent)..load(),
      child: const _ReservationTabView(),
    );
  }
}

class _ReservationTabView extends StatelessWidget {
  const _ReservationTabView();

  /// Ouvre la liste complète, puis relit l'aperçu au retour : une réservation
  /// prolongée ou close depuis là-bas changerait sinon les chiffres du mois
  /// sans que l'onglet le montre.
  Future<void> _openAll(BuildContext context) async {
    final cubit = context.read<ReservationCubit>();
    await context.router.push(const ReservationRoute());
    if (!cubit.isClosed) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<ReservationCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Marge basse : hauteur de la barre flottante, voir `HomeTab`.
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          children: [
            PageHeader(title: 'home.bookings_title'.tr()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Les quatre chiffres portent tous sur le mois en cours :
                  // sans cet intitulé, une tuile de comptage posée à côté
                  // d'un revenu mensuel se lit comme un total de tous les
                  // temps.
                  SectionHeading(
                    title: 'common.this_month'.tr(),
                    icon: AppSectionIcons.stats,
                  ),
                  const SizedBox(height: 8),
                  // Les compteurs et le bloc revenus lisent le même état que
                  // la liste : servis séparément, ils pourraient afficher des
                  // chiffres qui contredisent les réservations juste en
                  // dessous.
                  BlocBuilder<ReservationCubit, ReservationState>(
                    builder: (context, state) {
                      final stats = switch (state) {
                        ReservationLoaded(:final stats) => stats,
                        ReservationLoading(:final stats) => stats,
                        _ => null,
                      };
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
                  SectionHeading(
                    title: 'reservation.recent'.tr(),
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
                        AppCard(
                          child: EmptyState(
                            message: 'reservation.empty'.tr(),
                            icon: AppSectionIcons.bookings,
                          ),
                        ),
                      ReservationLoaded(:final items, :final total) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final r in items)
                            ReservationItem(
                              reservation: r,
                              onChanged: () =>
                                  context.read<ReservationCubit>().load(),
                            ),
                          const SizedBox(height: 4),
                          // Offert même sous cinq réservations : c'est là que
                          // vivent les filtres par statut et la recherche.
                          AppButton(
                            label: 'reservation.see_all'.tr(args: ['$total']),
                            icon: LucideIcons.list,
                            variant: AppButtonVariant.secondary,
                            expand: true,
                            onPressed: () => _openAll(context),
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
