import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../reservation/business_logic/reservation_cubit.dart';
import '../../../../reservation/business_logic/reservation_state.dart';
import '../reservations/reservation_item.dart';

/// Réservations d'un bien, sur sa fiche : les séjours passés, en cours et à
/// venir de ce seul logement, sans passer par l'onglet et ses filtres.
///
/// Les lignes sont les cartes de l'onglet Réservations, elles-mêmes bordées :
/// un simple intitulé les précède, sans `Section` qui les encadrerait deux
/// fois.
class PropertyReservationsSection extends StatelessWidget {
  const PropertyReservationsSection({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReservationCubit>(
        param1: ReservationListOptions(propertyId: propertyId),
      )..load(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(
            title: 'property_reservations.title'.tr(),
            icon: AppSectionIcons.bookings,
          ),
          const SizedBox(height: 8),
          BlocBuilder<ReservationCubit, ReservationState>(
            builder: (context, state) => switch (state) {
              ReservationInitial() ||
              ReservationLoading() => const PropertyListSkeleton(
                itemCount: 2,
                padding: EdgeInsets.zero,
              ),
              ReservationError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<ReservationCubit>().load(),
              ),
              ReservationLoaded(:final items) when items.isEmpty => AppCard(
                child: EmptyState(
                  message: 'property_reservations.empty'.tr(),
                  icon: AppSectionIcons.bookings,
                ),
              ),
              ReservationLoaded(:final items) => Column(
                children: [
                  for (final r in items)
                    ReservationItem(
                      reservation: r,
                      onChanged: () => context.read<ReservationCubit>().load(),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}
