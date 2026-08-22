enum ReportType { financial, performance, maintenance, reservations, fiscal }

extension ReportTypeExt on ReportType {
  String get label {
    switch (this) {
      case ReportType.financial:
        return 'Bilan Financier';
      case ReportType.performance:
        return 'Performance & Occupation';
      case ReportType.maintenance:
        return 'État des Lieux & Maintenance';
      case ReportType.reservations:
        return 'Relevé des Réservations';
      case ReportType.fiscal:
        return 'Rapport Fiscal';
    }
  }

  String get description {
    switch (this) {
      case ReportType.financial:
        return 'Revenus vs dépenses, bénéfice net';
      case ReportType.performance:
        return 'Taux d\'occupation, RevPAR, nuitées';
      case ReportType.maintenance:
        return 'Interventions, coûts, prestataires';
      case ReportType.reservations:
        return 'Historique locataires, paiements';
      case ReportType.fiscal:
        return 'CA brut, charges déductibles';
    }
  }

  String get iconPath {
    switch (this) {
      case ReportType.financial:
        return 'trending_up';
      case ReportType.performance:
        return 'bar_chart';
      case ReportType.maintenance:
        return 'build';
      case ReportType.reservations:
        return 'people';
      case ReportType.fiscal:
        return 'receipt_long';
    }
  }
}
