import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/period_preset_model.dart';
import '../data/models/report_type_model.dart';
import 'report_form_state.dart';

class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit() : super(const ReportFormState());

  void setReportType(ReportType type) =>
      emit(state.copyWith(selectedType: type));

  void setProperty(String id) => emit(state.copyWith(selectedPropertyId: id));

  void setPreset(PeriodPreset preset) =>
      emit(state.copyWith(selectedPreset: preset));

  void setCustomDates(DateTime start, DateTime end) =>
      emit(state.copyWith(customStart: start, customEnd: end));

  Future<void> generate() async {
    emit(state.copyWith(isGenerating: true));
    await Future.delayed(const Duration(seconds: 2));
    emit(state.copyWith(isGenerating: false));
  }
}
