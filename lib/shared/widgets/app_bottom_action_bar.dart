import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

/// Barre d'actions ancrée en bas d'écran, hors de la zone scrollable.
///
/// L'action principale occupe deux fois la largeur de l'action secondaire,
/// qui disparaît quand [secondaryLabel] est absent — le cas de la première
/// étape d'un parcours, ou d'un écran à action unique.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
    this.secondaryIcon,
    this.isLoading = false,
    this.footer,
  }) : assert(
         secondaryLabel == null || onSecondary != null,
         'secondaryLabel nécessite onSecondary',
       );

  final String primaryLabel;

  /// `null` désactive le bouton — utilisé pendant un chargement bloquant.
  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final AppButtonIcon? primaryIcon;
  final AppButtonIcon? secondaryIcon;

  final bool isLoading;

  /// Lien discret sous les boutons (« Plus tard », mentions…).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: AppButton(
                    label: secondaryLabel!,
                    onPressed: isLoading ? null : onSecondary,
                    variant: AppButtonVariant.secondary,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    leadingIcon: secondaryIcon,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: AppButton(
                  label: primaryLabel,
                  onPressed: onPrimary,
                  isLoading: isLoading,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  trailingIcon: primaryIcon,
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}
