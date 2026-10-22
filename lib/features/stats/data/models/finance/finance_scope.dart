/// Périmètre du relevé financier : tout le parc, une résidence avec ses
/// logements, ou un logement seul.
///
/// Résidence et logement sont exclusifs. Une résidence retient le revenu de
/// ses logements, ses charges communes et celles de ses logements ; un
/// logement ne retient que son revenu et ses propres charges — jamais une part
/// des charges communes, que le serveur ne sait pas répartir.
final class FinanceScope {
  const FinanceScope.portfolio()
    : residenceId = null,
      propertyId = null,
      label = null;

  const FinanceScope.residence({required String id, required String name})
    : residenceId = id,
      propertyId = null,
      label = name;

  const FinanceScope.property({required String id, required String name})
    : residenceId = null,
      propertyId = id,
      label = name;

  final String? residenceId;
  final String? propertyId;

  /// Nom affiché sur le bouton du périmètre, `null` pour tout le parc.
  final String? label;

  bool get isPortfolio => residenceId == null && propertyId == null;

  /// Égalité sur les seuls identifiants : le libellé n'est qu'un affichage, et
  /// un bien renommé entre deux ouvertures de la feuille reste le même
  /// périmètre — le recharger ne changerait aucun chiffre.
  @override
  bool operator ==(Object other) =>
      other is FinanceScope &&
      other.residenceId == residenceId &&
      other.propertyId == propertyId;

  @override
  int get hashCode => Object.hash(residenceId, propertyId);
}
