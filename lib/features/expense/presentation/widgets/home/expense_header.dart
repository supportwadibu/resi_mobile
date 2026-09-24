import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class ExpenseHeader extends StatelessWidget {
  const ExpenseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => AutoRouter.of(context).maybePop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 17,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Dépenses',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        const Spacer(),
        GestureDetector(
          // Le rechargement de la liste au retour est pris en charge par
          // l'écran, via `didPopNext`.
          onTap: () => AutoRouter.of(context).push(AddExpenseRoute()),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.white, size: 21),
          ),
        ),
      ],
    );
  }
}
