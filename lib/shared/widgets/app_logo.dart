import 'package:flutter/material.dart';

/// Logo RESI, miroir du composant `Logo` du backoffice.
///
/// Le fichier est noir sur fond transparent : inversé en mode sombre, sans
/// quoi il disparaîtrait sur le fond noir. L'inversion garde le logo bicolore
/// (pastille blanche, maison noire) au lieu d'exiger une seconde version.
///
/// `onMedia` : posé sur une photo assombrie, le logo est toujours en blanc,
/// quel que soit le mode.
class AppLogo extends StatelessWidget {
  const AppLogo({this.height = 32, this.onMedia = false, super.key});

  final double height;
  final bool onMedia;

  static const _invert = ColorFilter.matrix([
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/resi_logo.png',
      height: height,
      // Proportions du fichier (1136 × 412) : la largeur est réservée avant
      // le décodage, et rien ne saute à l'affichage.
      width: height * 1136 / 412,
      semanticLabel: 'RESI',
    );
    final invert = onMedia || Theme.of(context).brightness == Brightness.dark;
    return invert ? ColorFiltered(colorFilter: _invert, child: image) : image;
  }
}
