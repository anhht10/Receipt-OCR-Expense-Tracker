import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/receipt_model.dart';
import '../../../widgets/amount_text.dart';
import '../providers/receipts_provider.dart';
import 'edit_receipt_dialog.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final ReceiptModel receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  ConsumerState<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  late ReceiptModel _currentReceipt;

  @override
  void initState() {
    super.initState();
    _currentReceipt = widget.receipt;
  }

  Future<void> _editReceipt() async {
    final updated = await EditReceiptDialog.show(context, _currentReceipt);
    if (updated == true) {
      final refreshed = await ref.read(receiptDetailProvider(_currentReceipt.id).future);
      if (refreshed != null && mounted) {
        setState(() {
          _currentReceipt = refreshed;
        });
      }
    }
  }

  Future<void> _deleteReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hóa đơn?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa hóa đơn "${_currentReceipt.merchant}"? Tệp ảnh và dữ liệu sẽ được xóa hoàn toàn.',
        ),
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
      await ref.read(receiptListProvider.notifier).deleteReceipt(_currentReceipt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa hóa đơn thành công'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ExpenseCategory.findById(_currentReceipt.category);
    final imageFile = File(_currentReceipt.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: _editReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa',
            onPressed: _deleteReceipt,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Receipt Image Card with pinch-to-zoom
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (imageFile.existsSync()) {
                          _showFullImageDialog(context, imageFile);
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        width: double.infinity,
                        color: Colors.black,
                        child: imageFile.existsSync()
                            ? Image.file(
                                imageFile,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                height: 200,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                      ),
                    ),
                    if (imageFile.existsSync())
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Nhấn vào ảnh để phóng to toàn màn hình',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Main Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentReceipt.merchant,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: category.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(category.icon, size: 14, color: category.color),
                                          const SizedBox(width: 6),
                                          Text(
                                            category.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: category.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AmountText(
                            amount: _currentReceipt.totalAmount,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày giao dịch',
                        value: DateFormatter.format(_currentReceipt.date),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        icon: Icons.access_time_outlined,
                        label: 'Thời gian lưu',
                        value: DateFormatter.formatWithTime(_currentReceipt.createdAt),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        icon: Icons.image_outlined,
                        label: 'Vị trí tệp lưu trữ',
                        value: _currentReceipt.imagePath.split('/').last,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Raw OCR Debug/Inspect Card
              if (_currentReceipt.rawOcrText != null &&
                  _currentReceipt.rawOcrText!.trim().isNotEmpty)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.text_snippet_outlined),
                    title: const Text('Văn bản nhận diện từ Google ML Kit'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          _currentReceipt.rawOcrText!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showFullImageDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(file),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

