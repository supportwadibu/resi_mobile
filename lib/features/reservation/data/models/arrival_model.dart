import 'reservation_model.dart';

/// Réservation présentée au comptoir, telle que la rend
/// `GET /bookings/arrival/:code`.
class ArrivalModel {
  const ArrivalModel({
    required this.reservation,
    required this.onlinePaid,
    required this.canCheckIn,
    this.blockerCode,
    this.blockerMessage,
  });

  factory ArrivalModel.fromJson(Map<String, dynamic> json) {
    final check = json['check'] as Map<String, dynamic>? ?? const {};
    final blocker = check['blocker'] as Map<String, dynamic>?;
    return ArrivalModel(
      reservation: ReservationModel.fromJson(
        json['booking'] as Map<String, dynamic>,
      ),
      onlinePaid: check['online_paid'] == true,
      canCheckIn: check['can_check_in'] == true,
      blockerCode: blocker?['code'] as String?,
      blockerMessage: blocker?['message'] as String?,
    );
  }

  final ReservationModel reservation;

  /// Le paiement en ligne — total ou acompte — est encaissé.
  final bool onlinePaid;

  /// Rien ne s'oppose à la remise des clés.
  final bool canCheckIn;

  /// Code stable de ce qui bloque — `booking_balance_due`,
  /// `check_in_too_early`… — lu pour choisir l'écran, jamais le message.
  final String? blockerCode;
  final String? blockerMessage;

  /// Seul le reste dû bloque : l'encaisser débloque l'arrivée.
  bool get blockedByBalance => blockerCode == 'booking_balance_due';
}
