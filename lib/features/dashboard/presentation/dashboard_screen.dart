import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/receipt_card.dart';
import '../../receipts/presentation/receipt_detail_screen.dart';
import '../../receipts/providers/receipts_provider.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/weekly_bar_chart.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToScan;
  final VoidCallback onNavigateToHistory;

  const DashboardScreen({
    super.key,
    required this.onNavigateToScan,
    required this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản Lý Chi Tiêu VKU',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Dành cho Sinh viên & Ban Chủ nhiệm CLB',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: dashboardAsync.when(
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(receiptListProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Summary Metrics Cards (Total, Receipts Count, This Week)
                  Row(
                    children: [
                      // Total Spending Card (Large)
                      Expanded(
                        flex: 3,
                        child: _buildMetricCard(
                          context,
                          title: 'Tổng chi tiêu',
                          amount: CurrencyFormatter.format(data.totalSpending),
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: theme.colorScheme.primary,
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Receipt Count Card
                      Expanded(
                        flex: 2,
                        child: _buildMetricCard(
                          context,
                          title: 'Số hóa đơn',
                          amount: '${data.receiptCount}',
                          icon: Icons.receipt_long_outlined,
                          iconColor: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // This Week Card
                  _buildMetricCard(
                    context,
                    title: 'Chi tiêu tuần này (T2 - CN)',
                    amount: CurrencyFormatter.format(data.thisWeekSpending),
                    icon: Icons.calendar_view_week_outlined,
                    iconColor: Colors.deepOrange,
                  ),
                  const SizedBox(height: 18),

                  // 2. Custom Weekly Bar Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Chi tiêu theo các ngày trong tuần',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Icon(
                                Icons.bar_chart_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Biểu đồ CustomPainter vẽ bằng Canvas API',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          WeeklyBarChart(weeklyData: data.weeklySpending),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Custom Donut Category Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phân bổ theo danh mục',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Icon(
                                Icons.donut_large_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tỉ lệ phần trăm các nhóm chi tiêu',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CategoryDonutChart(data: data.categorySpending),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Recent Receipts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hóa đơn gần đây',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (data.recentReceipts.isNotEmpty)
                        TextButton(
                          onPressed: onNavigateToHistory,
                          child: const Text('Xem tất cả'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (data.recentReceipts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 8),
                              const Text('Chưa có hóa đơn nào được lưu.'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: onNavigateToScan,
                                icon: const Icon(Icons.document_scanner, size: 18),
                                label: const Text('Quét hóa đơn ngay'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...data.recentReceipts.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: ReceiptCard(
                          receipt: r,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiptDetailScreen(receipt: r),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingView(message: 'Đang chuẩn bị số liệu thống kê...'),
        error: (err, _) => Center(
          child: Text('Lỗi tải thống kê: $err'),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      color: highlight
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : theme.cardTheme.shape is RoundedRectangleBorder
                  ? (theme.cardTheme.shape as RoundedRectangleBorder).side.color
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: highlight ? theme.colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

