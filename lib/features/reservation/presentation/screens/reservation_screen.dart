import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

import '../../../../core/di/service_locator.dart';
import '../../../home/presentation/widgets/reservations/reservation_filters.dart';
import '../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../../business_logic/reservation_cubit.dart';
import '../../business_logic/reservation_state.dart';
import '../widgets/sync_status_banner.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeletons/list_skeleton.dart';

/// Toutes les réservations, paginées, avec les filtres par statut et la
/// recherche client. L'onglet n'en montre que les cinq plus récentes.
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
      appBar: AppTopBar(title: 'reservation.title'.tr()),
      body: BlocListener<ReservationCubit, ReservationState>(
        // Un échec de page suivante laisse la liste en place : seul un
        // message le signale.
        listenWhen: (previous, current) =>
            current is ReservationLoaded &&
            current.loadMoreError != null &&
            (previous is! ReservationLoaded ||
                previous.loadMoreError != current.loadMoreError),
        listener: (context, state) => AppToast.error(
          (state as ReservationLoaded).loadMoreError!,
          context: context,
        ),
        child: const Column(
          children: [
            // Au-dessus de la liste : ce qui n'est pas encore parti doit se
            // voir avant ce qui est confirmé.
            SyncStatusBanner(),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ReservationFilters(),
            ),
            Expanded(child: _ReservationList()),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends StatefulWidget {
  const _ReservationList();

  @override
  State<_ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<_ReservationList> {
  final _scroll = ScrollController();

  /// Distance au bas de la liste à partir de laquelle la page suivante est
  /// demandée : assez tôt pour que le réseau réponde avant que le pouce
  /// n'atteigne la fin.
  static const _prefetchExtent = 400.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < _prefetchExtent) {
      context.read<ReservationCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReservationCubit>();
    return BlocBuilder<ReservationCubit, ReservationState>(
      builder: (context, state) => switch (state) {
        ReservationInitial() => const SizedBox.shrink(),
        ReservationLoading() => const SimpleListSkeleton(),
        ReservationError(:final message) => ErrorState(
          message: message,
          onRetry: cubit.load,
        ),
        ReservationLoaded() => RefreshIndicator(
          onRefresh: cubit.load,
          child: _list(context, state),
        ),
      },
    );
  }

  Widget _list(BuildContext context, ReservationLoaded state) {
    final cubit = context.read<ReservationCubit>();
    final items = state.visibleItems;
    final filtered = state.query.trim().isNotEmpty || cubit.status != null;

    // Rien d'affiché mais des pages restent : la recherche porte sur les
    // pages chargées, et la suite peut contenir le client cherché.
    if (items.isEmpty && !state.hasMore) {
      return ListView(
        // Le tirer-pour-rafraîchir doit rester possible sur une liste vide.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            message: filtered
                ? 'reservation_filters.no_match'.tr()
                : 'reservation.empty'.tr(),
            icon: AppSectionIcons.bookings,
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      // Le tirer-pour-rafraîchir doit rester possible même quand la liste
      // tient dans l'écran.
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i < items.length) {
          return ReservationItem(reservation: items[i], onChanged: cubit.load);
        }
        return _Footer(state: state, onLoadMore: cubit.loadMore);
      },
    );
  }
}

/// Pied de liste : chargement de la page suivante, ou bouton pour la
/// demander.
///
/// Le bouton double le chargement au défilement pour le cas où la liste ne
/// défile pas — une recherche qui ne retient que deux lignes sur la page
/// chargée ne laisserait sinon aucun moyen d'aller voir la suite.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onLoadMore});

  final ReservationLoaded state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: AppLoader(size: 24)),
      );
    }
    if (!state.hasMore) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppButton(
        label: 'reservation.load_more'.tr(
          args: ['${state.items.length}', '${state.total}'],
        ),
        variant: AppButtonVariant.secondary,
        expand: true,
        onPressed: onLoadMore,
      ),
    );
  }
}
