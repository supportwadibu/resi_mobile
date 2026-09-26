import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import '../../data/models/period_preset_model.dart';

class PeriodPresetSelector extends StatelessWidget {
  final PeriodPreset selected;
  final ValueChanged<PeriodPreset> onChanged;

  const PeriodPresetSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in PeriodPreset.values)
          AppChoiceChip(
            label: preset.label,
            selected: preset == selected,
            onTap: () => onChanged(preset),
          ),
      ],
    );
  }
}
