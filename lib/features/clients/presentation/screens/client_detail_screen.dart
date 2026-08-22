import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/clients_fake_data.dart';
import '../widgets/client_action_button.dart';
import '../widgets/client_avatar.dart';
import '../widgets/client_status_badge.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/reservation_history_card.dart';

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
    final reservations = ClientsFakeData.reservationsByClient[client.id] ?? [];

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _ClientHeader(client: client),
            const SizedBox(height: 16),

            // Actions rapides
            _QuickActions(client: client, onArchiveToggle: onArchiveToggle),
            const SizedBox(height: 16),

            // Infos
            _InfoCard(client: client),
            const SizedBox(height: 16),

            // Stats
            _StatsCard(client: client),
            const SizedBox(height: 16),

            // Historique
            if (reservations.isNotEmpty) ...[
              Text(
                'Historique des réservations',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 10),
              ...reservations.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ReservationHistoryCard(reservation: r),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
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
    final uri = Uri.parse('https://wa.me/$number');
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
            // À défaut de numéro WhatsApp distinct, le téléphone fait foi :
            // en Côte d'Ivoire c'est presque toujours le même.
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
