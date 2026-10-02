import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
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

  static const _icons = <PropertyType, IconData>{
    PropertyType.apartment: LucideIcons.building2,
    PropertyType.studio: LucideIcons.bed,
    PropertyType.villa: LucideIcons.umbrella,
    PropertyType.duplex: LucideIcons.hotel,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'property_form.which_type'.tr(),
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 16),
        for (final type in PropertyType.values) ...[
          AppOptionTile(
            icon: _icons[type] ?? LucideIcons.building2,
            title: type.label,
            selected: selected == type,
            onTap: () => onSelected(type),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
