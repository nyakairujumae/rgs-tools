import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hvac_tools.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tools table — matches Supabase schema with TEXT UUIDs
    await db.execute('''
      CREATE TABLE tools (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        serial_number TEXT,
        purchase_date TEXT,
        purchase_price REAL,
        current_value REAL,
        condition TEXT NOT NULL,
        location TEXT,
        assigned_to TEXT,
        status TEXT NOT NULL DEFAULT 'Available',
        tool_type TEXT NOT NULL DEFAULT 'inventory',
        image_path TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Technicians table — matches Supabase schema
    await db.execute('''
      CREATE TABLE technicians (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        employee_id TEXT,
        phone TEXT,
        email TEXT,
        department TEXT,
        hire_date TEXT,
        status TEXT NOT NULL DEFAULT 'Active',
        profile_picture_url TEXT,
        created_at TEXT
      )
    ''');

    // Sync queue — stores offline mutations to replay when online
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Cache metadata — tracks last sync time per table
    await db.execute('''
      CREATE TABLE cache_metadata (
        table_name TEXT PRIMARY KEY,
        last_sync_at TEXT NOT NULL
      )
    ''');

    Logger.debug('Created SQLite database v$version');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.debug('Upgrading SQLite database from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      // Drop old v1 tables (INTEGER PKs, wrong schema) and recreate
      await db.execute('DROP TABLE IF EXISTS tool_usage');
      await db.execute('DROP TABLE IF EXISTS maintenance');
      await db.execute('DROP TABLE IF EXISTS technicians');
      await db.execute('DROP TABLE IF EXISTS tools');
      await _createDB(db, newVersion);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
