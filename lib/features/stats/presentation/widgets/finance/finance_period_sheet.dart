import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../data/models/finance/finance_period.dart';

/// Choix de la période du relevé : douze mois glissants, une année entière ou
/// un mois de cette année.
///
/// L'année se parcourt aux flèches plutôt que dans une liste : elle n'a pas de
/// borne basse connue ici, et une liste d'années vides n'aiderait personne.
class FinancePeriodSheet extends StatefulWidget {
  const FinancePeriodSheet({super.key, required this.selected});

  final FinancePeriod selected;

  /// `null` si la feuille est fermée sans choix.
  static Future<FinancePeriod?> show(
    BuildContext context, {
    required FinancePeriod selected,
  }) {
    return showAppSheet<FinancePeriod>(
      context: context,
      builder: (_) => FinancePeriodSheet(selected: selected),
    );
  }

  @override
  State<FinancePeriodSheet> createState() => _FinancePeriodSheetState();
}

class _FinancePeriodSheetState extends State<FinancePeriodSheet> {
  final _currentYear = DateTime.now().year;

  /// Année parcourue, ouverte sur celle de la période retenue.
  late int _year = widget.selected.year ?? _currentYear;

  void _select(FinancePeriod period) => Navigator.of(context).pop(period);

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return AppSheet(
      title: 'finance_page.period_title'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppOptionTile(
            title: 'finance_page.rolling_year'.tr(),
            description: 'finance_page.rolling_year_hint'.tr(),
            icon: LucideIcons.history,
            selected: selected.isRolling,
            onTap: () => _select(const FinancePeriod.rolling()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppIconButton(
                icon: LucideIcons.chevronLeft,
                label: 'finance_page.previous_year'.tr(),
                onPressed: () => setState(() => _year--),
              ),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ),
              // Au-delà de l'année en cours, aucun relevé n'a de sens.
              AppIconButton(
                icon: LucideIcons.chevronRight,
                label: 'finance_page.next_year'.tr(),
                onPressed: _year < _currentYear
                    ? () => setState(() => _year++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppOptionTile(
            title: 'finance_page.whole_year'.tr(namedArgs: {'year': '$_year'}),
            icon: LucideIcons.calendarRange,
            selected: selected == FinancePeriod.year(_year),
            onTap: () => _select(FinancePeriod.year(_year)),
          ),
          const SizedBox(height: 12),
          _MonthGrid(
            year: _year,
            selectedMonth: selected.year == _year ? selected.month : null,
            onSelect: (month) => _select(FinancePeriod.month(_year, month)),
          ),
        ],
      ),
    );
  }
}

/// Les douze mois de l'année parcourue, sur quatre colonnes.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.selectedMonth,
    required this.onSelect,
  });

  final int year;
  final int? selectedMonth;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var month = 1; month <= 12; month++)
          // Centrée : étirée sur la cellule, la puce collerait son libellé à
          // gauche.
          Center(
            child: AppChoiceChip(
              // Le nom du mois vient d'intl, dans la langue de l'application ;
              // le français l'écrit en minuscule, d'où la majuscule ajoutée.
              label: toBeginningOfSentenceCase(
                DateFormat('MMM').format(DateTime(year, month)),
              ),
              selected: selectedMonth == month,
              onTap: () => onSelect(month),
            ),
          ),
      ],
    );
  }
}
