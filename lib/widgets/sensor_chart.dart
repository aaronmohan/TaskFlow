import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/iot_reading.dart';

/// Clean, responsive line chart widget for sensor telemetry history.
/// Built with Flutter's CustomPainter for high performance, zero external dependencies,
/// and full Material 3 theme compatibility.
class SensorChart extends StatelessWidget {
  final String title;
  final String unit;
  final Color accentColor;
  final List<IoTReading> readings;
  final double? Function(IoTReading) valueExtractor;

  const SensorChart({
    super.key,
    required this.title,
    required this.unit,
    required this.accentColor,
    required this.readings,
    required this.valueExtractor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter valid data points, convert timestamp to local device timezone, and sort chronologically
    final validPoints = <_ChartPoint>[];
    for (int i = 0; i < readings.length; i++) {
      final val = valueExtractor(readings[i]);
      if (val != null && !val.isNaN && !val.isInfinite) {
        // Keep DateTime internally timezone-aware and convert to local for display
        final localTime = readings[i].createdAt.toLocal();
        validPoints.add(_ChartPoint(time: localTime, value: val));
      }
    }

    // Ensure readings are ordered chronologically (oldest on left, newest on right)
    validPoints.sort((a, b) => a.time.compareTo(b.time));

    if (validPoints.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: theme.colorScheme.onSurfaceVariant, size: 36),
            const SizedBox(height: 8),
            Text(
              title.toLowerCase().endsWith('history')
                  ? 'No $title available yet'
                  : 'No $title history available yet',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    double minVal = validPoints.first.value;
    double maxVal = validPoints.first.value;
    for (final p in validPoints) {
      if (p.value < minVal) minVal = p.value;
      if (p.value > maxVal) maxVal = p.value;
    }

    // Add slight headroom to chart bounds; if identical, create a flat range around the value
    if (minVal == maxVal) {
      minVal -= 1.0;
      maxVal += 1.0;
    } else {
      final padding = (maxVal - minVal) * 0.15;
      minVal -= padding;
      maxVal += padding;
    }

    final latestVal = validPoints.last.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${latestVal.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Min / Max summary row
          Row(
            children: [
              Text(
                'Min: ${validPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Max: ${validPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${validPoints.length} ${validPoints.length == 1 ? 'sample' : 'samples'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Canvas Chart
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _SensorChartPainter(
                points: validPoints,
                minVal: minVal,
                maxVal: maxVal,
                lineColor: accentColor,
                gridColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                unit: unit,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Time labels (First and Last, localized to device timezone)
          if (validPoints.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: DateFormat('d MMM y, h:mm:ss a').format(validPoints.first.time),
                  child: Text(
                    DateFormat('h:mm a').format(validPoints.first.time),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Tooltip(
                  message: DateFormat('d MMM y, h:mm:ss a').format(validPoints.last.time),
                  child: Text(
                    DateFormat('h:mm a').format(validPoints.last.time),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          else if (validPoints.length == 1)
            Center(
              child: Tooltip(
                message: DateFormat('d MMM y, h:mm:ss a').format(validPoints.first.time),
                child: Text(
                  DateFormat('h:mm a').format(validPoints.first.time),
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final DateTime time;
  final double value;
  const _ChartPoint({required this.time, required this.value});
}

class _SensorChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final double minVal;
  final double maxVal;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final String unit;

  _SensorChartPainter({
    required this.points,
    required this.minVal,
    required this.maxVal,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal reference lines (top, mid, bottom)
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);

    final range = maxVal - minVal;
    if (range <= 0) return;

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final normalizedY = (points[i].value - minVal) / range;
      final y = size.height - (normalizedY * size.height);
      offsets.add(Offset(x, y.clamp(0.0, size.height)));
    }

    // Gradient fill and stroke line (when 2 or more points exist)
    if (offsets.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(offsets.first.dx, size.height);
      for (final pt in offsets) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(offsets.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withAlpha(60),
            lineColor.withAlpha(0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Stroke line
      final linePath = Path();
      linePath.moveTo(offsets.first.dx, offsets.first.dy);
      for (int i = 1; i < offsets.length; i++) {
        linePath.lineTo(offsets[i].dx, offsets[i].dy);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw circular dots on points
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in offsets) {
      canvas.drawCircle(pt, 3.5, dotPaint);
      canvas.drawCircle(pt, 1.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SensorChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minVal != minVal ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.lineColor != lineColor;
  }
}
