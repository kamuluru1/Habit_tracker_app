import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Data model for a habit.
class Habit {
  int id;
  String name;
  int streak;
  String lastCompleted; // Format: 'yyyy-MM-dd'

  Habit({this.id, this.name, this.streak = 0, this.lastCompleted});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'streak': streak,
      'lastCompleted': lastCompleted,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      streak: map['streak'],
      lastCompleted: map['lastCompleted'],
    );
  }
}

/// Database helper class for managing local storage using sqflite.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDB();
    return _database;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'habit_tracker.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Table to store habits
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        streak INTEGER,
        lastCompleted TEXT
      )
    ''');
    // Table to track daily completions
    await db.execute('''
      CREATE TABLE completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER,
        date TEXT,
        completed INTEGER,
        FOREIGN KEY (habitId) REFERENCES habits (id)
      )
    ''');
  }

  // Habit CRUD operations
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return List.generate(maps.length, (i) {
      return Habit.fromMap(maps[i]);
    });
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // Completion tracking methods
  Future<int> markHabitCompleted(int habitId, String date) async {
    final db = await database;
    return await db.insert('completions', {
      'habitId': habitId,
      'date': date,
      'completed': 1,
    });
  }

  Future<int> removeHabitCompletion(int habitId, String date) async {
    final db = await database;
    return await db.delete('completions', where: 'habitId = ? AND date = ?', whereArgs: [habitId, date]);
  }

  Future<bool> isHabitCompleted(int habitId, String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('completions',
        where: 'habitId = ? AND date = ?', whereArgs: [habitId, date]);
    return maps.isNotEmpty;
  }
}