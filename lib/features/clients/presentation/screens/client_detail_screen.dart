import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../business_logic/client_detail_cubit.dart';
import '../../business_logic/client_detail_state.dart';
import '../widgets/client_action_button.dart';
import '../widgets/client_avatar.dart';
import '../widgets/client_status_badge.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/identity_documents_card.dart';
import '../widgets/reservation_history_card.dart';
import 'edit_client_screen.dart';

@RoutePage()
class ClientDetailScreen extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onArchiveToggle;

  const ClientDetailScreen({
    super.key,
    required this.client,
    this.onArchiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // La fiche venue de la liste s'affiche sans attendre, puis est remplacée
      // par celle du serveur : le propriétaire doit pouvoir appeler son client
      // avant la fin du chargement.
      create: (_) => ClientDetailCubit(sl())..load(client.id, known: client),
      child: _ClientDetailView(onArchiveToggle: onArchiveToggle),
    );
  }
}

class _ClientDetailView extends StatelessWidget {
  const _ClientDetailView({this.onArchiveToggle});

  final VoidCallback? onArchiveToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Fiche Client',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<ClientDetailCubit, ClientDetailState>(
            builder: (context, state) {
              if (state is! ClientDetailLoaded) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                tooltip: 'Modifier',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditClientScreen(
                      client: state.client,
                      cubit: context.read<ClientDetailCubit>(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ClientDetailCubit, ClientDetailState>(
        builder: (context, state) {
          return switch (state) {
            ClientDetailInitial() || ClientDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ClientDetailError(:final message) => _ErrorView(message: message),
            ClientDetailLoaded() => _LoadedView(
              state: state,
              onArchiveToggle: onArchiveToggle,
            ),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state, this.onArchiveToggle});

  final ClientDetailLoaded state;
  final VoidCallback? onArchiveToggle;

  @override
  Widget build(BuildContext context) {
    final client = state.client;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClientHeader(client: client),
          const SizedBox(height: 16),

          _QuickActions(client: client, onArchiveToggle: onArchiveToggle),
          const SizedBox(height: 16),

          _InfoCard(client: client),
          const SizedBox(height: 16),

          IdentityDocumentsCard(client: client),
          const SizedBox(height: 16),

          _StatsCard(client: client),
          const SizedBox(height: 16),

          Text(
            'Historique des réservations',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 10),
          _History(state: state),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Historique des séjours : chargement, échec rattrapable, ou liste.
class _History extends StatelessWidget {
  const _History({required this.state});

  final ClientDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isHistoryLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.historyError != null) {
      return _HistoryError(
        message: state.historyError!,
        onRetry: () =>
            context.read<ClientDetailCubit>().retryHistory(state.client.id),
      );
    }

    if (state.reservations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 28,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text('Aucun séjour enregistré', style: AppTextStyles.labelMedium),
          ],
        ),
      );
    }

    return Column(
      children: state.reservations
          .map(
            (reservation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReservationHistoryCard(reservation: reservation),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium,
        ),
      ),
    );
  }
}

class _ClientHeader extends StatelessWidget {
  final ClientModel client;
  const _ClientHeader({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ClientAvatar(initials: client.avatarInitials, size: 64),
          const SizedBox(height: 12),
          Text(
            client.fullName,
            style: AppTextStyles.valueMedium.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          ClientStatusBadge(status: client.status),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onArchiveToggle;

  const _QuickActions({required this.client, this.onArchiveToggle});

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp(String number) async {
    final uri = Uri.parse('https://wa.me/225$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = client.status == ClientStatus.archived;
    return Row(
      children: [
        Expanded(
          child: ClientActionButton(
            icon: Icons.call_rounded,
            label: 'Appeler',
            color: AppColors.black,
            onTap: () => _call(client.phone),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClientActionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            color: Colors.black,
            onTap: () => _whatsapp(client.whatsapp ?? client.phone),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClientActionButton(
            icon: isArchived ? Icons.restore_rounded : Icons.archive_rounded,
            label: isArchived ? 'Restaurer' : 'Archiver',
            color: isArchived ? AppColors.black : AppColors.textSecondary,
            onTap: onArchiveToggle ?? () {},
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ClientModel client;
  const _InfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          DetailInfoRow(
            icon: Icons.phone_rounded,
            label: 'Téléphone',
            value: client.phone,
          ),
          Divider(color: AppColors.divider, height: 1),
          DetailInfoRow(
            icon: Icons.badge_rounded,
            label: 'Pièce d’identité',
            value: client.documentsComplete
                ? (client.idDocumentType?.label ?? 'Déposée')
                : 'Incomplète',
          ),
          Divider(color: AppColors.divider, height: 1),
          DetailInfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Dernier séjour',
            value: client.stats.lastStayAt == null
                ? 'Aucun séjour'
                : DateFormat(
                    'dd MMMM yyyy',
                    'fr_FR',
                  ).format(client.stats.lastStayAt!),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ClientModel client;
  const _StatsCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StatBlock(
            label: 'Total séjours',
            value: '${client.stats.totalStays}',
          ),
          _VerticalDivider(),
          _StatBlock(
            label: 'Total payé',
            value: CurrencyFormatter.format(client.stats.totalPaid),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.valueMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}
