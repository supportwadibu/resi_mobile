import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class DatePickerField extends StatelessWidget {
  final String date;
  final VoidCallback onTap;

  const DatePickerField({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Text(date, style: AppTextStyles.valueSmall),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
