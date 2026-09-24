// `maintenance` et `fiscal` ont existé dans la maquette mais n'ont rien
// derrière côté API : aucune donnée d'intervention ni de prestataire pour la
// maintenance, aucun marqueur de déductibilité pour le fiscal. Retirés plutôt
// que branchés sur des champs qui n'existent pas.
enum ReportType { financial, performance, reservations }

extension ReportTypeExt on ReportType {
  String get label {
    switch (this) {
      case ReportType.financial:
        return 'Bilan Financier';
      case ReportType.performance:
        return 'Performance & Occupation';
      case ReportType.reservations:
        return 'Relevé des Réservations';
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
    }
  }
}
