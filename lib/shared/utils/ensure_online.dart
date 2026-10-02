import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../core/di/service_locator.dart';
import '../widgets/app_toast.dart';

/// Laisse passer une action réservée au réseau, ou dit pourquoi elle attend.
///
/// Garde posée à l'entrée des flux qui ne se mettent pas en file — biens,
/// résidences, publication, abonnement, gérants, export : sans elle, le
/// propriétaire remplissait un formulaire entier hors ligne pour le voir
/// échouer à l'envoi. Un Wi-Fi sans Internet passe la garde : l'envoi échoue
/// alors avec le message réseau habituel.
Future<bool> ensureOnline(BuildContext context) async {
  final results = await sl<Connectivity>().checkConnectivity();
  final online = results.any((r) => r != ConnectivityResult.none);
  if (!online && context.mounted) {
    AppToast.warning('offline_queue.requires_network'.tr(), context: context);
  }
  return online;
}
