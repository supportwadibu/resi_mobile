import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_cubit.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_state.dart';
import 'package:resi_africa/features/rapport/data/models/period_preset_model.dart';
import 'package:resi_africa/features/rapport/data/models/report_type_model.dart';
import 'package:resi_africa/features/rapport/presentation/widgets/custom_date_picker.dart';
import 'package:resi_africa/features/rapport/presentation/widgets/generate_button.dart';
import 'package:resi_africa/features/rapport/presentation/widgets/period_preset_selector.dart';
import 'package:resi_africa/features/rapport/presentation/widgets/report_type_selector.dart';
import 'package:resi_africa/features/rapport/presentation/widgets/residence_selector.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Génération d'un rapport PDF, d'après les maquettes : type en tuiles,
/// résidence et période en puces, récapitulatif sable, bouton dans une barre
/// de verre. Rien ne part tant que le propriétaire n'a pas appuyé sur
/// « Générer ».
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
  static Future<void> _openReport(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type == ResultType.done) return;
    AppToast.error('report.open_failed'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'report.title'.tr()),
      extendBody: true,
      bottomNavigationBar: BlocBuilder<ReportFormCubit, ReportFormState>(
        builder: (context, state) => GenerateButton(
          isLoading: state.isGenerating,
          enabled: state.canGenerate && !state.isGenerating,
          onTap: context.read<ReportFormCubit>().generate,
        ),
      ),
      body: BlocConsumer<ReportFormCubit, ReportFormState>(
        // Le PDF ne s'ouvre qu'à l'arrivée d'un **nouveau** rapport. Sans ce
        // filtre, tout changement de choix après une génération — un autre
        // type, une autre période — rouvrait l'ancien fichier, resté dans
        // l'état.
        listenWhen: (previous, current) =>
            (current.result != null &&
                !identical(previous.result, current.result)) ||
            (current.errorMessage != null &&
                previous.errorMessage != current.errorMessage),
        listener: (context, state) {
          final result = state.result;
          if (result != null) _openReport(result.filePath);
          final error = state.errorMessage;
          if (error != null) AppToast.error(error, context: context);
        },
        builder: (context, state) {
          final cubit = context.read<ReportFormCubit>();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('report.subtitle'.tr(), style: context.mutedText),
              ),
              const SizedBox(height: 20),
              _Heading(number: 1, title: 'report.type'.tr()),
              ReportTypeSelector(
                selected: state.selectedType,
                onChanged: cubit.setReportType,
              ),
              const SizedBox(height: 24),
              _Heading(number: 2, title: 'report.residences'.tr()),
              ResidenceSelector(
                residences: state.residences,
                selectedId: state.selectedResidenceId,
                onChanged: cubit.setResidence,
              ),
              // La commune n'existe dans aucune donnée : le registre de police
              // l'exige en tête, elle se saisit ici. Vide, la ville de la
              // résidence en tient lieu.
              if (state.selectedType == ReportType.police) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: state.commune,
                  onChanged: cubit.setCommune,
                  style: context.text.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'report_police.commune'.tr(),
                    hintText: 'report_police.commune_hint'.tr(),
                    helperText: 'report_police.commune_helper'.tr(),
                    helperMaxLines: 2,
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _Heading(number: 3, title: 'report.period'.tr()),
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
              const SizedBox(height: 24),
              _Summary(state: state),
              if (state.result case final result?) ...[
                const SizedBox(height: 10),
                _LastReport(
                  filename: result.filename,
                  onOpen: () => _openReport(result.filePath),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Intitulé d'une étape : numéro sur disque, titre.
class _Heading extends StatelessWidget {
  const _Heading({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
            child: SizedBox.square(
              dimension: 26,
              child: Center(
                child: Text(
                  '$number',
                  style: context.text.labelMedium!.copyWith(
                    color: t.primaryForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: context.text.titleMedium),
        ],
      ),
    );
  }
}

/// Récapitulatif sable : ce que le bouton va produire, relu d'un coup d'œil.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final ReportFormState state;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final residence = state.residences
        .where((r) => r.id == state.selectedResidenceId)
        .map((r) => r.id == allResidencesOption.id ? r.name.tr() : r.name)
        .firstOrNull;
    String period = state.selectedPreset.label;
    if (state.isCustomPeriod &&
        state.customStart != null &&
        state.customEnd != null) {
      final f = DateFormat.yMMMd(Localizations.localeOf(context).toString());
      period =
          '${f.format(state.customStart!)} → ${f.format(state.customEnd!)}';
    }
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: t.onSand.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium!.copyWith(color: t.onSand),
            ),
          ),
        ],
      ),
    );
    return Material(
      color: t.sand,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: HaloSurface(
        radius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'report.summary'.tr(),
                style: context.text.labelMedium!.copyWith(
                  color: t.onSand.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.selectedType.label,
                style: context.text.titleLarge!.copyWith(color: t.onSand),
              ),
              line(LucideIcons.building2, residence ?? '—'),
              line(LucideIcons.calendarRange, period),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dernier rapport produit pendant la visite : le rouvrir sans le refaire.
class _LastReport extends StatelessWidget {
  const _LastReport({required this.filename, required this.onOpen});

  final String filename;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      shape: AppRadius.outlined(AppRadius.lg, t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.accentVioletSoft,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    LucideIcons.fileText,
                    size: 18,
                    color: t.accentViolet,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'report.last_report'.tr(),
                      style: context.text.bodySmall,
                    ),
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.arrowUpRight, size: 16, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }
}
