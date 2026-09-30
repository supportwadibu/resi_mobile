// `maintenance` et `fiscal` ont existé dans la maquette mais n'ont rien
// derrière côté API : aucune donnée d'intervention ni de prestataire pour la
// maintenance, aucun marqueur de déductibilité pour le fiscal. Retirés plutôt
// que branchés sur des champs qui n'existent pas.
//
// `police` est le registre des personnes hébergées remis à la Brigade
// mondaine : un formulaire administratif, en paysage, que le propriétaire
// imprime tel quel.
enum ReportType { financial, performance, reservations, police }

extension ReportTypeExt on ReportType {
  String get label {
    switch (this) {
      case ReportType.financial:
        return 'Bilan Financier';
      case ReportType.performance:
        return 'Performance & Occupation';
      case ReportType.reservations:
        return 'Relevé des Réservations';
      case ReportType.police:
        return 'Rapport police';
    }
  }

  String get description {
    switch (this) {
      case ReportType.financial:
        return 'Revenus vs dépenses, bénéfice net';
      case ReportType.performance:
        return 'Taux d\'occupation, RevPAR, nuitées';
      case ReportType.reservations:
        return 'Historique locataires, paiements';
      case ReportType.police:
        return 'Liste des personnes hébergées, pour la police';
    }
  }

  String get iconPath {
    switch (this) {
      case ReportType.financial:
        return 'trending_up';
      case ReportType.performance:
        return 'bar_chart';
      case ReportType.reservations:
        return 'people';
      case ReportType.police:
        return 'shield';
    }
  }
}

/// Valeur attendue par l'API pour le champ `type` du corps de la requête.
extension ReportTypeApiExt on ReportType {
  String get apiValue {
    switch (this) {
      case ReportType.financial:
        return 'financial';
      case ReportType.performance:
        return 'performance';
      case ReportType.reservations:
        return 'reservations';
      case ReportType.police:
        return 'police';
    }
  }
}
