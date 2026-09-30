import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import '../../business_logic/report_form_cubit.dart';
import '../../business_logic/report_form_state.dart';
import '../../data/models/report_type_model.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/generate_button.dart';
import '../widgets/period_preset_selector.dart';
import '../widgets/residence_selector.dart';
import '../widgets/report_type_selector.dart';

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
    final result = await OpenFilex.open(filePath);
    if (result.type == ResultType.done) return;

    AppToast.error(
      'Impossible d\'ouvrir le rapport. Installez une application capable '
      'de lire un PDF.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Générer un rapport'),
      bottomNavigationBar: BlocBuilder<ReportFormCubit, ReportFormState>(
        builder: (context, state) => GenerateButton(
          isLoading: state.isGenerating,
          enabled: state.canGenerate,
          onTap: context.read<ReportFormCubit>().generate,
        ),
      ),
      body: BlocConsumer<ReportFormCubit, ReportFormState>(
        listener: (context, state) {
          final result = state.result;
          if (result != null) {
            _openReport(context, result.filePath);
          }
          final error = state.errorMessage;
          if (error != null) AppToast.error(error, context: context);
        },
        builder: (context, state) {
          final cubit = context.read<ReportFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Section(
                  title: 'Type de rapport',
                  icon: AppSectionIcons.reports,
                  child: ReportTypeSelector(
                    selected: state.selectedType,
                    onChanged: cubit.setReportType,
                  ),
                ),
                const SizedBox(height: 12),

                // Résidences
                Section(
                  title: 'Résidences concernées',
                  icon: AppSectionIcons.residences,
                  child: ResidenceSelector(
                    residences: state.residences,
                    selectedId: state.selectedResidenceId,
                    onChanged: cubit.setResidence,
                  ),
                ),
                const SizedBox(height: 12),

                // La commune n'existe dans aucune donnée : le registre de
                // police l'exige en tête, elle se saisit ici. Vide, la ville
                // de la résidence en tient lieu.
                if (state.selectedType == ReportType.police) ...[
                  Section(
                    title: 'report_police.commune'.tr(),
                    icon: LucideIcons.mapPin,
                    child: TextFormField(
                      initialValue: state.commune,
                      onChanged: cubit.setCommune,
                      style: context.text.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'report_police.commune_hint'.tr(),
                        helperText: 'report_police.commune_helper'.tr(),
                        helperMaxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Période
                Section(
                  title: 'Période',
                  icon: LucideIcons.calendarRange,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
