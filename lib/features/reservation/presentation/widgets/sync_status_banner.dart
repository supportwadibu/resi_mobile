import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
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
        // Un refus s'arbitre sur l'écran dédié ; une attente se relance.
        action: isConflict
            ? AppButton(
                label: 'sync_banner.review'.tr(),
                icon: LucideIcons.listChecks,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.router.push(const SyncReviewRoute()),
              )
            : AppButton(
                label: 'sync_banner.send_now'.tr(),
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
      return 'sync_banner.rejected'.plural(rejected);
    }

    if (conflicts > 0) {
      return 'sync_banner.conflicts'.plural(conflicts);
    }

    return 'sync_banner.pending'.plural(pending);
  }
}
