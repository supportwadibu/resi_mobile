import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';

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
            return ValueListenableBuilder<int>(
              valueListenable: sync.rejectedCount,
              builder: (context, rejected, _) {
                return _banner(context, sync, pending, conflicts, rejected);
              },
            );
          },
        );
      },
    );
  }

  Widget _banner(
    BuildContext context,
    SyncService sync,
    int pending,
    int conflicts,
    int rejected,
  ) {
    if (pending == 0 && conflicts == 0 && rejected == 0) {
      return const SizedBox.shrink();
    }

    // Un refus du serveur est rouge, comme tout ce qu'une décision a arrêté ;
    // une saisie qui attend le réseau est ambre, comme tout ce qui attend une
    // action.
    final isConflict = conflicts > 0 || rejected > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCallout(
        icon: isConflict ? LucideIcons.circleAlert : LucideIcons.cloudUpload,
        tone: isConflict ? AppAccent.red : AppAccent.amber,
        message: label(pending, conflicts, rejected),
        action: isConflict
            ? null
            : AppButton(
                label: 'Envoyer maintenant',
                icon: LucideIcons.refreshCw,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: sync.synchronize,
              ),
      ),
    );
  }

  @visibleForTesting
  static String label(int pending, int conflicts, int rejected) {
    if (rejected > 0) {
      return rejected == 1
          ? '1 réservation refusée : logement hors de votre périmètre.'
          : '$rejected réservations refusées : logements hors de votre périmètre.';
    }

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
