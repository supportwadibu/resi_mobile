import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/finance/revenue_point_model.dart';

class RevenueChart extends StatelessWidget {
  final List<RevenuePointModel> points;

  const RevenueChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Évolution des revenus mensuels',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ChartPainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        _MonthLabels(points: points),
      ],
    );
  }
}

class _MonthLabels extends StatelessWidget {
  final List<RevenuePointModel> points;

  const _MonthLabels({required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: points
          .map((p) => Text(p.month, style: AppTextStyles.labelSmall))
          .toList(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RevenuePointModel> points;

  const _ChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double minVal = 0;
    final double maxVal =
        points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.15;
    final double valueRange = maxVal - minVal;

    // Y axis labels
    final yLabels = [0, 5500, 11000, 16500, 22000];
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    const double labelWidth = 36;

    for (final label in yLabels) {
      final y = size.height - ((label - minVal) / valueRange) * size.height;
      labelPaint.text = TextSpan(
        text: label == 0
            ? '0k'
            : '${(label / 1000).toStringAsFixed(label % 1000 == 0 ? 0 : 1)}k',
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      labelPaint.layout();
      labelPaint.paint(canvas, Offset(0, y - labelPaint.height / 2));

      // Grid line
      if (label > 0) {
        final gridPaint = Paint()
          ..color = AppColors.chartGrid
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(labelWidth + 8, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
    }

    final double chartLeft = labelWidth + 8;
    final double chartWidth = size.width - chartLeft;

    // Convert data points to canvas coordinates
    List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = chartLeft + (i / (points.length - 1)) * chartWidth;
      final y =
          size.height - ((points[i].value - minVal) / valueRange) * size.height;
      offsets.add(Offset(x, y));
    }

    // Draw line
    final linePaint = Paint()
      ..color = AppColors.chartLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      final cp1 = Offset(
        (offsets[i - 1].dx + offsets[i].dx) / 2,
        offsets[i - 1].dy,
      );
      final cp2 = Offset(
        (offsets[i - 1].dx + offsets[i].dx) / 2,
        offsets[i].dy,
      );
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        offsets[i].dx,
        offsets[i].dy,
      );
    }
    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = AppColors.chartDot
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final offset in offsets) {
      canvas.drawCircle(offset, 6, dotBorderPaint);
      canvas.drawCircle(offset, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
