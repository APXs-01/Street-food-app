import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A small line-and-area chart of scores, one point per label (for the vendor's
/// analytics, one per inspection). Drawn by hand, so the app needs no chart
/// package for one curve.
class RatingCurveChart extends StatelessWidget {
  const RatingCurveChart({
    super.key,
    required this.values,
    required this.labels,
    this.minY = 4.4,
    this.maxY = 5.0,
    this.step = 0.2,
    this.valueSuffix = '★',
    this.height = 150,
  });

  final List<double> values;
  final List<String> labels;

  /// The value at the bottom and top of the plot, with a gridline every [step].
  final double minY;
  final double maxY;
  final double step;

  /// Printed after each gridline value: `★` for star ratings, empty for scores.
  final String valueSuffix;
  final double height;

  /// Room on the left for the "4.8★" labels.
  static const double gutter = 38;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _CurvePainter(values: values, minY: minY, maxY: maxY, step: step, suffix: valueSuffix)),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: gutter),
          child: Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.values, required this.minY, required this.maxY, required this.step, required this.suffix});

  final List<double> values;
  final double minY;
  final double maxY;
  final double step;
  final String suffix;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(RatingCurveChart.gutter, 6, size.width - RatingCurveChart.gutter, size.height - 12);

    double yFor(double rating) => plot.bottom - (rating.clamp(minY, maxY) - minY) / (maxY - minY) * plot.height;

    // Gridlines and their labels, every [step].
    final grid = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    for (var rating = minY; rating <= maxY + 0.001; rating += step) {
      final y = yFor(rating);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);

      final label = TextPainter(
        text: TextSpan(text: '${rating.toStringAsFixed(1)}$suffix', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    if (values.isEmpty) return;

    // One point per slot, centred under its label.
    final slot = plot.width / values.length;
    final points = [for (var i = 0; i < values.length; i++) Offset(plot.left + slot * (i + 0.5), yFor(values[i]))];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      // Smooth between points with a control point halfway along.
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      line.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondary.withValues(alpha: 0.28), AppColors.secondary.withValues(alpha: 0)],
        ).createShader(plot),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final highest = values.indexOf(values.reduce((a, b) => a > b ? a : b));

    for (var i = 0; i < points.length; i++) {
      final isPeak = i == highest;

      canvas.drawCircle(points[i], isPeak ? 6 : 4.5, Paint()..color = AppColors.surface);
      canvas.drawCircle(
        points[i],
        isPeak ? 6 : 4.5,
        Paint()
          ..color = isPeak ? AppColors.amber : AppColors.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.values != values || old.minY != minY || old.maxY != maxY || old.step != step || old.suffix != suffix;
}
