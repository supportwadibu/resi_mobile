import '../data/models/period_preset_model.dart';
import '../data/models/report_type_model.dart';

class ReportFormState {
  final ReportType selectedType;
  final String selectedPropertyId;
  final PeriodPreset selectedPreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool isGenerating;

  const ReportFormState({
    this.selectedType = ReportType.financial,
    this.selectedPropertyId = 'all',
    this.selectedPreset = PeriodPreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.isGenerating = false,
  });

  ReportFormState copyWith({
    ReportType? selectedType,
    String? selectedPropertyId,
    PeriodPreset? selectedPreset,
    DateTime? customStart,
    DateTime? customEnd,
    bool? isGenerating,
  }) {
    return ReportFormState(
      selectedType: selectedType ?? this.selectedType,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  bool get isCustomPeriod => selectedPreset == PeriodPreset.custom;
  bool get canGenerate =>
      !isCustomPeriod || (customStart != null && customEnd != null);
}
