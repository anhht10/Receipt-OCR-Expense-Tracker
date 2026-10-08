import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/receipt_dao.dart';
import '../repositories/receipt_repository.dart';
import '../services/receipt_image_service.dart';
import '../../features/receipt_scanner/data/receipt_ocr_service.dart';
import '../../features/receipt_scanner/domain/receipt_parser.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    AppDatabase.close();
  });
  return db;
});

final receiptDaoProvider = Provider<ReceiptDao>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return ReceiptDao(appDb);
});

final receiptImageServiceProvider = Provider<ReceiptImageService>((ref) {
  return ReceiptImageService();
});

final receiptRepositoryProvider = Provider<IReceiptRepository>((ref) {
  final dao = ref.watch(receiptDaoProvider);
  final imageService = ref.watch(receiptImageServiceProvider);
  return ReceiptRepository(dao, imageService);
});

final ocrServiceProvider = Provider<IReceiptOcrService>((ref) {
  final service = ReceiptOcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final receiptParserProvider = Provider<ReceiptParser>((ref) {
  return ReceiptParser();
});

