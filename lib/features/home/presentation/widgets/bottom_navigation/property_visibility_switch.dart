import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

/// Met l'annonce en ligne, ou la retire de la vitrine.
///
/// La bascule porte la visibilité — ce que le propriétaire décide — et non la
/// disponibilité, qui se déduit des réservations en cours et qu'aucun geste ne
/// doit pouvoir forcer.
class PropertyVisibilitySwitch extends StatelessWidget {
  const PropertyVisibilitySwitch({
    super.key,
    required this.isPublished,
    required this.onChanged,
    this.isBusy = false,
  });

  final bool isPublished;
  final ValueChanged<bool> onChanged;

  /// Appel en cours : la bascule reste à sa position tant que le serveur n'a
  /// pas confirmé. Un état optimiste mentirait quand la publication est
  /// refusée, faute de dossier d'identité déposé.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = isPublished ? AppColors.success : AppColors.grey600;
    final background = isPublished ? AppColors.successBg : AppColors.grey100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isPublished
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPublished ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  isPublished
                      ? 'Visible par les clients'
                      : 'Masquée dans la vitrine',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              // Occupe la largeur du bouton retiré, pour que la ligne ne
              // tressaute pas le temps de l'appel.
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: AppLoader(size: 20),
            )
          else
            Switch(
              value: isPublished,
              onChanged: onChanged,
              activeThumbColor: AppColors.success,
              activeTrackColor: AppColors.success.withValues(alpha: 0.35),
            ),
        ],
      ),
    );
  }
}
