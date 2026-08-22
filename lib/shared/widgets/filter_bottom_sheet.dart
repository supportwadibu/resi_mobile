// lib/shared/widgets/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key, this.onApply});

  final void Function(FilterData)? onApply;

  static Future<FilterData?> show(BuildContext context) {
    return showModalBottomSheet<FilterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedType;
  final _locationCtrl = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 500);

  static const _types = [
    _TypeItem(icon: FontAwesomeIcons.building, label: 'Appartement'),
    _TypeItem(icon: FontAwesomeIcons.bed, label: 'Studio'),
    _TypeItem(icon: FontAwesomeIcons.umbrellaBeach, label: 'Villa'),
    _TypeItem(icon: FontAwesomeIcons.hotel, label: 'Duplex'),
  ];

  void _reset() {
    setState(() {
      _selectedType = null;
      _locationCtrl.clear();
      _priceRange = const RangeValues(0, 500);
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FilterData(
        type: _selectedType,
        location: _locationCtrl.text.trim(),
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      ),
    );
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle + titre
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Text(
                'Filtrer les biens',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Type de propriété
          const Text(
            'Type de propriété',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final type = _types[i];
                final isSelected = _selectedType == type.label;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = isSelected ? null : type.label;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.black : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.black : AppColors.grey200,
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          type.icon,
                          size: 13,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.grey500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Emplacement
          AppTextField(
            label: 'Emplacement',
            hint: 'Rechercher une commune...',
            controller: _locationCtrl,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            keyboardType: TextInputType.streetAddress,
          ),

          const SizedBox(height: 24),

          // ── Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prix (k FCFA / jour)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Text(
                '${_priceRange.start.toInt()}k — ${_priceRange.end.toInt()}k',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppColors.black,
            inactiveColor: AppColors.grey200,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0k',
                style: TextStyle(fontSize: 11, color: AppColors.grey500),
              ),
              Text(
                '500k',
                style: TextStyle(fontSize: 11, color: AppColors.grey500),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Boutons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Réinitialiser',
                  onPressed: _reset,
                  variant: AppButtonVariant.secondary,
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Filtrer',
                  onPressed: _apply,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  leadingIcon: AppButtonIcon.material(Icons.tune_rounded),
                  backgroundColor: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Modèles
// ─────────────────────────────────────────
class _TypeItem {
  const _TypeItem({required this.icon, required this.label});
  final FaIconData icon;
  final String label;
}

class FilterData {
  const FilterData({this.type, this.location, this.minPrice, this.maxPrice});

  final String? type;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
}
