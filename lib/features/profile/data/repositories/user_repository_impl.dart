import 'package:bcrypt/bcrypt.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/onboarding/domain/models/user_preference_model.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of IUserRepository for SQLite database and SharedPreferences.
class UserRepositoryImpl implements IUserRepository {
  final DatabaseHelper _dbHelper;

  UserRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> _resolveUserId(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      final parsed = int.tryParse(userId);
      if (parsed != null) return parsed;
    }
    final activeUser = await PreferenceHandler.getUser();
    if (activeUser?.id != null) return activeUser!.id!;
    return 1;
  }

  @override
  Future<Result<void>> saveOnboardingPrefs({
    String? userId,
    required String experienceLevel,
    double dailyTimeMinutes = 15.0,
    bool hasPets = false,
    bool hasKids = false,
    bool hasCompletedOnboarding = false,
  }) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;

      final userRows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetUserId],
        limit: 1,
      );
      if (userRows.isEmpty) {
        await db.insert(
          DatabaseHelper.tableUsers,
          {
            'id': targetUserId,
            'email': 'user_$targetUserId@plenty.app',
            'username': 'user_$targetUserId',
            'display_name': 'Pecinta Tanaman',
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final existing = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ?',
        whereArgs: [targetUserId],
      );

      final prefModel = UserPreferenceModel(
        id: existing.isNotEmpty
            ? (existing.first['id'] as String? ??
                'pref_${DateTime.now().millisecondsSinceEpoch}')
            : 'pref_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetUserId.toString(),
        experienceLevel: experienceLevel,
        dailyTimeMinutes: dailyTimeMinutes,
        hasPets: hasPets,
        hasKids: hasKids,
        hasCompletedOnboarding: hasCompletedOnboarding,
      );

      if (existing.isNotEmpty) {
        await db.update(
          DatabaseHelper.tableUserPreferences,
          prefModel.toMap(),
          where: 'user_id = ?',
          whereArgs: [targetUserId],
        );
      } else {
        await db.insert(DatabaseHelper.tableUserPreferences, prefModel.toMap());
      }

      if (hasCompletedOnboarding) {
        await PreferenceHandler.setOnboard(true);
      }
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setOnboardingCompleted([String? userId]) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;

      await db.update(
        DatabaseHelper.tableUserPreferences,
        {'has_completed_onboarding': 1},
        where: 'user_id = ?',
        whereArgs: [targetUserId],
      );

      await PreferenceHandler.setOnboard(true);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> hasCompletedOnboarding([String? userId]) async {
    try {
      final isOnboardPref = PreferenceHandler.isOnboard;
      if (isOnboardPref) return const Success(true);

      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ? AND has_completed_onboarding = 1',
        whereArgs: [targetUserId],
      );

      return Success(rows.isNotEmpty);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserPreferenceModel?>> getUserPreferences([String? userId]) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ?',
        whereArgs: [targetUserId],
      );

      if (rows.isEmpty) return const Success(null);
      return Success(UserPreferenceModel.fromMap(rows.first));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserModel?>> getUserProfile([String? userId]) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetUserId],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(UserModel.fromMap(rows.first).copyWith(password: ''));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUserProfile({
    String? userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;

      final updateValues = <String, dynamic>{};
      if (displayName != null) updateValues['display_name'] = displayName;
      if (username != null) updateValues['username'] = username;
      if (bio != null) updateValues['bio'] = bio;
      if (avatarUrl != null) updateValues['avatar_url'] = avatarUrl;

      if (updateValues.isNotEmpty) {
        await db.update(
          DatabaseHelper.tableUsers,
          updateValues,
          where: 'id = ?',
          whereArgs: [targetUserId],
        );

        final updatedRes = await getUserProfile(targetUserId.toString());
        final updated = updatedRes.dataOrNull;
        if (updated != null) {
          await PreferenceHandler.setUser(updated);
        }
      }
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePassword({
    String? userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final targetUserId = await _resolveUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetUserId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Error(DatabaseFailure('User tidak ditemukan'));
      }
      final storedHash = rows.first['password'] as String? ?? '';
      bool isValid = false;
      try {
        isValid = BCrypt.checkpw(currentPassword, storedHash);
      } catch (_) {
        isValid = (storedHash == currentPassword);
      }
      if (!isValid) {
        return const Error(ValidationFailure('Kata sandi saat ini tidak cocok'));
      }

      final newHashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await db.update(
        DatabaseHelper.tableUsers,
        {'password': newHashed},
        where: 'id = ?',
        whereArgs: [targetUserId],
      );
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
