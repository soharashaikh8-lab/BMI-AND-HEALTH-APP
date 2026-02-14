import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_tracker.db');
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
    // We store the amount, the time of intake, and the date
    // to make filtering "Today's history" easy.
    await db.execute('''
      CREATE TABLE water_intake (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        time TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
    CREATE TABLE health_results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      actualAge INTEGER,
      healthAge INTEGER,
      riskLevel TEXT,
      riskColorValue INTEGER,
      date TEXT
    )
  ''');
  }

  // --- CRUD OPERATIONS ---

  // Insert water intake
  Future<int> insertWater(int amount) async {
    final db = await instance.database;
    final now = DateTime.now();

    return await db.insert('water_intake', {
      'amount': amount,
      'time': "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
      'date': "${now.year}-${now.month}-${now.day}",
    });
  }

  // Fetch only today's records
  Future<List<Map<String, dynamic>>> getTodayHistory() async {
    final db = await instance.database;
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    return await db.query(
      'water_intake',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'id DESC',
    );
  }

  // Reset/Delete all records for today
  Future<int> resetToday() async {
    final db = await instance.database;
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    return await db.delete(
      'water_intake',
      where: 'date = ?',
      whereArgs: [today],
    );
  }
// Method to save BMI/Health result
  Future<void> saveHealthResult(int age, int hAge, String risk, int colorValue) async {
    final db = await instance.database;
    await db.insert('health_results', {
      'actualAge': age,
      'healthAge': hAge,
      'riskLevel': risk,
      'riskColorValue': colorValue,
      'date': DateTime.now().toIso8601String(),
    });
  }

// Method to get the most recent result
  Future<Map<String, dynamic>?> getLatestHealthResult() async {
    final db = await instance.database;
    final results = await db.query(
      'health_results',
      orderBy: 'id DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
  Future<List<Map<String, dynamic>>> getAllHealthResults() async {
    final db = await instance.database;
    // Fetch all rows from the table
    return await db.query('health_results', orderBy: 'id DESC');
  }
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}