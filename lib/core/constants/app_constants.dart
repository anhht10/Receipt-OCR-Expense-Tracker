import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'VKU Expense Receipt Scanner';
  static const String appSubtitle = 'Dành cho Sinh viên & Ban Chủ nhiệm CLB VKU';
  static const String currencySuffix = 'VND';
  static const String dbName = 'vku_receipts.db';
  static const int dbVersion = 1;
  static const String receiptsDirectoryName = 'receipts';
}

/// Predefined expense categories suitable for university students and club activities
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      id: 'food',
      name: 'Ăn uống (Food)',
      icon: Icons.restaurant,
      color: Color(0xFFEF5350), // Red
    ),
    ExpenseCategory(
      id: 'equipment',
      name: 'Thiết bị CLB (Equipment)',
      icon: Icons.build_circle_outlined,
      color: Color(0xFF42A5F5), // Blue
    ),
    ExpenseCategory(
      id: 'study',
      name: 'Học tập & In ấn (Study)',
      icon: Icons.menu_book,
      color: Color(0xFF66BB6A), // Green
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Đi lại (Transportation)',
      icon: Icons.directions_bus,
      color: Color(0xFFFFA726), // Orange
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Liên hoan & Sự kiện (Events)',
      icon: Icons.celebration,
      color: Color(0xFFAB47BC), // Purple
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Khác (Other)',
      icon: Icons.category,
      color: Color(0xFF78909C), // Blue Grey
    ),
  ];

  static ExpenseCategory findById(String id) {
    return all.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
      orElse: () => all.last,
    );
  }

  static Color getColor(String id) {
    return findById(id).color;
  }
}

