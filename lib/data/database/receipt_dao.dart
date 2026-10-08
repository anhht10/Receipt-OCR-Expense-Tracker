import 'package:sqflite/sqflite.dart';
import '../models/receipt_model.dart';
import 'app_database.dart';
import 'database_tables.dart';

class ReceiptDao {
  final AppDatabase _appDatabase;

  ReceiptDao(this._appDatabase);

  Future<Database> get _db => _appDatabase.database;

  /// Insert a new receipt
  Future<int> insertReceipt(ReceiptModel receipt) async {
    final db = await _db;
    return await db.insert(
      DatabaseTables.receiptsTable,
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get receipt by ID
  Future<ReceiptModel?> getReceiptById(String id) async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.query(
      DatabaseTables.receiptsTable,
      where: '${DatabaseTables.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ReceiptModel.fromMap(results.first);
  }

  /// Get all receipts sorted by date descending (newest first)
  Future<List<ReceiptModel>> getAllReceipts() async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.query(
      DatabaseTables.receiptsTable,
      orderBy: '${DatabaseTables.columnDate} DESC, ${DatabaseTables.columnCreatedAt} DESC',
    );

    return results.map((m) => ReceiptModel.fromMap(m)).toList();
  }

  /// Update an existing receipt
  Future<int> updateReceipt(ReceiptModel receipt) async {
    final db = await _db;
    return await db.update(
      DatabaseTables.receiptsTable,
      receipt.toMap(),
      where: '${DatabaseTables.columnId} = ?',
      whereArgs: [receipt.id],
    );
  }

  /// Delete a receipt by ID
  Future<int> deleteReceipt(String id) async {
    final db = await _db;
    return await db.delete(
      DatabaseTables.receiptsTable,
      where: '${DatabaseTables.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Query receipts by date range (inclusive: startDate <= date <= endDate)
  Future<List<ReceiptModel>> getReceiptsByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final startIso = start.toIso8601String().split('T').first;
    final endIso = end.toIso8601String().split('T').first;

    final List<Map<String, dynamic>> results = await db.query(
      DatabaseTables.receiptsTable,
      where: '${DatabaseTables.columnDate} >= ? AND ${DatabaseTables.columnDate} <= ?',
      whereArgs: [startIso, endIso],
      orderBy: '${DatabaseTables.columnDate} ASC',
    );

    return results.map((m) => ReceiptModel.fromMap(m)).toList();
  }

  /// Query receipts by category
  Future<List<ReceiptModel>> getReceiptsByCategory(String category) async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.query(
      DatabaseTables.receiptsTable,
      where: '${DatabaseTables.columnCategory} = ?',
      whereArgs: [category],
      orderBy: '${DatabaseTables.columnDate} DESC',
    );

    return results.map((m) => ReceiptModel.fromMap(m)).toList();
  }

  /// Calculate total lifetime spending in VND
  Future<int> calculateTotalSpending() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseTables.columnTotalAmount}) as total FROM ${DatabaseTables.receiptsTable}',
    );

    final value = result.first['total'];
    if (value == null) return 0;
    return (value as num).toInt();
  }

  /// Calculate total number of receipts
  Future<int> countReceipts() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.receiptsTable}',
    );
    final value = result.first['count'];
    if (value == null) return 0;
    return (value as num).toInt();
  }

  /// Calculate spending grouped by category: Map of category id to total amount
  Future<Map<String, int>> calculateSpendingByCategory() async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT ${DatabaseTables.columnCategory}, SUM(${DatabaseTables.columnTotalAmount}) as sum_amount
      FROM ${DatabaseTables.receiptsTable}
      GROUP BY ${DatabaseTables.columnCategory}
      ORDER BY sum_amount DESC
    ''');

    final Map<String, int> resultMap = {};
    for (final row in results) {
      final category = row[DatabaseTables.columnCategory] as String;
      final sum = (row['sum_amount'] as num?)?.toInt() ?? 0;
      resultMap[category] = sum;
    }
    return resultMap;
  }

  /// Calculate spending for a given week (Monday through Sunday)
  /// Returns a map of DayOfWeek (1 = Monday, 7 = Sunday) to total amount in VND
  Future<Map<int, int>> calculateWeeklySpending(DateTime dateInWeek) async {
    // Find Monday of the week
    final monday = dateInWeek.subtract(Duration(days: dateInWeek.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final receipts = await getReceiptsByDateRange(monday, sunday);

    final Map<int, int> weeklyMap = {
      1: 0, // Mon
      2: 0, // Tue
      3: 0, // Wed
      4: 0, // Thu
      5: 0, // Fri
      6: 0, // Sat
      7: 0, // Sun
    };

    for (final r in receipts) {
      final weekday = r.date.weekday;
      weeklyMap[weekday] = (weeklyMap[weekday] ?? 0) + r.totalAmount;
    }

    return weeklyMap;
  }
}

