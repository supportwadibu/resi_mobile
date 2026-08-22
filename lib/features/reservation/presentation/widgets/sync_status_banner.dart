import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';

/// Signale les réservations qui n'ont pas encore atteint le serveur.
///
/// Sans ce rappel, une saisie hors réseau passerait pour confirmée et le
/// propriétaire ne saurait pas qu'il lui reste quelque chose à transmettre.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = sl<SyncService>();

    return ValueListenableBuilder<int>(
      valueListenable: sync.pendingCount,
      builder: (context, pending, _) {
        return ValueListenableBuilder<int>(
          valueListenable: sync.conflictCount,
          builder: (context, conflicts, _) {
            if (pending == 0 && conflicts == 0) {
              return const SizedBox.shrink();
            }

            // Un conflit prime : il demande un arbitrage, là où une attente de
            // réseau se résout seule.
            final isConflict = conflicts > 0;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isConflict ? AppColors.errorBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isConflict ? AppColors.error : AppColors.warning)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isConflict
                        ? Icons.error_outline
                        : Icons.cloud_upload_outlined,
                    size: 18,
                    color: isConflict ? AppColors.error : AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _label(pending, conflicts),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!isConflict)
                    TextButton(
                      onPressed: sync.synchronize,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Envoyer',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _label(int pending, int conflicts) {
    if (conflicts > 0) {
      return conflicts == 1
          ? '1 réservation refusée : la période était déjà prise.'
          : '$conflicts réservations refusées : périodes déjà prises.';
    }

    return pending == 1
        ? '1 réservation en attente d’envoi.'
        : '$pending réservations en attente d’envoi.';
  }
}
