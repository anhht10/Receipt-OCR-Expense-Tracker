class DatabaseTables {
  static const String receiptsTable = 'receipts';

  static const String columnId = 'id';
  static const String columnMerchant = 'merchant';
  static const String columnTotalAmount = 'total_amount';
  static const String columnDate = 'date';
  static const String columnCategory = 'category';
  static const String columnImagePath = 'image_path';
  static const String columnRawOcrText = 'raw_ocr_text';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createReceiptsTable = '''
    CREATE TABLE $receiptsTable (
      $columnId TEXT PRIMARY KEY,
      $columnMerchant TEXT NOT NULL,
      $columnTotalAmount INTEGER NOT NULL,
      $columnDate TEXT NOT NULL,
      $columnCategory TEXT NOT NULL,
      $columnImagePath TEXT NOT NULL,
      $columnRawOcrText TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    );
  ''';

  static const String createIndexes = '''
    CREATE INDEX idx_receipts_date ON $receiptsTable ($columnDate);
    CREATE INDEX idx_receipts_category ON $receiptsTable ($columnCategory);
  ''';
}

