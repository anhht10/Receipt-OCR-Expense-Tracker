import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/providers/database_providers.dart';
import '../../receipts/providers/receipts_provider.dart';

@immutable
class DashboardData {
  final int totalSpending;
  final int receiptCount;
  final int thisWeekSpending;
  final Map<String, int> categorySpending;
  final Map<int, int> weeklySpending; // 1 (Mon) -> 7 (Sun)
  final List<ReceiptModel> recentReceipts;

  const DashboardData({
    required this.totalSpending,
    required this.receiptCount,
    required this.thisWeekSpending,
    required this.categorySpending,
    required this.weeklySpending,
    required this.recentReceipts,
  });

  factory DashboardData.empty() {
    return const DashboardData(
      totalSpending: 0,
      receiptCount: 0,
      thisWeekSpending: 0,
      categorySpending: {},
      weeklySpending: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0},
      recentReceipts: [],
    );
  }
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  // Watch receiptListProvider so any database modification automatically updates the dashboard
  final receiptsAsync = ref.watch(receiptListProvider);
  final repo = ref.watch(receiptRepositoryProvider);

  final receipts = receiptsAsync.value ?? await repo.getAllReceipts();

  final totalSpending = await repo.getTotalSpending();
  final receiptCount = receipts.length;

  final now = DateTime.now();
  final weeklyMap = await repo.getWeeklySpending(now);
  final categoryMap = await repo.getSpendingByCategory();

  int thisWeekSpending = 0;
  for (final amount in weeklyMap.values) {
    thisWeekSpending += amount;
  }

  final recentReceipts = receipts.take(5).toList();

  return DashboardData(
    totalSpending: totalSpending,
    receiptCount: receiptCount,
    thisWeekSpending: thisWeekSpending,
    categorySpending: categoryMap,
    weeklySpending: weeklyMap,
    recentReceipts: recentReceipts,
  );
});

