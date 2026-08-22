import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: Colors.white,
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
            primary: Colors.black,
            onPrimary: Colors.white,
            onSurface: Colors.black,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Filtrer les dépenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            const Text('Bien', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            _PropertyChips(
              properties: widget.properties,
              selected: _propertyId,
              onSelected: (id) => setState(() => _propertyId = id),
            ),

            const SizedBox(height: 20),

            const Text('Catégorie', style: TextStyle(fontSize: 13)),
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

            const Text('Période', style: TextStyle(fontSize: 13)),
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
                  color: const Color(0xffF5F5FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _from != null && _to != null
                            ? '${_dateFormat.format(_from!)} → ${_dateFormat.format(_to!)}'
                            : 'Toutes les dates',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_from != null || _to != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _from = null;
                          _to = null;
                        }),
                        child: const Icon(Icons.close, size: 18),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Réinitialiser'),
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
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Appliquer',
                      style: TextStyle(color: Colors.white),
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
      return Text(
        'Aucun bien enregistré',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
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
          color: selected ? Colors.black : const Color(0xffF5F5FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xff1D2452),
          ),
        ),
      ),
    );
  }
}
