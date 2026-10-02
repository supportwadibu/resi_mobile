import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/offline/pending_action.dart';
import 'status_badge.dart';

/// Signale un élément saisi hors ligne que le serveur n'a pas encore accepté.
///
/// Rien pour un élément connu du serveur. Ambre tant qu'il attend le réseau —
/// il attend une action, celle de la synchronisation —, rouge s'il a été
/// refusé, comme tout ce qu'une décision a arrêté.
class SyncStateBadge extends StatelessWidget {
  const SyncStateBadge({required this.state, super.key});

  final PendingActionState? state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      null => const SizedBox.shrink(),
      PendingActionState.pending => StatusBadge(
        label: 'offline_queue.badge_pending'.tr(),
        tone: StatusTone.waiting,
      ),
      PendingActionState.conflict => StatusBadge(
        label: 'offline_queue.badge_conflict'.tr(),
        tone: StatusTone.stopped,
      ),
      PendingActionState.rejected => StatusBadge(
        label: 'offline_queue.badge_rejected'.tr(),
        tone: StatusTone.stopped,
      ),
    };
  }
}
