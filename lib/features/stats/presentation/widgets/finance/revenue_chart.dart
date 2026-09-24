import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/finance/revenue_point_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

const double _kLabelWidth = 40;
const double _kLabelGap = 8;
const double _kChartLeft = _kLabelWidth + _kLabelGap;
const double _kTopPadding = 14;
const int _kDivisions = 4;

const _kMonthLabels = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];

List<RevenuePointModel> buildSixMonthWindow(
  List<RevenuePointModel> data, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final byMonth = {for (final p in data) p.month: p};

  return List.generate(6, (i) {
    final d = DateTime(ref.year, ref.month - 3 + i, 1);
    final label = _kMonthLabels[d.month - 1];
    return byMonth[label] ?? RevenuePointModel(month: label, value: 0);
  });
}

double _niceStep(double raw) {
  if (raw <= 0) return 1000;
  final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / exp;
  final nice = f <= 1
      ? 1.0
      : f <= 2
      ? 2.0
      : f <= 2.5
      ? 2.5
      : f <= 5
      ? 5.0
      : 10.0;
  return nice * exp;
}

String _formatK(double v) {
  if (v == 0) return '0';
  if (v < 1000) return v.toStringAsFixed(0);
  final k = v / 1000;
  return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
}

class RevenueChart extends StatelessWidget {
  final List<RevenuePointModel> points;

  const RevenueChart({super.key, required this.points});

  @override
  @override
  Widget build(BuildContext context) {
    final window = buildSixMonthWindow(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Évolution des revenus mensuels',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: CustomPaint(
            painter: _ChartPainter(points: window, lastDataIndex: 3),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        _MonthLabels(points: window),
      ],
    );
  }
}

class _MonthLabels extends StatelessWidget {
  final List<RevenuePointModel> points;

  const _MonthLabels({required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _kChartLeft),
      child: LayoutBuilder(
        builder: (context, c) => SizedBox(
          height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < points.length; i++)
                Positioned(
                  left: (i / (points.length - 1)) * c.maxWidth - 24,
                  width: 48,
                  child: Text(
                    points[i].month,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RevenuePointModel> points;
  final int lastDataIndex;

  const _ChartPainter({required this.points, required this.lastDataIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final rawMax = points.map((p) => p.value).fold<double>(0, math.max);
    final step = _niceStep(rawMax <= 0 ? 4000 : rawMax / _kDivisions);
    final maxVal = step * _kDivisions;

    final chartHeight = size.height - _kTopPadding;
    final chartWidth = size.width - _kChartLeft;

    double yOf(double v) =>
        _kTopPadding + chartHeight - (v / maxVal) * chartHeight;
    double xOf(int i) => _kChartLeft + (i / (points.length - 1)) * chartWidth;

    // Axe Y + grille
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = AppColors.chartGrid
      ..strokeWidth = 1;

    for (int i = 0; i <= _kDivisions; i++) {
      final y = yOf(step * i);
      labelPainter.text = TextSpan(
        text: _formatK(step * i),
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(_kLabelWidth - labelPainter.width, y - labelPainter.height / 2),
      );
      canvas.drawLine(Offset(_kChartLeft, y), Offset(size.width, y), gridPaint);
    }

    // Courbe limitée aux mois réels
    final end = lastDataIndex.clamp(0, points.length - 1);
    if (end < 1) return;

    final offsets = [
      for (int i = 0; i <= end; i++) Offset(xOf(i), yOf(points[i].value)),
    ];

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      final midX = (offsets[i - 1].dx + offsets[i].dx) / 2;
      path.cubicTo(
        midX,
        offsets[i - 1].dy,
        midX,
        offsets[i].dy,
        offsets[i].dx,
        offsets[i].dy,
      );
    }

    // Remplissage dégradé
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.chartLine.withValues(alpha: 0.18),
            AppColors.chartLine.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.chartLine
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = AppColors.chartDot;
    final borderPaint = Paint()..color = Colors.white;
    for (final o in offsets) {
      canvas.drawCircle(o, 6, borderPaint);
      canvas.drawCircle(o, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.lastDataIndex != lastDataIndex ||
      old.points.length != points.length ||
      !listEquals(old.points, points);
}
