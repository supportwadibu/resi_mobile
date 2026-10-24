import 'dart:async';

import 'package:app_links/app_links.dart';

/// Issue d'un paiement Wave, telle que la page de retour du site la transmet.
enum PaymentReturn { success, failure }

/// Retours de paiement Wave : `resi://abonnement?statut=succes|echec`.
///
/// La page du site, où Wave renvoie le propriétaire, rouvre l'application par
/// ce lien. Le paiement est déjà confirmé côté serveur à ce stade : le lien ne
/// fait foi de rien, il dit seulement quoi annoncer. L'écran des forfaits le
/// recoupe par sa propre confirmation.
///
/// Un seul écouteur à la fois : l'écran des forfaits s'y attache quand il est
/// affiché ([attach]), parce qu'il porte le paiement en cours et sait le
/// confirmer. Sinon — application relancée par le lien, ou ouverte sur un
/// autre écran — le retour va à [fallback], posé par l'application.
class PaymentReturnLinks {
  PaymentReturnLinks({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  void Function(PaymentReturn outcome)? _listener;

  /// Traitement par défaut, quand aucun écran ne s'est attaché.
  void Function(PaymentReturn outcome)? fallback;

  /// Écoute les liens, y compris celui qui a lancé l'application : `app_links`
  /// le rejoue sur le flux à l'abonnement.
  void start() {
    _subscription ??= _appLinks.uriLinkStream.listen(_onLink);
  }

  void attach(void Function(PaymentReturn outcome) listener) =>
      _listener = listener;

  /// Ne détache que [listener] : un écran qui se ferme après qu'un autre a
  /// pris la main ne doit pas le déposséder.
  void detach(void Function(PaymentReturn outcome) listener) {
    if (identical(_listener, listener)) _listener = null;
  }

  void _onLink(Uri uri) {
    final outcome = parse(uri);
    if (outcome == null) return;
    (_listener ?? fallback)?.call(outcome);
  }

  /// `null` pour un lien qui n'est pas un retour de paiement.
  static PaymentReturn? parse(Uri uri) {
    if (uri.scheme != 'resi' || uri.host != 'abonnement') return null;
    return switch (uri.queryParameters['statut']) {
      'succes' => PaymentReturn.success,
      'echec' => PaymentReturn.failure,
      _ => null,
    };
  }

  Future<void> dispose() async => _subscription?.cancel();
}
