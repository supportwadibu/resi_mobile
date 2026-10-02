import 'dart:convert';

/// Identifiant de l'utilisateur (`sub`) porté par un jeton d'accès JWT.
///
/// Lu sans vérifier la signature : il ne sert qu'à cloisonner le cache local
/// entre deux comptes du même appareil, jamais à décider d'un droit — c'est le
/// serveur qui contrôle le jeton. Un jeton illisible rend `null`, et la lecture
/// part alors sans cache plutôt que de risquer un mélange de comptes.
String? jwtSubject(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    if (claims is! Map) return null;
    final sub = claims['sub'];
    return sub is String && sub.isNotEmpty ? sub : null;
  } catch (_) {
    return null;
  }
}
