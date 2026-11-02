import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
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

  static const _icons = <Amenity, IconData>{
    Amenity.wifi: LucideIcons.wifi,
    Amenity.airConditioning: LucideIcons.snowflake,
    Amenity.heating: LucideIcons.flame,
    Amenity.elevator: LucideIcons.arrowUpDown,
    Amenity.balcony: LucideIcons.doorOpen,
    Amenity.terrace: LucideIcons.umbrella,
    Amenity.garden: LucideIcons.treePine,
    Amenity.pool: LucideIcons.waves,
    Amenity.gym: LucideIcons.dumbbell,
    Amenity.security: LucideIcons.shieldHalf,
    Amenity.concierge: LucideIcons.conciergeBell,
    Amenity.parking: LucideIcons.car,
    Amenity.petFriendly: LucideIcons.dog,
    Amenity.smokingAllowed: LucideIcons.cigarette,
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
        Text(
          'property_form.which_amenities'.tr(),
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'property_form.selected_count'.tr(args: ['${selected.length}']),
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amenity in Amenity.values)
              AppChoiceChip(
                label: amenity.label,
                icon: _icons[amenity] ?? LucideIcons.check,
                selected: selected.contains(amenity),
                onTap: () => _toggle(amenity),
              ),
          ],
        ),
      ],
    );
  }
}
