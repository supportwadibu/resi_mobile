import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../property/data/models/property_model.dart';
import '../../../../residence/data/models/residence_model.dart';
import '../../../business_logic/expense_state.dart';
import '../../../data/models/expense_model.dart';
import 'expense_month_stepper.dart';

/// Feuille de filtres de l'historique : bien ou résidence, catégorie et
/// période.
///
/// Retourne les filtres retenus, ou `null` si l'utilisateur ferme la feuille
/// sans valider — à distinguer d'une remise à zéro, qui renvoie les filtres
/// d'ouverture.
class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({
    super.key,
    required this.initial,
    required this.properties,
    required this.residences,
  });

  final ExpenseFilters initial;
  final List<PropertyModel> properties;
  final List<ResidenceModel> residences;

  static Future<ExpenseFilters?> show(
    BuildContext context, {
    required ExpenseFilters initial,
    required List<PropertyModel> properties,
    required List<ResidenceModel> residences,
  }) {
    return showAppSheet<ExpenseFilters>(
      context: context,
      builder: (_) => ExpenseFilterSheet(
        initial: initial,
        properties: properties,
        residences: residences,
      ),
    );
  }

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late String? _propertyId = widget.initial.propertyId;
  late String? _residenceId = widget.initial.residenceId;
  late ExpenseCategory? _category = widget.initial.category;
  late ExpensePeriodKind _periodKind = widget.initial.periodKind;

  /// Mois retenu en mode mensuel. Gardé même hors de ce mode : revenir sur
  /// « Par mois » retrouve le mois choisi plutôt que de repartir du mois en
  /// cours.
  late DateTime _month = widget.initial.month ?? _currentMonth;

  /// Plage retenue en mode libre, gardée de la même façon.
  late DateTimeRange? _range =
      widget.initial.periodKind == ExpensePeriodKind.range &&
          widget.initial.from != null &&
          widget.initial.to != null
      ? DateTimeRange(start: widget.initial.from!, end: widget.initial.to!)
      : null;

  static DateFormat get _dateFormat => DateFormat('d MMM y');

  static DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _range,
    );

    if (picked != null) setState(() => _range = picked);
  }

  /// Filtres à rendre. Une plage libre non choisie retombe sur tout
  /// l'historique : valider « Entre deux dates » sans dates ne doit pas
  /// laisser croire à un filtre.
  ExpenseFilters _result() {
    final base = ExpenseFilters(
      propertyId: _propertyId,
      residenceId: _residenceId,
      category: _category,
    );

    return switch (_periodKind) {
      ExpensePeriodKind.month => base.withMonth(_month),
      ExpensePeriodKind.range when _range != null => base.copyWith(
        periodKind: ExpensePeriodKind.range,
        from: _range!.start,
        to: _range!.end,
      ),
      _ => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'expense.filter_title'.tr(),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'expense.reset'.tr(),
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.pop(context, ExpenseFilters.initial()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'expense.apply'.tr(),
              expand: true,
              onPressed: () => Navigator.pop(context, _result()),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('expense.property'.tr(), style: context.text.titleSmall),
          const SizedBox(height: 8),
          _TargetChips(
            properties: widget.properties,
            residences: widget.residences,
            propertyId: _propertyId,
            residenceId: _residenceId,
            // Une dépense porte l'un ou l'autre rattachement : en retenir un
            // lève l'autre, faute de quoi la liste serait toujours vide.
            onProperty: (id) => setState(() {
              _propertyId = id;
              _residenceId = null;
            }),
            onResidence: (id) => setState(() {
              _residenceId = id;
              _propertyId = null;
            }),
          ),
          const SizedBox(height: 20),
          Text('expense.category'.tr(), style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ExpenseCategory.values)
                AppChoiceChip(
                  label: category.label,
                  icon: category.icon,
                  selected: _category == category,
                  // Retoucher le même choix l'annule : plus court qu'un
                  // bouton « toutes catégories ».
                  onTap: () => setState(
                    () => _category = _category == category ? null : category,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('expense.period'.tr(), style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ExpensePeriodKind.values)
                AppChoiceChip(
                  label: 'expense.period_kind.${kind.name}'.tr(),
                  selected: _periodKind == kind,
                  onTap: () => setState(() => _periodKind = kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          switch (_periodKind) {
            ExpensePeriodKind.month => ExpenseMonthStepper(
              month: _month,
              onPrevious: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
            ),
            ExpensePeriodKind.range => _RangeField(
              label: _range == null
                  ? null
                  : '${_dateFormat.format(_range!.start)} → '
                        '${_dateFormat.format(_range!.end)}',
              onTap: _pickRange,
              onClear: _range == null
                  ? null
                  : () => setState(() => _range = null),
            ),
            ExpensePeriodKind.all => Text(
              'expense.all_dates_hint'.tr(),
              style: context.mutedText,
            ),
          },
        ],
      ),
    );
  }
}

/// Résidences puis biens sélectionnables. Réduit à un message si le parc est
/// vide.
///
/// Une résidence retient ses charges communes **et** celles de ses logements :
/// c'est la question « que me coûte cette résidence ? ».
class _TargetChips extends StatelessWidget {
  const _TargetChips({
    required this.properties,
    required this.residences,
    required this.propertyId,
    required this.residenceId,
    required this.onProperty,
    required this.onResidence,
  });

  final List<PropertyModel> properties;
  final List<ResidenceModel> residences;
  final String? propertyId;
  final String? residenceId;
  final ValueChanged<String?> onProperty;
  final ValueChanged<String?> onResidence;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty && residences.isEmpty) {
      return Text('expense.no_property'.tr(), style: context.mutedText);
    }

    final residenceNames = {for (final r in residences) r.id: r.name};

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final residence in residences)
          AppChoiceChip(
            label: residence.name,
            icon: AppSectionIcons.residences,
            selected: residenceId == residence.id,
            onTap: () =>
                onResidence(residenceId == residence.id ? null : residence.id),
          ),
        for (final property in properties)
          AppChoiceChip(
            label: _propertyLabel(property, residenceNames),
            selected: propertyId == property.id,
            onTap: () =>
                onProperty(propertyId == property.id ? null : property.id),
          ),
      ],
    );
  }

  /// « Resi Adja › Studio 1 » pour une unité : deux résidences ont souvent
  /// chacune leur « Studio 1 », et le titre seul ne les distinguait pas.
  static String _propertyLabel(
    PropertyModel property,
    Map<String, String> residenceNames,
  ) {
    final residence = residenceNames[property.residenceId]?.trim();
    if (residence == null || residence.isEmpty) return property.title;

    final unit = property.unitLabel?.trim();
    return '$residence › ${unit == null || unit.isEmpty ? property.title : unit}';
  }
}

/// Champ de plage de dates, vide tant qu'aucune plage n'est choisie.
class _RangeField extends StatelessWidget {
  const _RangeField({required this.label, required this.onTap, this.onClear});

  final String? label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = this.label;
    return Material(
      color: t.background,
      shape: AppRadius.outlined(AppRadius.md, t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(LucideIcons.calendar, size: 16, color: t.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label ?? 'expense.choose_dates'.tr(),
                  style: label != null
                      ? context.text.bodyMedium
                      : context.mutedText,
                ),
              ),
              if (onClear case final clear?)
                InkWell(
                  onTap: clear,
                  child: Icon(LucideIcons.x, size: 16, color: t.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
