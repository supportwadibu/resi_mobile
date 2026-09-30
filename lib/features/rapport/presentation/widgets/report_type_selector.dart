import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import '../../data/models/report_type_model.dart';

class ReportTypeSelector extends StatelessWidget {
  final ReportType selected;
  final ValueChanged<ReportType> onChanged;

  const ReportTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _icons = {
    ReportType.financial: LucideIcons.trendingUp,
    ReportType.performance: LucideIcons.chartColumn,
    ReportType.reservations: LucideIcons.users,
    ReportType.police: LucideIcons.shield,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final type in ReportType.values) ...[
          AppOptionTile(
            icon: _icons[type],
            title: type.label,
            description: type.description,
            selected: type == selected,
            onTap: () => onChanged(type),
          ),
          if (type != ReportType.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
