import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';

class CategoryItem extends StatelessWidget {
  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                // La teinte du poste reste visible une fois sélectionné :
                // c'est elle qui identifie la catégorie d'un écran à l'autre,
                // y compris dans l'anneau des statistiques.
                color: category.color.withValues(alpha: selected ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, size: 17, color: category.color),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
