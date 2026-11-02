import '../data/models/early_check_out_quote.dart';
import '../data/models/reservation_model.dart';

/// États du départ anticipé.
sealed class EarlyCheckOutState {
  const EarlyCheckOutState();
}

final class EarlyCheckOutInitial extends EarlyCheckOutState {
  const EarlyCheckOutInitial();
}

/// Chiffrage en cours pour l'heure de sortie choisie.
final class EarlyCheckOutLoading extends EarlyCheckOutState {
  const EarlyCheckOutLoading();
}

/// Chiffrage reçu. [isSubmitting] garde le détail affiché pendant l'envoi :
/// le vider ferait sauter la feuille au moment où le propriétaire valide.
///
/// [isEstimate] : chiffré sur l'appareil, faute de réseau. Le montant retenu
/// partira tel quel à la synchronisation.
final class EarlyCheckOutLoaded extends EarlyCheckOutState {
  const EarlyCheckOutLoaded(
    this.quote, {
    this.isSubmitting = false,
    this.isEstimate = false,
  });

  final EarlyCheckOutQuote quote;
  final bool isSubmitting;
  final bool isEstimate;
}

/// Heure refusée, réseau coupé ou clôture refusée.
///
/// [quote] est conservé quand l'échec survient à l'envoi : le propriétaire
/// corrige le montant et réessaie sans rechiffrer.
final class EarlyCheckOutError extends EarlyCheckOutState {
  const EarlyCheckOutError(this.message, {this.quote});

  final String message;
  final EarlyCheckOutQuote? quote;
}

final class EarlyCheckOutSuccess extends EarlyCheckOutState {
  const EarlyCheckOutSuccess(this.reservation, {this.queued = false});

  /// Réservation clôturée par le serveur, `null` quand le départ est en file.
  final ReservationModel? reservation;

  /// Départ saisi hors ligne, envoyé au retour du réseau.
  final bool queued;
}
