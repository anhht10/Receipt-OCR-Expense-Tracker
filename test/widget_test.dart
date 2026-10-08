import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_receipt_scanner/core/utils/formatters.dart';
import 'package:vku_receipt_scanner/features/dashboard/presentation/widgets/category_donut_chart.dart';
import 'package:vku_receipt_scanner/features/dashboard/presentation/widgets/weekly_bar_chart.dart';
import 'package:vku_receipt_scanner/features/receipt_scanner/domain/parsed_receipt.dart';
import 'package:vku_receipt_scanner/features/receipt_scanner/presentation/review_receipt_screen.dart';
import 'package:vku_receipt_scanner/widgets/amount_text.dart';
import 'package:vku_receipt_scanner/widgets/empty_state.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('1. EmptyState displays title and message properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Chưa có hóa đơn nào',
              message: 'Hãy quét hóa đơn đầu tiên của bạn.',
              actionLabel: 'Quét ngay',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Chưa có hóa đơn nào'), findsOneWidget);
      expect(find.text('Hãy quét hóa đơn đầu tiên của bạn.'), findsOneWidget);
      expect(find.text('Quét ngay'), findsOneWidget);
    });

    testWidgets('2. AmountText formats integer VND currency correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmountText(amount: 125000),
          ),
        ),
      );

      expect(find.text(CurrencyFormatter.format(125000)), findsOneWidget);
    });

    testWidgets('3. ReviewReceiptScreen renders extracted OCR data in editable fields', (tester) async {
      final tempFile = File('${Directory.systemTemp.path}/test_receipt.jpg');
      if (!tempFile.existsSync()) {
        tempFile.writeAsBytesSync([0, 1, 2]);
      }

      const parsed = ParsedReceipt(
        merchant: 'CĂN TIN VKU',
        totalAmount: 45000,
        suggestedCategory: 'food',
        confidenceScore: 0.9,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReviewReceiptScreen(
              imageFile: tempFile,
              parsedReceipt: parsed,
              rawOcrText: 'CĂN TIN VKU\nTOTAL 45000',
            ),
          ),
        ),
      );

      expect(find.text('CĂN TIN VKU'), findsOneWidget);
      expect(find.text('45000'), findsOneWidget);
      expect(find.text('Xác nhận thông tin hóa đơn'), findsOneWidget);
      expect(find.text('Lưu hóa đơn vào sổ'), findsOneWidget);
    });

    testWidgets('4. ReviewReceiptScreen validates required fields on submission', (tester) async {
      final tempFile = File('${Directory.systemTemp.path}/test_receipt_empty.jpg');
      if (!tempFile.existsSync()) {
        tempFile.writeAsBytesSync([0, 1, 2]);
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReviewReceiptScreen(
              imageFile: tempFile,
              parsedReceipt: null,
            ),
          ),
        ),
      );

      // Tap Save button when fields are empty
      await tester.tap(find.text('Lưu hóa đơn vào sổ'));
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Vui lòng nhập tên đơn vị / cửa hàng'), findsOneWidget);
      expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
    });

    testWidgets('5. Custom CategoryDonutChart renders without errors', (tester) async {
      final data = {
        'food': 100000,
        'study': 50000,
        'transport': 30000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDonutChart(data: data),
          ),
        ),
      );

      // Verify widget builds and pump animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CategoryDonutChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('6. Custom WeeklyBarChart renders without errors', (tester) async {
      final weeklyData = {
        1: 50000,
        2: 0,
        3: 120000,
        4: 45000,
        5: 80000,
        6: 0,
        7: 35000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(weeklyData: weeklyData),
          ),
        ),
      );

      // Verify widget builds and pump animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WeeklyBarChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
