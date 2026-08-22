import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../../business_logic/reservation_cubit.dart';
import '../../business_logic/reservation_state.dart';
import '../../data/models/reservation_model.dart';
import '../widgets/sync_status_banner.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeletons/list_skeleton.dart';

@RoutePage()
class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReservationCubit>()..load(),
      child: const _ReservationView(),
    );
  }
}

class _ReservationView extends StatelessWidget {
  const _ReservationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('reservation.title'.tr())),
      body: BlocConsumer<ReservationCubit, ReservationState>(
        listener: (context, state) {
          if (state is ReservationError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => Column(
          children: [
            // Au-dessus de la liste : ce qui n'est pas encore parti doit se
            // voir avant ce qui est confirmé.
            const SyncStatusBanner(),
            Expanded(
              child: switch (state) {
                ReservationInitial() => const SizedBox.shrink(),
                ReservationLoading() => const SimpleListSkeleton(),
                ReservationError() => ErrorState(
                  message: state.message,
                  onRetry: () => context.read<ReservationCubit>().load(),
                ),
                ReservationLoaded() => _ReservationList(items: state.items),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  const _ReservationList({required this.items});
  final List<ReservationModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: 'reservation.empty'.tr());

    return RefreshIndicator(
      onRefresh: () => context.read<ReservationCubit>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        // Le tirer-pour-rafraîchir doit rester possible même quand la liste
        // tient dans l'écran.
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) => ReservationItem(reservation: items[i]),
      ),
    );
  }
}
