import '../data/models/period_preset_model.dart';
import '../data/models/report_export_model.dart';
import '../data/models/report_type_model.dart';
import '../presentation/widgets/residence_selector.dart';

/// Sentinelle du sélecteur local, jamais envoyée telle quelle : le repository
/// l'omet du corps de la requête, ce qui vaut pour l'API « toutes les
/// résidences ».
const allResidencesOption = ReportResidenceOption(
  id: 'all',
  name: 'Toutes mes résidences',
);

class ReportFormState {
  final ReportType selectedType;
  final String selectedResidenceId;
  final PeriodPreset selectedPreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final bool isGenerating;
  final ReportExportModel? result;
  final String? errorMessage;

  /// Résidences du propriétaire, sentinelle « Toutes mes résidences » comprise
  /// en tête. N'inclut que celle-ci tant que le chargement n'a pas abouti — ou
  /// s'il échoue, voir [isLoadingResidences].
  final List<ReportResidenceOption> residences;
  final bool isLoadingResidences;

  const ReportFormState({
    this.selectedType = ReportType.financial,
    this.selectedResidenceId = 'all',
    this.selectedPreset = PeriodPreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.isGenerating = false,
    this.result,
    this.errorMessage,
    this.residences = const [allResidencesOption],
    this.isLoadingResidences = false,
  });

  /// [clearResult] et [clearError] effacent un champ que `copyWith` ne peut
  /// pas distinguer de « inchangé » via `null` : sans eux, le résultat d'une
  /// génération réussie laisserait l'erreur précédente affichée, ou
  /// inversement.
  ReportFormState copyWith({
    ReportType? selectedType,
    String? selectedResidenceId,
    PeriodPreset? selectedPreset,
    DateTime? customStart,
    DateTime? customEnd,
    bool? isGenerating,
    ReportExportModel? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    List<ReportResidenceOption>? residences,
    bool? isLoadingResidences,
  }) {
    return ReportFormState(
      selectedType: selectedType ?? this.selectedType,
      selectedResidenceId: selectedResidenceId ?? this.selectedResidenceId,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      isGenerating: isGenerating ?? this.isGenerating,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      residences: residences ?? this.residences,
      isLoadingResidences: isLoadingResidences ?? this.isLoadingResidences,
    );
  }

  bool get isCustomPeriod => selectedPreset == PeriodPreset.custom;
  bool get canGenerate =>
      !isCustomPeriod || (customStart != null && customEnd != null);
}
