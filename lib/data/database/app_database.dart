import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import 'database_tables.dart';

class AppDatabase {
  static Database? _instance;
  final Database? _overrideDb;

  AppDatabase([this._overrideDb]);

  Future<Database> get database async {
    if (_overrideDb != null) {
      return _overrideDb;
    }
    if (_instance != null) {
      return _instance!;
    }
    _instance = await _initDatabase();
    return _instance!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute(DatabaseTables.createReceiptsTable);
        await db.execute(DatabaseTables.createIndexes);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration hooks for future versions
      },
    );
  }

  /// Closes database connection (useful for tests and cleanup)
  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}

