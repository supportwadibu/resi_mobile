import 'package:flutter/foundation.dart';

/// Date des données affichées quand elles viennent du cache, `null` quand
/// elles sont fraîches.
///
/// Retient la plus **ancienne** date servie depuis le dernier succès réseau :
/// le bandeau doit annoncer la donnée la plus périmée à l'écran, pas la plus
/// récente.
class OfflineStatus extends ValueNotifier<DateTime?> {
  OfflineStatus() : super(null);

  /// Une lecture vient d'être servie depuis le cache.
  void markCached(DateTime cachedAt) {
    final current = value;
    if (current == null || cachedAt.isBefore(current)) value = cachedAt;
  }

  /// Une lecture vient d'aboutir sur le réseau.
  void markFresh() => value = null;
}
