import 'package:flutter/foundation.dart';

/// Immutable model representing an expense receipt.
///
/// NOTE on [totalAmount]:
/// Stored strictly as an [int] representing Vietnamese Dong (VND).
/// In Vietnamese currency, there are no fractional subunit coins/cents (e.g., hao/xu).
/// Using an integer prevents floating-point precision errors (such as 125000.00000000001)
/// when performing aggregations, sums, and database queries.
@immutable
class ReceiptModel {
  final String id;
  final String merchant;
  final int totalAmount; // Stored as integer VND to prevent precision loss
  final DateTime date;
  final String category;
  final String imagePath;
  final String? rawOcrText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReceiptModel({
    required this.id,
    required this.merchant,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.imagePath,
    this.rawOcrText,
    required this.createdAt,
    required this.updatedAt,
  });

  ReceiptModel copyWith({
    String? id,
    String? merchant,
    int? totalAmount,
    DateTime? date,
    String? category,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'total_amount': totalAmount,
      'date': date.toIso8601String().split('T').first, // yyyy-MM-dd
      'category': category,
      'image_path': imagePath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as String,
      merchant: map['merchant'] as String,
      totalAmount: (map['total_amount'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      imagePath: map['image_path'] as String,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          merchant == other.merchant &&
          totalAmount == other.totalAmount &&
          date == other.date &&
          category == other.category &&
          imagePath == other.imagePath &&
          rawOcrText == other.rawOcrText &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      merchant.hashCode ^
      totalAmount.hashCode ^
      date.hashCode ^
      category.hashCode ^
      imagePath.hashCode ^
      (rawOcrText?.hashCode ?? 0) ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'ReceiptModel(id: $id, merchant: $merchant, totalAmount: $totalAmount, date: $date, category: $category)';
  }
}

