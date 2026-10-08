import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/receipt_model.dart';
import '../providers/receipts_provider.dart';

class EditReceiptDialog extends ConsumerStatefulWidget {
  final ReceiptModel receipt;

  const EditReceiptDialog({super.key, required this.receipt});

  static Future<bool?> show(BuildContext context, ReceiptModel receipt) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EditReceiptDialog(receipt: receipt),
    );
  }

  @override
  ConsumerState<EditReceiptDialog> createState() => _EditReceiptDialogState();
}

class _EditReceiptDialogState extends ConsumerState<EditReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.receipt.merchant);
    _amountController = TextEditingController(text: widget.receipt.totalAmount.toString());
    _selectedDate = widget.receipt.date;
    _selectedCategory = widget.receipt.category;
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
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = widget.receipt.copyWith(
        merchant: _merchantController.text.trim(),
        totalAmount: int.parse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')),
        date: _selectedDate,
        category: _selectedCategory,
      );

      await ref.read(receiptListProvider.notifier).updateReceipt(updated);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Chỉnh sửa hóa đơn'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng *',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Bắt buộc nhập tên đơn vị' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tổng tiền (VND) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: '₫',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Bắt buộc nhập số tiền';
                  final parsed = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), ''));
                  if (parsed == null || parsed <= 0) return 'Số tiền phải là số nguyên dương';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(DateFormatter.format(_selectedDate)),
                      const Spacer(),
                      const Icon(Icons.edit, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExpenseCategory.all.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.name.split(' ').first),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (c) {
                  if (c != null) setState(() => _selectedCategory = c);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}

