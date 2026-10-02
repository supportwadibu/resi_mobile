import 'package:easy_localization/easy_localization.dart';
enum PeriodPreset { thisMonth, lastMonth, thisYear, custom }

extension PeriodPresetExt on PeriodPreset {
  String get label {
    switch (this) {
      case PeriodPreset.thisMonth:
        return 'report.this_month'.tr();
      case PeriodPreset.lastMonth:
        return 'report.last_month'.tr();
      case PeriodPreset.thisYear:
        return 'report.this_year'.tr();
      case PeriodPreset.custom:
        return 'report.custom'.tr();
    }
  }
}

/// Valeur attendue par l'API pour le champ `period` du corps de la requête.
extension PeriodPresetApiExt on PeriodPreset {
  String get apiValue {
    switch (this) {
      case PeriodPreset.thisMonth:
        return 'this_month';
      case PeriodPreset.lastMonth:
        return 'last_month';
      case PeriodPreset.thisYear:
        return 'this_year';
      case PeriodPreset.custom:
        return 'custom';
    }
  }
}
