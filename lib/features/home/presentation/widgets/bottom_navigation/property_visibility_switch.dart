import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
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
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        AppCallout(
          icon: isPublished ? LucideIcons.eye : LucideIcons.eyeOff,
          tone: isPublished ? AppAccent.green : AppAccent.neutral,
          title: isPublished
              ? 'property_detail.online'.tr()
              : 'property_detail.offline'.tr(),
          message: isPublished
              ? 'property_detail.visible'.tr()
              : 'property_detail.hidden'.tr(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: isBusy
              // Occupe la largeur de la bascule, pour que la ligne ne
              // tressaute pas le temps de l'appel.
              ? const SizedBox(width: 52, child: AppLoader(size: 20))
              : Switch(value: isPublished, onChanged: onChanged),
        ),
      ],
    );
  }
}
