import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../business_logic/add_reservation_state.dart';

/// Demande si le client arrive maintenant ou si le séjour est à venir.
///
/// Le choix commande le reste du formulaire : un check-in verrouille la date
/// d'entrée à l'instant présent et crée un séjour « en cours », une
/// réservation future laisse la date au choix et n'immobilise le bien que sur
/// ses dates.
Future<ReservationMode?> showReservationModeSheet(BuildContext context) {
  return showModalBottomSheet<ReservationMode>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nouvelle réservation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le client est-il déjà sur place ?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _ModeCard(
              icon: Icons.login_rounded,
              title: 'Check-in immédiat',
              subtitle: 'Le client entre maintenant',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReservationMode.checkIn),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.event_available_outlined,
              title: 'Réservation future',
              subtitle: 'Séjour prévu à une date à venir',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReservationMode.future),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }
}
