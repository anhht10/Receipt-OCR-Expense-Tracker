import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeeklyBarChart extends StatefulWidget {
  final Map<int, int> weeklyData; // 1 (Mon) -> 7 (Sun)

  const WeeklyBarChart({super.key, required this.weeklyData});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayWeekday = DateTime.now().weekday;

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 200),
            painter: WeeklyExpenseChart(
              weeklyData: widget.weeklyData,
              animationProgress: _animation.value,
              todayWeekday: todayWeekday,
              primaryColor: theme.colorScheme.primary,
              barColor: theme.colorScheme.primary.withValues(alpha: 0.35),
              gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              textColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          );
        },
      ),
    );
  }
}

class WeeklyExpenseChart extends CustomPainter {
  final Map<int, int> weeklyData;
  final double animationProgress;
  final int todayWeekday;
  final Color primaryColor;
  final Color barColor;
  final Color gridColor;
  final Color textColor;

  WeeklyExpenseChart({
    required this.weeklyData,
    required this.animationProgress,
    required this.todayWeekday,
    required this.primaryColor,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  static const List<String> _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final chartWidth = size.width;

    // Determine max value for scaling
    int maxVal = 0;
    for (int day = 1; day <= 7; day++) {
      final val = weeklyData[day] ?? 0;
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) {
      maxVal = 100000; // default baseline for empty state
    }

    // 1. Draw horizontal grid lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 2; i++) {
      final y = topPadding + chartHeight * (1.0 - (i / 2.0));
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. Draw bars
    final totalBars = 7;
    final slotWidth = chartWidth / totalBars;
    final barWidth = math.min(slotWidth * 0.55, 30.0);

    for (int day = 1; day <= 7; day++) {
      final amount = weeklyData[day] ?? 0;
      final xCenter = slotWidth * (day - 0.5);
      final isToday = day == todayWeekday;

      // Bar height animated
      final barHeight = (amount / maxVal) * chartHeight * animationProgress;
      final clampedHeight = barHeight < 0 ? 0.0 : barHeight;

      final barLeft = xCenter - barWidth / 2;
      final barTop = topPadding + chartHeight - clampedHeight;
      final barRect = Rect.fromLTWH(barLeft, barTop, barWidth, clampedHeight);

      final paint = Paint()
        ..color = isToday ? primaryColor : barColor
        ..style = PaintingStyle.fill;

      if (clampedHeight > 0) {
        final rrect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(rrect, paint);
      }

      // Draw value text if amount > 0 and animated progress is reasonably high
      if (amount > 0 && animationProgress > 0.6) {
        final valueText = _formatCompact(amount);
        final valPainter = TextPainter(
          text: TextSpan(
            text: valueText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday ? primaryColor : textColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valPainter.layout();
        valPainter.paint(
          canvas,
          Offset(xCenter - valPainter.width / 2, barTop - valPainter.height - 3),
        );
      }

      // Draw day label at the bottom
      final label = _dayLabels[day - 1];
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? primaryColor : textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(xCenter - labelPainter.width / 2, size.height - bottomLabelHeight + 4),
      );
    }
  }

  String _formatCompact(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toString();
  }

  @override
  bool shouldRepaint(covariant WeeklyExpenseChart oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.weeklyData != weeklyData ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.barColor != barColor;
  }
}

