import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/repositories/receipt_repository.dart';

final receiptListProvider = AsyncNotifierProvider<ReceiptListNotifier, List<ReceiptModel>>(() {
  return ReceiptListNotifier();
});

class ReceiptListNotifier extends AsyncNotifier<List<ReceiptModel>> {
  IReceiptRepository get _repo => ref.read(receiptRepositoryProvider);

  @override
  Future<List<ReceiptModel>> build() async {
    return _repo.getAllReceipts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAllReceipts());
  }

  Future<void> addReceipt({
    required String id,
    required String merchant,
    required int totalAmount,
    required DateTime date,
    required String category,
    required File imageFile,
    String? rawOcrText,
  }) async {
    await _repo.createReceipt(
      id: id,
      merchant: merchant,
      totalAmount: totalAmount,
      date: date,
      category: category,
      imageFile: imageFile,
      rawOcrText: rawOcrText,
    );
    await refresh();
  }

  Future<void> updateReceipt(ReceiptModel receipt, {File? newImageFile}) async {
    await _repo.updateReceipt(receipt, newImageFile: newImageFile);
    await refresh();
  }

  Future<void> deleteReceipt(String id) async {
    await _repo.deleteReceipt(id);
    await refresh();
  }
}

final receiptDetailProvider = FutureProvider.family<ReceiptModel?, String>((ref, id) async {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.getReceiptById(id);
});

