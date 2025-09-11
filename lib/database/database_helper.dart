import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tools table
    await db.execute('''
      CREATE TABLE tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        serial_number TEXT UNIQUE,
        purchase_date TEXT,
        purchase_price REAL,
        current_value REAL,
        condition TEXT CHECK(condition IN ('Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair')),
        location TEXT,
        assigned_to TEXT,
        status TEXT CHECK(status IN ('Available', 'In Use', 'Maintenance', 'Retired')) DEFAULT 'Available',
        image_path TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Technicians table
    await db.execute('''
      CREATE TABLE technicians (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        employee_id TEXT UNIQUE,
        phone TEXT,
        email TEXT,
        department TEXT,
        hire_date TEXT,
        status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tool usage history
    await db.execute('''
      CREATE TABLE tool_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER,
        technician_id INTEGER,
        check_out_date TEXT,
        check_in_date TEXT,
        notes TEXT,
        FOREIGN KEY (tool_id) REFERENCES tools (id),
        FOREIGN KEY (technician_id) REFERENCES technicians (id)
      )
    ''');

    // Maintenance records
    await db.execute('''
      CREATE TABLE maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER,
        maintenance_type TEXT,
        maintenance_date TEXT,
        next_maintenance_date TEXT,
        cost REAL,
        description TEXT,
        performed_by TEXT,
        FOREIGN KEY (tool_id) REFERENCES tools (id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

