import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import '../../data/models/client_model.dart';
import 'client_avatar.dart';
import 'client_status_badge.dart';
import 'package:resi_africa/shared/widgets/sync_state_badge.dart';

/// Ligne du carnet : initiales, nom, statut, téléphone, séjours et total
/// réglé.
class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const ClientCard({super.key, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClientAvatar(initials: client.avatarInitials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        client.fullName,
                        style: context.text.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClientStatusBadge(status: client.status),
                  ],
                ),
                if (client.syncState case final syncState?) ...[
                  const SizedBox(height: 4),
                  SyncStateBadge(state: syncState),
                ],
                const SizedBox(height: 2),
                // Le téléphone plutôt qu'une résidence : il identifie le
                // client, là où un habitué a séjourné dans plusieurs biens.
                Text(
                  client.phone,
                  style: context.text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Stat(
                      icon: LucideIcons.calendar,
                      label: 'clients.stays_count'.plural(
                        client.stats.totalStays,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Stat(
                      icon: LucideIcons.banknote,
                      label: CurrencyFormatter.short(client.stats.totalPaid),
                    ),
                    // Pièces manquantes : un point d'attention, en ambre
                    // comme tout ce qui attend une action.
                    if (!client.documentsComplete) ...[
                      const SizedBox(width: 12),
                      Icon(LucideIcons.idCard, size: 12, color: t.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        'clients.documents_to_complete'.tr(),
                        style: context.text.bodySmall!.copyWith(
                          color: t.accentAmber,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, color: t.muted, size: 16),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.tokens.muted),
        const SizedBox(width: 4),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}
