/// Période du relevé financier : douze mois glissants, une année civile ou un
/// mois.
///
/// Un choix plutôt qu'une paire de dates libres : le relevé se lit par mois
/// ou par exercice, et un choix nommé s'annonce tel quel en tête d'écran
/// (« Septembre 2026 », « Année 2025 ») au lieu d'une plage à déchiffrer.
final class FinancePeriod {
  /// Douze mois glissants jusqu'à aujourd'hui : la période à l'ouverture.
  const FinancePeriod.rolling() : year = null, month = null;

  const FinancePeriod.year(int this.year) : month = null;

  const FinancePeriod.month(int this.year, int this.month)
    : assert(month >= 1 && month <= 12);

  /// `null` pour les douze mois glissants.
  final int? year;

  /// De 1 à 12 ; `null` pour une année entière ou les douze mois glissants.
  final int? month;

  bool get isRolling => year == null;

  /// Premier et dernier jour couverts, **tous deux inclus**.
  ///
  /// Une année ou un mois en cours vont jusqu'à leur terme, et non jusqu'à
  /// aujourd'hui : « Septembre 2026 » couvre tout le mois, réservations déjà
  /// prises pour la fin du mois comprises. Le taux d'occupation reste juste,
  /// l'API le mesure sur les seuls jours écoulés.
  ({DateTime from, DateTime to}) bounds(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch ((year, month)) {
      (null, _) => (
        from: DateTime(today.year - 1, today.month, today.day),
        to: today,
      ),
      (final int y, null) => (from: DateTime(y, 1, 1), to: DateTime(y, 12, 31)),
      // Le jour 0 du mois suivant est le dernier jour du mois.
      (final int y, final int m) => (
        from: DateTime(y, m, 1),
        to: DateTime(y, m + 1, 0),
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is FinancePeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
