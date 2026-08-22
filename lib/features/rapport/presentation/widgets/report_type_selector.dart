import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    ReportType.financial: Icons.trending_up_rounded,
    ReportType.performance: Icons.bar_chart_rounded,
    ReportType.maintenance: Icons.build_rounded,
    ReportType.reservations: Icons.people_alt_rounded,
    ReportType.fiscal: Icons.receipt_long_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ReportType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.black.withOpacity(0.08)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.black.withOpacity(0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _icons[type],
                    size: 18,
                    color: isSelected
                        ? AppColors.black
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: AppTextStyles.valueSmall.copyWith(
                          color: isSelected
                              ? AppColors.black
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(type.description, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.black,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
