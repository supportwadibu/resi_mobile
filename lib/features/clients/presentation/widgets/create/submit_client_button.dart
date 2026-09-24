import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class SubmitClientButton extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  /// Le défaut porte l'enregistrement d'un nouveau client ; l'édition d'une
  /// fiche existante le remplace.
  final String label;

  const SubmitClientButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    this.label = 'Enregistrer le client',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled && !isLoading ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: enabled ? AppColors.black : AppColors.divider,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
