import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/UserModel.dart';
import 'dart:developer' as developer;

class UserDatabase {
  static final UserDatabase instance = UserDatabase._init();
  static Database? _database;

  UserDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    developer.log('Opening database at path: $path', name: 'UserDatabase');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) => developer.log('Database opened', name: 'UserDatabase'),
    );
  }

  Future _createDB(Database db, int version) async {
    developer.log('Creating database with version: $version', name: 'UserDatabase');
    // Tạo bảng users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar TEXT,
        createdAt TEXT NOT NULL,
        lastActive TEXT NOT NULL
      )
    ''');
    developer.log('Table users created', name: 'UserDatabase');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion', name: 'UserDatabase');
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT,
          createdAt TEXT NOT NULL,
          lastActive TEXT NOT NULL
        )
      ''');
      developer.log('Table users created during upgrade (version < 2)', name: 'UserDatabase');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT,
          createdAt TEXT NOT NULL,
          lastActive TEXT NOT NULL
        )
      ''');
      developer.log('Table users created during upgrade (version < 3)', name: 'UserDatabase');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT,
          createdAt TEXT NOT NULL,
          lastActive TEXT NOT NULL
        )
      ''');
      developer.log('Table users created during upgrade (version < 4)', name: 'UserDatabase');
    }
  }

  // Kiểm tra xem bảng users có tồn tại không
  Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> insertUser(User user) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'users')) {
      await _createDB(db, 4); // Tạo bảng nếu chưa tồn tại
    }
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(String id) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'users')) {
      await _createDB(db, 4); // Tạo bảng nếu chưa tồn tại
    }
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    if (!await _tableExists(db, 'users')) {
      await _createDB(db, 4); // Tạo bảng nếu chưa tồn tại
      return []; // Trả về danh sách rỗng nếu bảng vừa được tạo
    }
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> updateUser(User user) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'users')) {
      await _createDB(db, 4); // Tạo bảng nếu chưa tồn tại
    }
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteUser(String id) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'users')) {
      await _createDB(db, 4); // Tạo bảng nếu chưa tồn tại
    }
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}