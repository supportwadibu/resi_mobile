import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Clients',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.router.push(AddClientRoute()),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                  ClientsInitial() || ClientsLoading() => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  ClientsError(:final message) => _ErrorView(
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
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

/// Échec de chargement du carnet, avec de quoi réessayer.
///
/// Distinct de l'état vide : un carnet sans client invite à en créer un, une
/// erreur réseau invite à relancer.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 34,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Réessayer', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
