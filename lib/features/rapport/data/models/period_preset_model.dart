enum PeriodPreset { thisMonth, lastMonth, thisYear, custom }

extension PeriodPresetExt on PeriodPreset {
  String get label {
    switch (this) {
      case PeriodPreset.thisMonth:
        return 'Ce mois-ci';
      case PeriodPreset.lastMonth:
        return 'Mois précédent';
      case PeriodPreset.thisYear:
        return 'Année en cours';
      case PeriodPreset.custom:
        return 'Dates personnalisées';
    }
  }
}
