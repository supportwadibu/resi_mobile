import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../residence/data/repositories/residence_repository.dart';
import '../data/models/period_preset_model.dart';
import '../data/models/report_type_model.dart';
import '../data/repositories/rapport_repository.dart';
import '../presentation/widgets/residence_selector.dart';
import 'report_form_state.dart';

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(this._repository, this._residenceRepository)
    : super(const ReportFormState());

  final RapportRepository _repository;
  final ResidenceRepository _residenceRepository;

  void setReportType(ReportType type) =>
      emit(state.copyWith(selectedType: type));

  void setResidence(String id) => emit(state.copyWith(selectedResidenceId: id));

  /// Charge le parc du propriétaire pour peupler le sélecteur.
  ///
  /// Un échec n'empêche pas de générer un rapport : la sentinelle « Toutes mes
  /// résidences » reste seule proposée, et le rapport porte alors sur
  /// l'ensemble du parc — exactement ce que produirait un `residence_id` omis.
  /// Bloquer l'écran pour ça priverait le propriétaire d'un rapport qu'il
  /// pourrait obtenir sans le filtre.
  Future<void> loadResidences() async {
    emit(state.copyWith(isLoadingResidences: true));

    try {
      final residences = await _residenceRepository.getAllResidences();
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoadingResidences: false,
            residences: [
              allResidencesOption,
              for (final residence in residences)
                ReportResidenceOption(id: residence.id, name: residence.name),
            ],
          ),
        );
      }
    } on AppFailure {
      if (!isClosed) emit(state.copyWith(isLoadingResidences: false));
    }
  }

  void setPreset(PeriodPreset preset) =>
      emit(state.copyWith(selectedPreset: preset));

  void setCustomDates(DateTime start, DateTime end) =>
      emit(state.copyWith(customStart: start, customEnd: end));

  Future<void> generate() async {
    emit(
      state.copyWith(isGenerating: true, clearResult: true, clearError: true),
    );

    try {
      final result = await _repository.generate(
        type: state.selectedType,
        preset: state.selectedPreset,
        customStart: state.customStart,
        customEnd: state.customEnd,
        residenceId: state.selectedResidenceId,
      );
      if (!isClosed) {
        emit(state.copyWith(isGenerating: false, result: result));
      }
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(isGenerating: false, errorMessage: f.userMessage));
      }
    }
  }
}
