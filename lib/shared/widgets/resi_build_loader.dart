import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/resi_tokens.dart';

/// Attente de l'accueil : le logo RESI se construit comme un chantier —
/// fondations, murs, toit, puis le repère qui se pose dans la maison.
///
/// Réservé aux attentes plein écran de l'accueil. Une liste ou une fiche
/// garde `AppLoader` : rejouer le chantier à chaque page lasserait.
///
/// Trait à la couleur du texte, lisible dans les deux modes. Avec les
/// animations réduites du système, le logo s'affiche construit, immobile.
class ResiBuildLoader extends StatefulWidget {
  const ResiBuildLoader({super.key, this.size = 96});

  final double size;

  @override
  State<ResiBuildLoader> createState() => _ResiBuildLoaderState();
}

class _ResiBuildLoaderState extends State<ResiBuildLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _BuildPainter.built;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _BuildPainter(
            progress: _controller,
            color: context.tokens.foreground,
          ),
        ),
      ),
    );
  }
}

/// Plein écran, au fond de page.
class ResiBuildLoaderScreen extends StatelessWidget {
  const ResiBuildLoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: const Center(child: ResiBuildLoader()),
    );
  }
}

/// Dessine le logo dans un repère de 100 × 100, mis à l'échelle.
class _BuildPainter extends CustomPainter {
  _BuildPainter({required this.progress, required this.color})
    : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  /// Instant où le logo est complet : l'image figée des animations réduites.
  static const built = 0.88;

  // Phases du chantier, en fraction du cycle.
  static const _ground = (0.0, 0.16);
  static const _walls = (0.16, 0.36);
  static const _roof = (0.36, 0.54);
  static const _pin = (0.54, 0.76);
  static const _dot = (0.76, 0.86);
  static const _fadeOut = (0.94, 1.0);

  /// Avancement d'une phase entre 0 et 1, adouci.
  static double _phase(
    (double, double) span,
    double t, [
    Curve curve = Curves.easeInOut,
  ]) {
    final (start, end) = span;
    final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  /// Trace la portion [amount] d'un segment, de [from] vers [to].
  static void _segment(
    Canvas canvas,
    Paint paint,
    Offset from,
    Offset to,
    double amount,
  ) {
    if (amount <= 0) return;
    canvas.drawLine(from, Offset.lerp(from, to, amount)!, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale);

    final opacity = 1 - _phase(_fadeOut, t);
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fondations : de gauche à droite, plus larges que la maison.
    _segment(
      canvas,
      paint,
      const Offset(14, 84),
      const Offset(86, 84),
      _phase(_ground, t),
    );

    // Murs : les deux montent ensemble depuis la dalle.
    final walls = _phase(_walls, t);
    _segment(canvas, paint, const Offset(24, 84), const Offset(24, 48), walls);
    _segment(canvas, paint, const Offset(76, 84), const Offset(76, 48), walls);

    // Toit : les deux pans se rejoignent au faîte.
    final roof = _phase(_roof, t);
    _segment(canvas, paint, const Offset(24, 48), const Offset(50, 22), roof);
    _segment(canvas, paint, const Offset(76, 48), const Offset(50, 22), roof);

    // Repère : il descend et se pose, en se dessinant.
    final pin = _phase(_pin, t, Curves.easeOutBack);
    if (pin > 0) {
      canvas.save();
      canvas.translate(0, (1 - pin) * -26);
      final path = _pinPath();
      final drawn = Path();
      final amount = _phase(_pin, t);
      for (final PathMetric metric in path.computeMetrics()) {
        drawn.addPath(
          metric.extractPath(0, metric.length * amount),
          Offset.zero,
        );
      }
      canvas.drawPath(drawn, paint);
      canvas.restore();
    }

    // Point central : il apparaît une fois le repère posé.
    final dot = _phase(_dot, t, Curves.easeOutBack);
    if (dot > 0) {
      canvas.drawCircle(const Offset(50, 55), 4.5 * dot, paint);
    }

    canvas.restore();
  }

  /// Goutte du repère : un cercle ouvert vers le bas, prolongé jusqu'à sa
  /// pointe, posée sur la dalle.
  static Path _pinPath() {
    const center = Offset(50, 55);
    const radius = 13.0;
    const tip = Offset(50, 80);
    // Angles en repère écran (y vers le bas) : 135° en bas à gauche, le cercle
    // parcouru par le haut jusqu'à 45° en bas à droite.
    const start = 135 * math.pi / 180;
    const sweep = 270 * math.pi / 180;
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        center.dx + radius * math.cos(start),
        center.dy + radius * math.sin(start),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_BuildPainter old) => old.color != color;
}
