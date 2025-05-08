import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ck/Flutter_Task_Manage/model/TaskUser.dart';

class UserDatabaseHelper {
  static final UserDatabaseHelper instance = UserDatabaseHelper._init();
  static Database? _database;

  UserDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await _createUserTable(db, version); // Gọi để tạo bảng Users
  }

  Future _createUserTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        avatar TEXT,
        createdAt TEXT NOT NULL,
        lastActive TEXT NOT NULL
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // CRUD Operations for User

  Future<int> insertUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(String id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateLastActive(String userId) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'lastActive': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

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
}