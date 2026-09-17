import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';

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

    // Un envoi réussi et un refus peuvent survenir dans la même passe : le
    // message doit dire ce qui s'est réellement produit, sous peine
    // d'annoncer un succès alors qu'une réservation reste à arbitrer.
    final hasProblem =
        report.conflicts > 0 || report.rejected > 0 || report.failed > 0;

    if (hasProblem) {
      AppToast.warning(_message(report), context: context);
    } else {
      AppToast.success(_message(report), context: context);
    }
  }

  static String _message(SyncReport report) {
    final parts = <String>[];

    if (report.sent > 0) {
      parts.add(_plural('sync.sent', report.sent));
    }

    if (report.conflicts > 0) {
      parts.add(_plural('sync.conflicts', report.conflicts));
    }

    // Annoncé à part du conflit : un conflit s'arbitre — le propriétaire
    // tranche qui occupe le logement — tandis qu'un rejet se constate. Les
    // confondre laisserait le gérant attendre un arbitrage qui ne viendra pas.
    if (report.rejected > 0) {
      parts.add(_plural('sync.rejected', report.rejected));
    }

    if (report.failed > 0) {
      parts.add(_plural('sync.failed', report.failed));
    }

    return parts.isEmpty ? 'sync.done'.tr() : '${parts.join(' · ')}.';
  }

  static String _plural(String key, int count) =>
      key.plural(count, args: ['$count']);

  @override
  Widget build(BuildContext context) => widget.child;
}
