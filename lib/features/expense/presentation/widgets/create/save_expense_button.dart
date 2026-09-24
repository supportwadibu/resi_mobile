import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class SaveExpenseButton extends StatelessWidget {
  /// `null` désactive le bouton — pendant l'envoi, par exemple.
  final VoidCallback? onPressed;

  /// Libellé de remplacement, pour distinguer création et modification.
  final String? label;

  /// Envoi en cours : le bouton montre un indicateur à côté de son libellé.
  ///
  /// Passé explicitement plutôt que déduit du libellé : une comparaison de
  /// chaîne ferait disparaître l'indicateur au premier remaniement du texte,
  /// sans rien signaler.
  final bool isBusy;

  const SaveExpenseButton({
    super.key,
    required this.onPressed,
    this.label,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.grey400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label ?? 'Enregistrer la dépense',
              style: AppTextStyles.valueSmall.copyWith(
                color: AppColors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
