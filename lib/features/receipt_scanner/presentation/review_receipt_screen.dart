import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../domain/parsed_receipt.dart';
import '../../receipts/providers/receipts_provider.dart';

class ReviewReceiptScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final ParsedReceipt? parsedReceipt;
  final String? rawOcrText;

  const ReviewReceiptScreen({
    super.key,
    required this.imageFile,
    this.parsedReceipt,
    this.rawOcrText,
  });

  @override
  ConsumerState<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends ConsumerState<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedReceipt?.merchant ?? '',
    );
    _amountController = TextEditingController(
      text: widget.parsedReceipt?.totalAmount != null
          ? widget.parsedReceipt!.totalAmount.toString()
          : '',
    );
    _selectedDate = widget.parsedReceipt?.date ?? DateTime.now();
    _selectedCategory = widget.parsedReceipt?.suggestedCategory ?? 'food';
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY HÓA ĐƠN',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final id = const Uuid().v4();
      final merchant = _merchantController.text.trim();
      final totalAmount = int.parse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));

      await ref.read(receiptListProvider.notifier).addReceipt(
            id: id,
            merchant: merchant,
            totalAmount: totalAmount,
            date: _selectedDate,
            category: _selectedCategory,
            imageFile: widget.imageFile,
            rawOcrText: widget.rawOcrText,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu hóa đơn "$merchant" thành công!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu hóa đơn: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận thông tin hóa đơn'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Receipt Image Preview
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: widget.imageFile.existsSync()
                            ? Image.file(
                                widget.imageFile,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 160,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48),
                                ),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.parsedReceipt != null &&
                                        widget.parsedReceipt!.confidenceScore > 0.6
                                    ? 'ML Kit OCR đã tự động trích xuất thông tin'
                                    : 'Vui lòng kiểm tra và chỉnh sửa lại nếu OCR nhận diện chưa chuẩn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Merchant input
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Tên cửa hàng / Đơn vị (Merchant) *',
                    hintText: 'VD: Căn tin VKU, Highlands Coffee...',
                    prefixIcon: Icon(Icons.store_mall_directory_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên đơn vị / cửa hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Amount input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tổng tiền (VND) *',
                    hintText: 'VD: 125000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: '₫',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số tiền';
                    }
                    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
                    final parsed = int.tryParse(cleaned);
                    if (parsed == null || parsed <= 0) {
                      return 'Số tiền phải là số nguyên dương hợp lệ';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                if (_amountController.text.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      'Bằng chữ/định dạng: ${CurrencyFormatter.format(int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 4. Date selector
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngày giao dịch *',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.format(_selectedDate),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Category selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục chi tiêu *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  items: ExpenseCategory.all.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 20, color: cat.color),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newCat) {
                    if (newCat != null) {
                      setState(() {
                        _selectedCategory = newCat;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 6. Raw OCR text expandable tile for inspection/debugging
                if (widget.rawOcrText != null && widget.rawOcrText!.isNotEmpty)
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.developer_mode_outlined),
                      title: const Text(
                        'Xem văn bản OCR thô (Raw OCR)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText(
                            widget.rawOcrText!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // 7. Save Action Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveReceipt,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu hóa đơn vào sổ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

