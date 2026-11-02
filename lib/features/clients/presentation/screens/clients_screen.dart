import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import '../../business_logic/clients_cubit.dart';
import '../../business_logic/clients_state.dart';
import '../../data/models/client_filter_model.dart';
import '../../data/models/client_model.dart';
import '../widgets/client_card.dart';
import '../widgets/client_empty_state.dart';
import '../widgets/client_filter_tabs.dart';
import '../widgets/client_search_bar.dart';
import 'client_detail_screen.dart';

@RoutePage()
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClientsCubit>()..load(),
      child: const _ClientsView(),
    );
  }
}

class _ClientsView extends StatelessWidget {
  const _ClientsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientsCubit>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'clients.title'.tr(),
        actions: [
          AppButton(
            label: 'clients.new_short'.tr(),
            icon: LucideIcons.plus,
            size: AppButtonSize.sm,
            // La liste est relue au retour : sans cela, le client tout juste
            // enregistré n'y figurerait pas.
            onPressed: () async {
              final cubit = context.read<ClientsCubit>();
              await context.router.push(const AddClientRoute());
              await cubit.load();
            },
          ),
        ],
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    ClientSearchBar(onChanged: cubit.search),
                    const SizedBox(height: 12),
                    ClientFilterTabs(
                      selected: state is ClientsLoaded
                          ? state.filter
                          : ClientFilter.all,
                      onChanged: cubit.setFilter,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (state) {
                  ClientsInitial() ||
                  ClientsLoading() => const SimpleListSkeleton(itemCount: 6),
                  ClientsError(:final message) => ErrorState(
                    message: message,
                    onRetry: cubit.load,
                  ),
                  ClientsLoaded(items: final items) when items.isEmpty =>
                    const ClientEmptyState(),
                  ClientsLoaded(:final items, :final isLoadingMore) =>
                    NotificationListener<ScrollNotification>(
                      // Charge la suite avant le bas, pour que le défilement
                      // ne marque pas d'arrêt.
                      onNotification: (notification) {
                        final metrics = notification.metrics;
                        if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                          cubit.loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: items.length + (isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: AppLoader(size: 24)),
                            );
                          }

                          final client = items[i];
                          return ClientCard(
                            client: client,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientDetailScreen(
                                  client: client,
                                  onArchiveToggle: () {
                                    cubit.setStatus(
                                      client.id,
                                      client.status == ClientStatus.active
                                          ? ClientStatus.archived
                                          : ClientStatus.active,
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
