import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/receipt_model.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/receipt_card.dart';
import '../providers/receipts_provider.dart';
import 'receipt_detail_screen.dart';

class ReceiptHistoryScreen extends ConsumerStatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  ConsumerState<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends ConsumerState<ReceiptHistoryScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hóa đơn'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên đơn vị / quán...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategory == 'all',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.all.map((cat) {
                  final isSelected = _selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 16, color: cat.color),
                      label: Text(cat.name.split(' ').first),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat.id : 'all';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: receiptsAsync.when(
              data: (receipts) {
                // Filter
                final filtered = receipts.where((r) {
                  final matchesCat =
                      _selectedCategory == 'all' || r.category == _selectedCategory;
                  final matchesSearch = _searchQuery.isEmpty ||
                      r.merchant.toLowerCase().contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: receipts.isEmpty
                        ? 'Chưa có hóa đơn nào'
                        : 'Không tìm thấy hóa đơn phù hợp',
                    message: receipts.isEmpty
                        ? 'Nhấn vào biểu tượng quét ảnh bên dưới để ghi nhận chi tiêu đầu tiên của bạn.'
                        : 'Thử tìm kiếm với từ khóa khác hoặc bỏ chọn bộ lọc danh mục.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(receiptListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final receipt = filtered[index];
                      return ReceiptCard(
                        receipt: receipt,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReceiptDetailScreen(receipt: receipt),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, receipt),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingView(message: 'Đang tải danh sách hóa đơn...'),
              error: (err, _) => Center(
                child: Text('Lỗi tải dữ liệu: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ReceiptModel receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hóa đơn?'),
        content: Text('Xác nhận xóa hóa đơn "${receipt.merchant}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(receiptListProvider.notifier).deleteReceipt(receipt.id);
    }
  }
}

