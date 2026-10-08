import 'dart:io';
import '../database/receipt_dao.dart';
import '../models/receipt_model.dart';
import '../services/receipt_image_service.dart';

abstract class IReceiptRepository {
  Future<ReceiptModel> createReceipt({
    required String id,
    required String merchant,
    required int totalAmount,
    required DateTime date,
    required String category,
    required File imageFile,
    String? rawOcrText,
  });

  Future<void> updateReceipt(ReceiptModel receipt, {File? newImageFile});
  Future<void> deleteReceipt(String id);
  Future<ReceiptModel?> getReceiptById(String id);
  Future<List<ReceiptModel>> getAllReceipts();
  Future<List<ReceiptModel>> getReceiptsByCategory(String category);
  Future<int> getTotalSpending();
  Future<int> getReceiptCount();
  Future<Map<String, int>> getSpendingByCategory();
  Future<Map<int, int>> getWeeklySpending(DateTime dateInWeek);
}

class ReceiptRepository implements IReceiptRepository {
  final ReceiptDao _receiptDao;
  final ReceiptImageService _imageService;

  ReceiptRepository(this._receiptDao, this._imageService);

  @override
  Future<ReceiptModel> createReceipt({
    required String id,
    required String merchant,
    required int totalAmount,
    required DateTime date,
    required String category,
    required File imageFile,
    String? rawOcrText,
  }) async {
    // 1. Persist image file into documents directory
    final persistentImagePath = await _imageService.saveReceiptImage(imageFile, id);

    final now = DateTime.now();
    final receipt = ReceiptModel(
      id: id,
      merchant: merchant,
      totalAmount: totalAmount,
      date: date,
      category: category,
      imagePath: persistentImagePath,
      rawOcrText: rawOcrText,
      createdAt: now,
      updatedAt: now,
    );

    // 2. Persist record in SQLite
    await _receiptDao.insertReceipt(receipt);
    return receipt;
  }

  @override
  Future<void> updateReceipt(ReceiptModel receipt, {File? newImageFile}) async {
    String imagePath = receipt.imagePath;
    if (newImageFile != null) {
      // Overwrite/update image
      imagePath = await _imageService.saveReceiptImage(newImageFile, receipt.id);
    }

    final updated = receipt.copyWith(
      imagePath: imagePath,
      updatedAt: DateTime.now(),
    );

    await _receiptDao.updateReceipt(updated);
  }

  @override
  Future<void> deleteReceipt(String id) async {
    final existing = await _receiptDao.getReceiptById(id);
    if (existing != null) {
      // 1. Delete database record
      await _receiptDao.deleteReceipt(id);
      // 2. Safely delete image file
      await _imageService.deleteReceiptImage(existing.imagePath);
    }
  }

  @override
  Future<ReceiptModel?> getReceiptById(String id) {
    return _receiptDao.getReceiptById(id);
  }

  @override
  Future<List<ReceiptModel>> getAllReceipts() {
    return _receiptDao.getAllReceipts();
  }

  @override
  Future<List<ReceiptModel>> getReceiptsByCategory(String category) {
    return _receiptDao.getReceiptsByCategory(category);
  }

  @override
  Future<int> getTotalSpending() {
    return _receiptDao.calculateTotalSpending();
  }

  @override
  Future<int> getReceiptCount() {
    return _receiptDao.countReceipts();
  }

  @override
  Future<Map<String, int>> getSpendingByCategory() {
    return _receiptDao.calculateSpendingByCategory();
  }

  @override
  Future<Map<int, int>> getWeeklySpending(DateTime dateInWeek) {
    return _receiptDao.calculateWeeklySpending(dateInWeek);
  }
}

