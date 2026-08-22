import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class ClientTextField extends StatelessWidget {
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const ClientTextField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? AppColors.red : AppColors.divider,
            ),
          ),
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: AppTextStyles.valueSmall,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.labelMedium,
              prefixIcon: Icon(
                prefixIcon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.red),
          ),
        ],
      ],
    );
  }
}
