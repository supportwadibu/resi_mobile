import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_state.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import '../reservations/reservation_planning.dart';
import '../reservations/reservation_stats_row.dart';
import '../reservations/revenue_card.dart';

/// Onglet Réservations, d'après la maquette « Planning » : le mois en
/// calendrier, les arrivées et départs du jour choisi, puis les chiffres du
/// mois.
class ReservationTab extends StatelessWidget {
  const ReservationTab({super.key});

  /// Une page large : le calendrier place les réservations proches de la
  /// date du jour, les plus récentes d'abord.
  static const _options = ReservationListOptions(perPage: 100, withStats: true);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReservationCubit>(param1: _options)..load(),
      child: const _ReservationTabView(),
    );
  }
}

class _ReservationTabView extends StatelessWidget {
  const _ReservationTabView();

  /// Ouvre la liste complète, puis relit l'onglet au retour : une réservation
  /// prolongée ou close depuis là-bas changerait sinon le planning sans que
  /// l'onglet le montre.
  Future<void> _openAll(BuildContext context) async {
    final cubit = context.read<ReservationCubit>();
    await context.router.push(const ReservationRoute());
    if (!cubit.isClosed) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReservationCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Marge basse : hauteur de la barre flottante, voir `HomeTab`.
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'reservation.planning_title'.tr(),
                        style: context.text.displayMedium!.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'arrival.entry'.tr(),
                      icon: LucideIcons.scanLine,
                      size: AppButtonSize.sm,
                      onPressed: () async {
                        final changed = await context.router.push<bool>(
                          const ArrivalRoute(),
                        );
                        // Une arrivée validée change le statut affiché.
                        if (changed == true) cubit.load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                BlocBuilder<ReservationCubit, ReservationState>(
                  builder: (context, state) => switch (state) {
                    ReservationInitial() ||
                    ReservationLoading() => const PropertyListSkeleton(
                      itemCount: 3,
                      padding: EdgeInsets.zero,
                    ),
                    ReservationError(:final message) => ErrorState(
                      message: message,
                      onRetry: cubit.load,
                    ),
                    ReservationLoaded(:final items) => ReservationPlanning(
                      reservations: items,
                      onChanged: cubit.load,
                    ),
                  },
                ),
                const SizedBox(height: 28),
                // Les compteurs portent tous sur le mois en cours : sans cet
                // intitulé, une tuile de comptage posée à côté d'un revenu
                // mensuel se lit comme un total de tous les temps.
                SectionHeading(
                  title: 'common.this_month'.tr(),
                  icon: AppSectionIcons.stats,
                ),
                const SizedBox(height: 8),
                BlocBuilder<ReservationCubit, ReservationState>(
                  builder: (context, state) {
                    final stats = switch (state) {
                      ReservationLoaded(:final stats) => stats,
                      ReservationLoading(:final stats) => stats,
                      _ => null,
                    };
                    final total = state is ReservationLoaded ? state.total : 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RevenueCard(revenue: stats?.revenue),
                        const SizedBox(height: 8),
                        ReservationStatsRow(stats: stats),
                        const SizedBox(height: 16),
                        // C'est là que vivent les filtres par statut et la
                        // recherche.
                        AppButton(
                          label: 'reservation.see_all'.tr(args: ['$total']),
                          icon: LucideIcons.list,
                          variant: AppButtonVariant.secondary,
                          expand: true,
                          onPressed: () => _openAll(context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
