import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

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
    final t = context.tokens;
    // Compact, une ligne par texte : l'encart complet passait sur trois
    // lignes à côté du bouton « Modifier » et déformait la barre.
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isPublished ? t.accentGreen : t.muted,
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPublished
                    ? 'property_detail.online'.tr()
                    : 'property_detail.offline'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
              Text(
                isPublished
                    ? 'property_detail.visible'.tr()
                    : 'property_detail.hidden'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        isBusy
            // Occupe la largeur de la bascule, pour que la ligne ne tressaute
            // pas le temps de l'appel.
            ? const SizedBox(width: 52, child: AppLoader(size: 20))
            : Switch(value: isPublished, onChanged: onChanged),
      ],
    );
  }
}
