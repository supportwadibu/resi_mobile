import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
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
    return showModalBottomSheet<ExpenseFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

  static final _dateFormat = DateFormat('d MMM y', 'fr');

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.black,
            onPrimary: AppColors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Filtrer les dépenses',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 20),

            Text('Bien', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            _PropertyChips(
              properties: widget.properties,
              selected: _propertyId,
              onSelected: (id) => setState(() => _propertyId = id),
            ),

            const SizedBox(height: 20),

            Text('Catégorie', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ExpenseCategory.values)
                  _Chip(
                    label: category.label,
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

            Text('Période', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _from != null && _to != null
                            ? '${_dateFormat.format(_from!)} → ${_dateFormat.format(_to!)}'
                            : 'Toutes les dates',
                        style: _from != null && _to != null
                            ? AppTextStyles.valueSmall
                            : AppTextStyles.labelMedium,
                      ),
                    ),
                    if (_from != null || _to != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _from = null;
                          _to = null;
                        }),
                        child: const Icon(
                          Icons.close,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const ExpenseFilters()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.grey200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Réinitialiser',
                      style: AppTextStyles.valueSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      ExpenseFilters(
                        propertyId: _propertyId,
                        category: _category,
                        from: _from,
                        to: _to,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Appliquer',
                      style: AppTextStyles.valueSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      return Text('Aucun bien enregistré', style: AppTextStyles.labelMedium);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final property in properties)
          _Chip(
            label: property.title,
            selected: selected == property.id,
            onTap: () =>
                onSelected(selected == property.id ? null : property.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
