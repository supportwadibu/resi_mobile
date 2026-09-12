import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../business_logic/residence_cubit.dart';
import '../../business_logic/residence_state.dart';
import '../widgets/residence_card.dart';

/// Résidences du propriétaire — les lieux regroupant plusieurs logements.
@RoutePage()
class ResidenceScreen extends StatelessWidget {
  const ResidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResidenceCubit>()..load(),
      child: const _ResidenceView(),
    );
  }
}

class _ResidenceView extends StatelessWidget {
  const _ResidenceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes résidences')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: BlocBuilder<ResidenceCubit, ResidenceState>(
        builder: (context, state) => switch (state) {
          ResidenceInitial() || ResidenceLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ResidenceError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<ResidenceCubit>().load(),
          ),
          ResidenceLoaded(:final items) when items.isEmpty => const _EmptyView(),
          ResidenceLoaded(:final items) => RefreshIndicator(
            onRefresh: () => context.read<ResidenceCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final residence = items[index];
                return ResidenceCard(
                  residence: residence,
                  onTap: () => _openForm(context, id: residence.id),
                  onDelete: () => _confirmDelete(context, residence.id),
                );
              },
            ),
          ),
        },
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }

  Future<void> _openForm(BuildContext context, {String? id}) async {
    final cubit = context.read<ResidenceCubit>();
    await context.router.push(AddResidenceRoute(residenceId: id));
    // La liste est rechargée au retour : le formulaire a son propre cubit, et
    // ses écritures n'atteignent donc pas celui de cette page.
    await cubit.load();
  }

  /// Demande confirmation, puis supprime.
  ///
  /// La suppression est refusée par le serveur tant que des logements sont
  /// rattachés : le message est affiché tel quel plutôt que traduit ici, lui
  /// seul sachant combien il en reste.
  Future<void> _confirmDelete(BuildContext context, String id) async {
    final cubit = context.read<ResidenceCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette résidence ?'),
        content: const Text(
          'Les logements qu’elle contient ne sont pas supprimés. '
          'Détachez-les d’abord si la suppression est refusée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await cubit.delete(id);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 56,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune résidence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Une résidence regroupe plusieurs logements loués séparément — '
              'un studio, une chambre-salon — qui partagent une adresse et des '
              'charges communes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
