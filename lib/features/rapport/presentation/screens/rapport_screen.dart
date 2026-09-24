import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../business_logic/report_form_cubit.dart';
import '../../business_logic/report_form_state.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/generate_button.dart';
import '../widgets/period_preset_selector.dart';
import '../widgets/residence_selector.dart';
import '../widgets/report_type_selector.dart';
import '../widgets/section.dart';

@RoutePage()
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportFormCubit>()..loadResidences(),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

  /// Ouvre le rapport, écrit localement, dans l'application qui sait lire un
  /// PDF.
  ///
  /// L'échec est traité ici plutôt que laissé remonter : `OpenFilex.open` ne
  /// lève pas, il rend un [OpenResult] dont le `type` vaut autre chose que
  /// [ResultType.done] quand aucun lecteur PDF n'est installé — sans ce
  /// contrôle, le bouton finirait son chargement sans que rien ne se passe.
  Future<void> _openReport(BuildContext context, String filePath) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await OpenFilex.open(filePath);
    if (result.type == ResultType.done) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Impossible d\'ouvrir le rapport. Installez une application capable de lire un PDF.',
          style: AppTextStyles.valueSmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Générer un rapport',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReportFormCubit, ReportFormState>(
        listener: (context, state) {
          final result = state.result;
          if (result != null) {
            _openReport(context, result.filePath);
          }
          final error = state.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error,
                  style: AppTextStyles.valueSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<ReportFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Section(
                  title: 'Type de rapport',
                  child: ReportTypeSelector(
                    selected: state.selectedType,
                    onChanged: cubit.setReportType,
                  ),
                ),
                const SizedBox(height: 20),

                // Résidences
                Section(
                  title: 'Résidences concernées',
                  child: ResidenceSelector(
                    residences: state.residences,
                    selectedId: state.selectedResidenceId,
                    onChanged: cubit.setResidence,
                  ),
                ),
                const SizedBox(height: 20),

                // Période
                Section(
                  title: 'Période',
                  child: Column(
                    children: [
                      PeriodPresetSelector(
                        selected: state.selectedPreset,
                        onChanged: cubit.setPreset,
                      ),
                      if (state.isCustomPeriod) ...[
                        const SizedBox(height: 12),
                        CustomDatePicker(
                          startDate: state.customStart,
                          endDate: state.customEnd,
                          onPicked: (range) =>
                              cubit.setCustomDates(range.start, range.end),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton générer
                GenerateButton(
                  isLoading: state.isGenerating,
                  enabled: state.canGenerate,
                  onTap: cubit.generate,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
