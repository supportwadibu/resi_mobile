import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class AddExpenseHeader extends StatelessWidget {
  const AddExpenseHeader({super.key, this.title});

  /// Titre de l'écran. Par défaut celui de la création.
  final String? title;

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
          title ?? 'Nouvelle dépense',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        const Spacer(),
        // Contrepoids de la flèche de retour : sans lui, le titre centré
        // par les deux `Spacer` se décale vers la droite.
        const SizedBox(width: 42),
      ],
    );
  }
}
