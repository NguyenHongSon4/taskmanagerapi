import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:taskmanagerapi/taskManager/model/TaskModel.dart';
import 'dart:developer' as developer;

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  static Database? _database;

  TaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    developer.log('Opening database at path: $path', name: 'TaskDatabase');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future _createDB(Database db, int version) async {
    developer.log('Creating database with version: $version', name: 'TaskDatabase');
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
    developer.log('Table users created', name: 'TaskDatabase');

    // Tạo bảng tasks
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
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
        completed INTEGER NOT NULL,
        FOREIGN KEY (assignedTo) REFERENCES users(id),
        FOREIGN KEY (createdBy) REFERENCES users(id)
      )
    ''');
    developer.log('Table tasks created', name: 'TaskDatabase');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion', name: 'TaskDatabase');
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
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
          completed INTEGER NOT NULL,
          FOREIGN KEY (assignedTo) REFERENCES users(id),
          FOREIGN KEY (createdBy) REFERENCES users(id)
        )
      ''');
      developer.log('Table tasks created during upgrade (version < 2)', name: 'TaskDatabase');
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
      developer.log('Table users created during upgrade (version < 3)', name: 'TaskDatabase');
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
      developer.log('Table users created during upgrade (version < 4)', name: 'TaskDatabase');
    }
  }

  Future _onOpen(Database db) async {
    developer.log('Database opened', name: 'TaskDatabase');
    // Tạo index để tối ưu truy vấn tìm kiếm và lọc
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_createdBy ON tasks(createdBy)');
  }

  // Kiểm tra xem bảng tasks có tồn tại không
  Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
    }
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Task?> getTask(String id) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
    }
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> getAllTasks(String createdBy) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
      return [];
    }
    final maps = await db.query(
      'tasks',
      where: 'createdBy = ?',
      whereArgs: [createdBy],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
    }
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
    }
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Task>> searchTasks({
    String? keyword,
    String? status,
    String? category,
    required String createdBy, // Bắt buộc createdBy để luôn lọc theo tài khoản
  }) async {
    final db = await instance.database;
    if (!await _tableExists(db, 'tasks')) {
      await _createDB(db, 4);
      return [];
    }
    String whereClause = 'createdBy = ?'; // Luôn lọc theo createdBy
    List<dynamic> whereArgs = [createdBy];

    if (keyword != null && keyword.isNotEmpty) {
      whereClause += ' AND (title LIKE ? OR description LIKE ?)';
      whereArgs.addAll(['%$keyword%', '%$keyword%']);
    }

    if (status != null && status.isNotEmpty) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    if (category != null && category.isNotEmpty) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}