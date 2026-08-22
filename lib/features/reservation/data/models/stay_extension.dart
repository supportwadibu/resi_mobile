class StayExtension {
  final String residenceName;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  /// Tarif d'une journée d'occupation (12h → 12h le lendemain).
  final double pricePerDay;

  StayExtension({
    required this.residenceName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.pricePerDay,
  });
}
