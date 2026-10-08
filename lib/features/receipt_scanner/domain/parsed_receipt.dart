import 'package:flutter/foundation.dart';

@immutable
class ParsedReceipt {
  final String? merchant;
  final DateTime? date;
  final int? totalAmount;
  final String? suggestedCategory;
  final double confidenceScore;

  const ParsedReceipt({
    this.merchant,
    this.date,
    this.totalAmount,
    this.suggestedCategory,
    this.confidenceScore = 0.0,
  });

  @override
  String toString() {
    return 'ParsedReceipt(merchant: $merchant, date: $date, totalAmount: $totalAmount, category: $suggestedCategory)';
  }
}

