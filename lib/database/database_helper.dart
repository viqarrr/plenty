import 'package:path/path.dart';
import 'package:plenty/models/user.dart';
import 'package:sqflite/sqflite.dart';

class DBHelperTugas12 {
  static final DBHelperTugas12 _instance = DBHelperTugas12._internal();
  factory DBHelperTugas12() => _instance;
  DBHelperTugas12._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'plenty.db');

    return await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (newVersion > 1) {
          await db.execute('''
          CREATE TABLE siswa(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            kelas TEXT
          )
        ''');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            username TEXT UNIQUE,
            email TEXT UNIQUE,
            nomor_telepon TEXT,
            password TEXT,
            asal_kota TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE siswa(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT,
            kelas TEXT
          )
        ''');
      },
    );
  }

  Future<bool> registerUser(UserModelSQL pengguna) async {
    final db = await database;

    try {
      await db.insert('users', pengguna.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModelSQL?> loginUser(String email, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return UserModelSQL.fromMap(results.first);
    }
    return null;
  }

  Future<List<UserModelSQL>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users');
    return results.map((map) => UserModelSQL.fromMap(map)).toList();
  }

  Future<bool> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<bool> updateUser(UserModelSQL pengguna) async {
    final db = await database;

    try {
      int count = await db.update(
        'users',
        pengguna.toMap(),
        where: 'id = ?',
        whereArgs: [pengguna.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
