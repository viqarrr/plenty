import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

/// Local DataSource for Authentication SQLite persistence.
abstract interface class AuthLocalDataSource {
  Future<bool> registerUser(UserModel user);
  Future<UserModel?> loginUser(String emailOrUsername, String password);
  Future<List<UserModel>> getAllUsers();
  Future<bool> deleteUser(String id);
  Future<bool> updateUser(UserModel user);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper _dbService;

  AuthLocalDataSourceImpl([DatabaseHelper? dbService])
      : _dbService = dbService ?? DatabaseHelper.instance;

  @override
  Future<bool> registerUser(UserModel user) async {
    final db = await _dbService.database;
    try {
      final userMap = user.toMap();
      if (userMap['created_at'] == null ||
          (userMap['created_at'] as String).isEmpty) {
        userMap['created_at'] = DateTime.now().toIso8601String();
      }
      final id = await db.insert(
        DatabaseHelper.tableUsers,
        userMap,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserModel?> loginUser(String emailOrUsername, String password) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.tableUsers,
      where: '(email = ? OR username = ?) AND password = ?',
      whereArgs: [emailOrUsername, emailOrUsername, password],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.tableUsers,
    );
    return results.map(UserModel.fromMap).toList();
  }

  @override
  Future<bool> deleteUser(String id) async {
    final db = await _dbService.database;
    final count = await db.delete(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<bool> updateUser(UserModel user) async {
    if (user.id == null) return false;
    final db = await _dbService.database;
    final count = await db.update(
      DatabaseHelper.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return count > 0;
  }
}
