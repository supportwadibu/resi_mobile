import 'dart:math';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import '../../../data/models/expense_category_model.dart';

class DonutChart extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;
  final double size;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.categories,
    this.size = 200,
    this.strokeWidth = 38,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          categories: categories,
          strokeWidth: strokeWidth,
          tokens: context.tokens,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ExpenseCategoryModel> categories;
  final double strokeWidth;

  /// Jetons du mode courant : la couleur d'un poste en dépend.
  final ResiTokens tokens;

  const _DonutPainter({
    required this.categories,
    required this.strokeWidth,
    required this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final total = categories.fold(0.0, (sum, c) => sum + c.amount);

    // Des postes tous à zéro donneraient un `NaN` à la première division, et
    // `drawArc` peinerait sur un angle invalide.
    if (total <= 0) return;

    const double gap = 0.025; // radians gap between segments
    const double startAngle = -pi / 2;
    double currentAngle = startAngle;

    for (final category in categories) {
      final sweep = (category.amount / total) * (2 * pi) - gap;

      final paint = Paint()
        ..color = category.category.colorIn(tokens)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        // Extrémités droites, comme tout le reste de l'interface.
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + gap / 2,
        sweep,
        false,
        paint,
      );

      currentAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.categories != categories || old.tokens != tokens;
}
