/// Clés sous lesquelles une réponse `GET` est mise en cache.
///
/// [exact] désigne la requête elle-même. [loose] existe pour les lectures
/// datées — finance, tableau de bord — dont les bornes suivent l'horloge :
/// « du 1er du mois à maintenant » change de valeur à chaque appel, et sans
/// clé souple le lendemain hors ligne ne retrouverait jamais rien.
class CacheKeys {
  const CacheKeys({required this.exact, this.loose});

  final String exact;

  /// Même requête, paramètres datés retirés. `null` quand il n'y en a pas :
  /// la clé exacte suffit, et servir une autre page ou un autre filtre en
  /// repli afficherait des données fausses.
  final String? loose;
}

/// Instant au format ISO 8601, tel que les repositories l'envoient.
final _isoInstant = RegExp(r'^\d{4}-\d{2}-\d{2}T');

/// Construit les clés d'une requête.
///
/// [owner] identifie l'utilisateur : la clé l'inclut pour qu'un gérant ne lise
/// jamais le cache d'un propriétaire sur le même appareil. Le rôle, lui, est
/// déjà dans [path] (`/proprio/…`, `/gerant/…`).
///
/// Un instant est ramené à son jour : la clé exacte d'un « jusqu'à
/// maintenant » reste ainsi stable sur la journée.
CacheKeys cacheKeysFor({
  required String owner,
  required String path,
  required Map<String, dynamic> query,
}) {
  final exact = <String>[];
  final loose = <String>[];
  var hasTemporal = false;

  final names = query.keys.toList()..sort();
  for (final name in names) {
    final value = query[name];
    if (value == null) continue;

    final temporal = _asDay(value);
    if (temporal != null) {
      hasTemporal = true;
      exact.add('$name=$temporal');
    } else {
      exact.add('$name=$value');
      loose.add('$name=$value');
    }
  }

  String join(List<String> parts) => '$owner|$path?${parts.join('&')}';

  return CacheKeys(
    exact: join(exact),
    loose: hasTemporal ? join(loose) : null,
  );
}

/// Jour (`2026-10-01`) d'un paramètre daté, `null` pour tout autre paramètre.
String? _asDay(Object value) {
  if (value is DateTime) return value.toUtc().toIso8601String().substring(0, 10);
  if (value is String && _isoInstant.hasMatch(value)) {
    return value.substring(0, 10);
  }
  return null;
}
