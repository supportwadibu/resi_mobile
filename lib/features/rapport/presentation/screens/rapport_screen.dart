import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../business_logic/report_form_cubit.dart';
import '../../business_logic/report_form_state.dart';
import '../../data/models/report_fake_data.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/generate_button.dart';
import '../widgets/period_preset_selector.dart';
import '../widgets/property_selector.dart';
import '../widgets/report_type_selector.dart';
import '../widgets/section.dart';

@RoutePage()
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportFormCubit(),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

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
      body: BlocBuilder<ReportFormCubit, ReportFormState>(
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

                // Propriétés
                Section(
                  title: 'Propriétés concernées',
                  child: PropertySelector(
                    properties: ReportFakeData.properties,
                    selectedId: state.selectedPropertyId,
                    onChanged: cubit.setProperty,
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
