import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = style ??
        TextStyle(
          color: color ?? theme.colorScheme.primary,
          fontSize: fontSize ?? 16,
          fontWeight: fontWeight ?? FontWeight.bold,
          letterSpacing: -0.2,
        );

    return Text(
      CurrencyFormatter.format(amount),
      style: effectiveStyle,
    );
  }
}

