import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';

/// Commodités du bien.
///
/// La liste est celle des clés reconnues par l'API : le serveur attend un
/// objet de booléens à clés fixes, et toute commodité hors de cette liste
/// serait rejetée par le validateur. Les libellés affichés viennent de
/// l'énumération, ce qui interdit tout écart entre écran et charge utile.
class StepAmenitiesWidget extends StatelessWidget {
  const StepAmenitiesWidget({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<Amenity> selected;
  final void Function(Set<Amenity>) onChanged;

  static const _icons = <Amenity, FaIconData>{
    Amenity.wifi: FontAwesomeIcons.wifi,
    Amenity.airConditioning: FontAwesomeIcons.snowflake,
    Amenity.heating: FontAwesomeIcons.fire,
    Amenity.elevator: FontAwesomeIcons.elevator,
    Amenity.balcony: FontAwesomeIcons.doorOpen,
    Amenity.terrace: FontAwesomeIcons.umbrellaBeach,
    Amenity.garden: FontAwesomeIcons.tree,
    Amenity.pool: FontAwesomeIcons.personSwimming,
    Amenity.gym: FontAwesomeIcons.dumbbell,
    Amenity.security: FontAwesomeIcons.shieldHalved,
    Amenity.concierge: FontAwesomeIcons.bellConcierge,
    Amenity.parking: FontAwesomeIcons.car,
    Amenity.petFriendly: FontAwesomeIcons.dog,
    Amenity.smokingAllowed: FontAwesomeIcons.smoking,
  };

  void _toggle(Amenity amenity) {
    final updated = Set<Amenity>.from(selected);
    if (!updated.remove(amenity)) updated.add(amenity);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quelles commodités propose votre bien ?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${selected.length} sélectionnée(s)',
          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
          ),
          itemCount: Amenity.values.length,
          itemBuilder: (_, i) {
            final amenity = Amenity.values[i];
            final isSelected = selected.contains(amenity);

            return GestureDetector(
              onTap: () => _toggle(amenity),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.black : AppColors.grey200,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      _icons[amenity] ?? FontAwesomeIcons.check,
                      size: 13,
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        amenity.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.white : AppColors.black,
                        ),
                      ),
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
