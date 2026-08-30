import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Annonce le résultat d'une synchronisation.
///
/// Le bandeau d'attente se contente de disparaître quand la file se vide, ce
/// qui ne distingue pas un envoi réussi d'un abandon. Le propriétaire a
/// encaissé de l'argent au comptoir : il doit voir que ses saisies ont bien
/// atteint le serveur.
///
/// La synchronisation démarre au `bootstrap`, sans `BuildContext` — elle
/// publie son rapport et cet écouteur, monté dans l'arbre, l'affiche.
class SyncResultListener extends StatefulWidget {
  const SyncResultListener({super.key, required this.child});

  final Widget child;

  @override
  State<SyncResultListener> createState() => _SyncResultListenerState();
}

class _SyncResultListenerState extends State<SyncResultListener> {
  late final SyncService _sync = sl<SyncService>();

  @override
  void initState() {
    super.initState();
    _sync.lastReport.addListener(_onReport);
  }

  @override
  void dispose() {
    _sync.lastReport.removeListener(_onReport);
    super.dispose();
  }

  void _onReport() {
    final report = _sync.lastReport.value;
    if (report == null || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Un envoi réussi et un refus peuvent survenir dans la même passe : le
    // message doit dire ce qui s'est réellement produit, sous peine
    // d'annoncer un succès alors qu'une réservation reste à arbitrer.
    final hasProblem = report.conflicts > 0 || report.failed > 0;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_message(report)),
          backgroundColor: hasProblem ? AppColors.warning : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  static String _message(SyncReport report) {
    final parts = <String>[];

    if (report.sent > 0) {
      parts.add(
        report.sent == 1
            ? '1 réservation transmise'
            : '${report.sent} réservations transmises',
      );
    }

    if (report.conflicts > 0) {
      parts.add(
        report.conflicts == 1
            ? '1 refusée (période déjà prise)'
            : '${report.conflicts} refusées (périodes déjà prises)',
      );
    }

    if (report.failed > 0) {
      parts.add(
        report.failed == 1
            ? '1 en attente de réseau'
            : '${report.failed} en attente de réseau',
      );
    }

    return parts.isEmpty
        ? 'Synchronisation terminée.'
        : '${parts.join(' · ')}.';
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
