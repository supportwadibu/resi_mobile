class StayExtension {
  final String residenceName;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  /// Tarif d'une nuit, jusqu'à l'heure de départ du lendemain.
  final double pricePerDay;

  StayExtension({
    required this.residenceName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.pricePerDay,
  });
}
