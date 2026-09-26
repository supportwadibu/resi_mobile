import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../business_logic/client_detail_cubit.dart';
import '../../business_logic/client_detail_state.dart';
import '../widgets/client_avatar.dart';
import '../widgets/client_status_badge.dart';
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
      appBar: AppTopBar(
        title: 'Fiche client',
        actions: [
          BlocBuilder<ClientDetailCubit, ClientDetailState>(
            builder: (context, state) {
              if (state is! ClientDetailLoaded) return const SizedBox.shrink();
              return AppIconButton(
                icon: LucideIcons.pencil,
                label: 'Modifier',
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
            ClientDetailInitial() ||
            ClientDetailLoading() => const Center(child: AppLoader()),
            ClientDetailError(:final message) => ErrorState(message: message),
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
    final lastStay = client.stats.lastStayAt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ClientHeader(client: client),
        const SizedBox(height: 12),
        _QuickActions(client: client, onArchiveToggle: onArchiveToggle),
        const SizedBox(height: 16),
        StatGrid(
          children: [
            StatTile(
              label: 'Séjours',
              value: '${client.stats.totalStays}',
              icon: AppSectionIcons.bookings,
              accent: AppAccent.violet,
            ),
            StatTile(
              label: 'Total payé',
              value: CurrencyFormatter.short(client.stats.totalPaid),
              icon: LucideIcons.banknote,
              accent: AppAccent.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Coordonnées',
          icon: AppSectionIcons.profile,
          child: DetailList(
            items: [
              DetailItem('Téléphone', client.phone, icon: LucideIcons.phone),
              DetailItem(
                'Pièce d’identité',
                client.documentsComplete
                    ? (client.idDocumentType?.label ?? 'Déposée')
                    : 'Incomplète',
                icon: LucideIcons.idCard,
              ),
              DetailItem(
                'Dernier séjour',
                lastStay == null
                    ? 'Aucun séjour'
                    : DateFormat('dd MMMM yyyy', 'fr_FR').format(lastStay),
                icon: LucideIcons.calendar,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IdentityDocumentsCard(client: client),
        const SizedBox(height: 16),
        Section(
          title: 'Historique des séjours',
          icon: AppSectionIcons.bookings,
          padding: EdgeInsets.zero,
          child: _History(state: state),
        ),
      ],
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
        child: Center(child: AppLoader()),
      );
    }

    if (state.historyError != null) {
      return ErrorState(
        message: state.historyError!,
        onRetry: () =>
            context.read<ClientDetailCubit>().retryHistory(state.client.id),
      );
    }

    if (state.reservations.isEmpty) {
      return const EmptyState(
        message: 'Aucun séjour enregistré',
        icon: LucideIcons.calendarX,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < state.reservations.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          ReservationHistoryCard(reservation: state.reservations[i]),
        ],
      ],
    );
  }
}

class _ClientHeader extends StatelessWidget {
  final ClientModel client;
  const _ClientHeader({required this.client});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClientAvatar(initials: client.avatarInitials, size: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.fullName, style: context.text.titleLarge),
              const SizedBox(height: 6),
              ClientStatusBadge(status: client.status),
            ],
          ),
        ),
      ],
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
          child: AppButton(
            label: 'Appeler',
            icon: LucideIcons.phone,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => _call(client.phone),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            label: 'WhatsApp',
            icon: LucideIcons.messageCircle,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => _whatsapp(client.whatsapp ?? client.phone),
          ),
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
          label: isArchived ? 'Restaurer' : 'Archiver',
          bordered: true,
          onPressed: onArchiveToggle,
        ),
      ],
    );
  }
}
