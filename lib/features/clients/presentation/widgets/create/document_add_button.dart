import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class DocumentAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const DocumentAddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: AppColors.green),
            const SizedBox(height: 4),
            Text(
              'Ajouter',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}
