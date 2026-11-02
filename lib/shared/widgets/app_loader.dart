import 'package:flutter/material.dart';

import '../../core/theme/resi_tokens.dart';

/// Indicateur d'attente : un anneau fin à la couleur du texte, comme le
/// backoffice. L'ancienne animation Lottie portait la couleur de marque, qui
/// n'existe plus, et restait claire en mode sombre.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 32, this.color});

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    // L'anneau plafonne à 28 : `size` réserve la place de l'ancienne
    // animation, bien plus large qu'un indicateur sobre.
    final ring = (size * 0.7).clamp(12.0, 28.0);
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: SizedBox.square(
          dimension: ring,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            strokeCap: StrokeCap.square,
            color: color ?? context.tokens.foreground,
          ),
        ),
      ),
    );
  }
}

/// Écran d'attente plein cadre, au fond de page.
class AppLoaderScreen extends StatelessWidget {
  const AppLoaderScreen({super.key, this.backgroundColor});

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.tokens.background,
      body: const Center(child: AppLoader()),
    );
  }
}
