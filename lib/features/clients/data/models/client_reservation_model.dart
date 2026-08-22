enum ReservationStatus { paid, pending, cancelled }

class ClientReservationModel {
  final String id;
  final String residenceName;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final ReservationStatus status;

  const ClientReservationModel({
    required this.id,
    required this.residenceName,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
  });

  /// Jours d'occupation : l'écart entre l'arrivée et le départ, une journée
  /// courant d'une heure à la même heure le lendemain.
  int get days => endDate.difference(startDate).inDays;
}
