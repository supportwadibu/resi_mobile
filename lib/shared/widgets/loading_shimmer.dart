import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

/// Bloc gris animé, brique de base des squelettes de chargement.
///
/// Se dimensionne comme le contenu qu'il remplace : un squelette n'a d'intérêt
/// que s'il occupe la place et la forme des données à venir, sinon la mise en
/// page saute à l'arrivée du contenu.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, this.height, this.width, this.radius});

  final double? height;
  final double? width;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 16,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(radius ?? 8),
      ),
    );
  }
}

/// Anime en balayage tous les [LoadingShimmer] de son sous-arbre.
///
/// Une seule animation pilote l'ensemble du squelette : chaque bloc pulsant
/// pour son compte produirait un scintillement désordonné, et autant de
/// contrôleurs que de blocs.
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            AppColors.grey200,
            AppColors.grey100,
            AppColors.grey200,
          ],
          stops: const [0.1, 0.5, 0.9],
          // Le dégradé traverse la zone de gauche à droite en boucle.
          transform: _SlidingGradient(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Translate le dégradé horizontalement selon l'avancement de l'animation.
class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // De -1 à +1 fois la largeur : le balayage entre par la gauche et sort
    // entièrement par la droite avant de recommencer.
    return Matrix4.translationValues(
      bounds.width * (progress * 2 - 1),
      0,
      0,
    );
  }
}
