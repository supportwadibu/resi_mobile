import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';

/// Logo Wave, seul moyen de versement des retraits.
///
/// Embarqué et non chargé du réseau : l'écran du portefeuille doit rester
/// lisible avec une connexion faible.
class WaveLogo extends StatelessWidget {
  const WaveLogo({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: Image.asset(
        'assets/images/wave.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Wave',
      ),
    );
  }
}
