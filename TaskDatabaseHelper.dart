import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';

class TaskDatabaseHelper {
  static final TaskDatabaseHelper instance = TaskDatabaseHelper._init();
  static Database? _database;

  TaskDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createTaskTable);
  }

  Future _onCreate(Database db, int version) async {
    await _createTaskTable(db, version); // Gọi để tạo bảng tasks
  }

  Future _createTaskTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        assignedTo TEXT,
        createdBy TEXT NOT NULL,
        category TEXT,
        attachments TEXT,
        completed INTEGER NOT NULL
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // CRUD Operations for Task

  Future<int> insertTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await instance.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Tìm kiếm và lọc dữ liệu

  Future<List<Task>> getTasksByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'status = ?', whereArgs: [status]);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByPriority(int priority) async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'priority = ?', whereArgs: [priority]);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query('tasks', where: 'category = ?', whereArgs: [category]);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }
}