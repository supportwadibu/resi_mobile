import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import '../../data/models/client_model.dart';
import 'client_avatar.dart';
import 'client_status_badge.dart';

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const ClientCard({super.key, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
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
                          style: AppTextStyles.valueSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ClientStatusBadge(status: client.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Le téléphone plutôt qu'une résidence : il identifie le
                  // client, là où un habitué a séjourné dans plusieurs biens.
                  Text(
                    client.phone,
                    style: AppTextStyles.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Stat(
                        icon: Icons.calendar_today_rounded,
                        label: '${client.stats.totalStays} séjours',
                      ),
                      const SizedBox(width: 14),
                      _Stat(
                        icon: Icons.payments_rounded,
                        label: CurrencyFormatter.format(client.stats.totalPaid),
                      ),
                      if (!client.documentsComplete) ...[
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
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
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
