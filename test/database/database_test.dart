import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_receipt_scanner/data/database/app_database.dart';
import 'package:vku_receipt_scanner/data/database/database_tables.dart';
import 'package:vku_receipt_scanner/data/database/receipt_dao.dart';
import 'package:vku_receipt_scanner/data/models/receipt_model.dart';

void main() {
  // Initialize ffi for testing SQLite in dart/flutter_test VM
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReceiptDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(DatabaseTables.createReceiptsTable);
    await db.execute(DatabaseTables.createIndexes);

    final appDb = AppDatabase(db);
    dao = ReceiptDao(appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Database CRUD & Query Tests', () {
    final sampleReceipt = ReceiptModel(
      id: 'receipt-001',
      merchant: 'Căn tin VKU',
      totalAmount: 35000,
      date: DateTime(2026, 10, 8),
      category: 'food',
      imagePath: '/path/to/image1.jpg',
      rawOcrText: 'CAN TIN VKU\nTOTAL 35000',
      createdAt: DateTime(2026, 10, 8, 12, 0),
      updatedAt: DateTime(2026, 10, 8, 12, 0),
    );

    // Insert & Read
    test('Insert receipt and read by ID', () async {
      await dao.insertReceipt(sampleReceipt);

      final retrieved = await dao.getReceiptById('receipt-001');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('receipt-001'));
      expect(retrieved.merchant, equals('Căn tin VKU'));
      expect(retrieved.totalAmount, equals(35000));
      expect(retrieved.category, equals('food'));
    });

    // Update
    test('Update receipt', () async {
      await dao.insertReceipt(sampleReceipt);

      final updated = sampleReceipt.copyWith(
        merchant: 'Căn tin VKU - Cập nhật',
        totalAmount: 40000,
      );
      await dao.updateReceipt(updated);

      final retrieved = await dao.getReceiptById('receipt-001');
      expect(retrieved!.merchant, equals('Căn tin VKU - Cập nhật'));
      expect(retrieved.totalAmount, equals(40000));
    });

    // Delete
    test('Delete receipt', () async {
      await dao.insertReceipt(sampleReceipt);
      expect(await dao.getReceiptById('receipt-001'), isNotNull);

      await dao.deleteReceipt('receipt-001');
      expect(await dao.getReceiptById('receipt-001'), isNull);
    });

    // Query all
    test('Get all receipts sorted by date descending', () async {
      final receipt2 = sampleReceipt.copyWith(
        id: 'receipt-002',
        merchant: 'Tiệm In VKU',
        totalAmount: 20000,
        date: DateTime(2026, 10, 9),
      );

      await dao.insertReceipt(sampleReceipt);
      await dao.insertReceipt(receipt2);

      final all = await dao.getAllReceipts();
      expect(all.length, equals(2));
      expect(all.first.id, equals('receipt-002')); // newer date first
    });

    // Query by category
    test('Query receipts by category', () async {
      final receiptStudy = sampleReceipt.copyWith(
        id: 'receipt-003',
        category: 'study',
        totalAmount: 50000,
      );

      await dao.insertReceipt(sampleReceipt);
      await dao.insertReceipt(receiptStudy);

      final studyList = await dao.getReceiptsByCategory('study');
      expect(studyList.length, equals(1));
      expect(studyList.first.id, equals('receipt-003'));
    });

    // Aggregates: Total spending & category breakdown
    test('Calculate total spending and category breakdown', () async {
      final r1 = sampleReceipt.copyWith(id: '1', totalAmount: 30000, category: 'food');
      final r2 = sampleReceipt.copyWith(id: '2', totalAmount: 70000, category: 'food');
      final r3 = sampleReceipt.copyWith(id: '3', totalAmount: 50000, category: 'study');

      await dao.insertReceipt(r1);
      await dao.insertReceipt(r2);
      await dao.insertReceipt(r3);

      final total = await dao.calculateTotalSpending();
      expect(total, equals(150000));

      final categoryMap = await dao.calculateSpendingByCategory();
      expect(categoryMap['food'], equals(100000));
      expect(categoryMap['study'], equals(50000));
    });

    // Weekly spending
    test('Calculate weekly spending correctly maps to weekdays', () async {
      // 2026-10-08 is Thursday (weekday 4)
      final r = sampleReceipt.copyWith(
        id: '1',
        totalAmount: 45000,
        date: DateTime(2026, 10, 8),
      );
      await dao.insertReceipt(r);

      final weekly = await dao.calculateWeeklySpending(DateTime(2026, 10, 8));
      expect(weekly[4], equals(45000));
      expect(weekly[1], equals(0)); // Mon
    });
  });
}

