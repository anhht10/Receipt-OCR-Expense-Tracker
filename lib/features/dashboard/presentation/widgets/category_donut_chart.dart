import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<String, int> data;

  const CategoryDonutChart({super.key, required this.data});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
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
    final total = widget.data.values.fold<int>(0, (sum, val) => sum + val);

    if (total == 0 || widget.data.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu chi tiêu',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: ReceiptCategoryChart(
                  categorySpending: widget.data,
                  animationProgress: _animation.value,
                  surfaceColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                  primaryTextColor: theme.colorScheme.onSurface,
                  secondaryTextColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.entries.where((e) => e.value > 0).map((entry) {
            final category = ExpenseCategory.findById(entry.key);
            final percent = (entry.value / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${category.name.split(' ').first}: $percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ReceiptCategoryChart extends CustomPainter {
  final Map<String, int> categorySpending;
  final double animationProgress;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  ReceiptCategoryChart({
    required this.categorySpending,
    required this.animationProgress,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 32.0;

    final total = categorySpending.values.fold<int>(0, (sum, val) => sum + val);

    if (total == 0) {
      final emptyPaint = Paint()
        ..color = secondaryTextColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius - strokeWidth / 2, emptyPaint);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double currentAngle = -math.pi / 2; // Start at 12 o'clock

    for (final entry in categorySpending.entries) {
      final amount = entry.value;
      if (amount <= 0) continue;

      final sweepAngle = (amount / total) * 2 * math.pi * animationProgress;
      final categoryColor = ExpenseCategory.getColor(entry.key);

      final paint = Paint()
        ..color = categoryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
    }

    // Draw inner center text (total summary)
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Tổng chi\n',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          TextSpan(
            text: CurrencyFormatter.format(total),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: radius * 1.3);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ReceiptCategoryChart oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.categorySpending != categorySpending ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.primaryTextColor != primaryTextColor;
  }
}

