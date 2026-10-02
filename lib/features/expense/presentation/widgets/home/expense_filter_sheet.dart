import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../property/data/models/property_model.dart';
import '../../../business_logic/expense_state.dart';
import '../../../data/models/expense_model.dart';

/// Feuille de filtres de l'historique : bien, catégorie et période.
///
/// Retourne les filtres retenus, ou `null` si l'utilisateur ferme la feuille
/// sans valider — à distinguer d'une remise à zéro, qui renvoie des filtres
/// vides.
class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({
    super.key,
    required this.initial,
    required this.properties,
  });

  final ExpenseFilters initial;
  final List<PropertyModel> properties;

  static Future<ExpenseFilters?> show(
    BuildContext context, {
    required ExpenseFilters initial,
    required List<PropertyModel> properties,
  }) {
    return showAppSheet<ExpenseFilters>(
      context: context,
      builder: (_) =>
          ExpenseFilterSheet(initial: initial, properties: properties),
    );
  }

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late String? _propertyId = widget.initial.propertyId;
  late ExpenseCategory? _category = widget.initial.category;
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;

  static DateFormat get _dateFormat => DateFormat('d MMM y');

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasRange = _from != null && _to != null;
    return AppSheet(
      title: 'expense.filter_title'.tr(),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'expense.reset'.tr(),
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.pop(context, const ExpenseFilters()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'expense.apply'.tr(),
              expand: true,
              onPressed: () => Navigator.pop(
                context,
                ExpenseFilters(
                  propertyId: _propertyId,
                  category: _category,
                  from: _from,
                  to: _to,
                ),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('expense.property'.tr(), style: context.text.titleSmall),
          const SizedBox(height: 8),
          _PropertyChips(
            properties: widget.properties,
            selected: _propertyId,
            onSelected: (id) => setState(() => _propertyId = id),
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
          Material(
            color: t.background,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.md,
              side: BorderSide(color: t.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickRange,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: t.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasRange
                            ? '${_dateFormat.format(_from!)} → ${_dateFormat.format(_to!)}'
                            : 'expense.all_dates'.tr(),
                        style: hasRange
                            ? context.text.bodyMedium
                            : context.mutedText,
                      ),
                    ),
                    if (_from != null || _to != null)
                      InkWell(
                        onTap: () => setState(() {
                          _from = null;
                          _to = null;
                        }),
                        child: Icon(LucideIcons.x, size: 16, color: t.muted),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Biens sélectionnables. Réduit à un message si le parc est vide.
class _PropertyChips extends StatelessWidget {
  const _PropertyChips({
    required this.properties,
    required this.selected,
    required this.onSelected,
  });

  final List<PropertyModel> properties;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Text('expense.no_property'.tr(), style: context.mutedText);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final property in properties)
          AppChoiceChip(
            label: property.title,
            selected: selected == property.id,
            onTap: () =>
                onSelected(selected == property.id ? null : property.id),
          ),
      ],
    );
  }
}
