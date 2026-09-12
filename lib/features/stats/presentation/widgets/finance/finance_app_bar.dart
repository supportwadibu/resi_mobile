import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class FinanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinanceAppBar({super.key, this.onFilterTap, this.scopeLabel});

  /// Ouvre le choix du périmètre. Sans lui, l’entrée reste décorative.
  final VoidCallback? onFilterTap;

  /// Résidence retenue, affichée à la place du mot « Filtres ».
  ///
  /// Le périmètre doit se lire sans ouvrir la feuille : un relevé restreint et
  /// un relevé complet n’ont pas les mêmes chiffres, et rien d’autre à l’écran
  /// ne dit lequel on regarde.
  final String? scopeLabel;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Gestion Financière',
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
      ),
      centerTitle: true,
      actions: [
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  // Le nom d’une résidence peut être long : il est tronqué
                  // plutôt que de pousser le titre hors de l’écran.
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    scopeLabel ?? 'Filtres',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
