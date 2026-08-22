import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';

/// Type de bien.
///
/// Les valeurs proposées sont celles de l'énumération de l'API : un type sans
/// équivalent côté serveur serait refusé par le validateur, quel que soit son
/// libellé à l'écran.
class StepTypeWidget extends StatelessWidget {
  const StepTypeWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PropertyType? selected;
  final void Function(PropertyType) onSelected;

  static const _icons = <PropertyType, FaIconData>{
    PropertyType.apartment: FontAwesomeIcons.building,
    PropertyType.studio: FontAwesomeIcons.bed,
    PropertyType.villa: FontAwesomeIcons.umbrellaBeach,
    PropertyType.duplex: FontAwesomeIcons.hotel,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quel type de bien souhaitez-vous enregistrer ?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: PropertyType.values.length,
          itemBuilder: (_, i) {
            final type = PropertyType.values[i];
            final isSelected = selected == type;
            return GestureDetector(
              onTap: () => onSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.black : AppColors.grey200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      _icons[type] ?? FontAwesomeIcons.building,
                      size: 18,
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.white,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
