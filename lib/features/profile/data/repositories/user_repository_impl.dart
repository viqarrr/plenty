import 'package:bcrypt/bcrypt.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/onboarding/domain/models/user_preference_model.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Implementation of IUserRepository combining Cloud Firestore with local SQLite caching.
class UserRepositoryImpl implements IUserRepository {
  final DatabaseHelper _dbHelper;
  final ProfileRemoteDataSource _remoteDataSource;

  UserRepositoryImpl({
    DatabaseHelper? dbHelper,
    ProfileRemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _remoteDataSource =
            remoteDataSource ?? FirestoreProfileRemoteDataSourceImpl();

  Future<String> _resolveStringUserId(String? userId) async {
    if (userId != null && userId.isNotEmpty && userId != '0') {
      return userId;
    }
    final activeUser = await PreferenceHandler.getUser();
    if (activeUser?.id != null && activeUser!.id!.isNotEmpty && activeUser.id != '0') {
      return activeUser.id!;
    }
    return '1';
  }

  Future<int> _resolveNumericUserId(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      final parsed = int.tryParse(userId);
      if (parsed != null) return parsed;
      return userId.hashCode.abs();
    }
    final activeUser = await PreferenceHandler.getUser();
    if (activeUser?.numericId != null) return activeUser!.numericId!;
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
      final targetStringId = await _resolveStringUserId(userId);
      final targetNumericId = await _resolveNumericUserId(userId);
      final db = await _dbHelper.database;

      final userRows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetNumericId],
        limit: 1,
      );
      if (userRows.isEmpty) {
        await db.insert(
          DatabaseHelper.tableUsers,
          {
            'id': targetNumericId,
            'email': 'user_$targetNumericId@plenty.app',
            'username': 'user_$targetNumericId',
            'display_name': 'Pecinta Tanaman',
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final existing = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ?',
        whereArgs: [targetNumericId],
      );

      final prefModel = UserPreferenceModel(
        id: existing.isNotEmpty
            ? (existing.first['id'] as String? ??
                'pref_${DateTime.now().millisecondsSinceEpoch}')
            : 'pref_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetStringId,
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
          whereArgs: [targetNumericId],
        );
      } else {
        await db.insert(DatabaseHelper.tableUserPreferences, prefModel.toMap());
      }

      // Sync onboarding preferences to Cloud Firestore
      try {
        if (targetStringId.isNotEmpty && targetStringId != '1') {
          await _remoteDataSource.saveUserPreferences(targetStringId, prefModel);
        }
      } catch (_) {}

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
      final targetStringId = await _resolveStringUserId(userId);
      final targetNumericId = await _resolveNumericUserId(userId);
      final db = await _dbHelper.database;

      await db.update(
        DatabaseHelper.tableUserPreferences,
        {'has_completed_onboarding': 1},
        where: 'user_id = ?',
        whereArgs: [targetNumericId],
      );

      // Sync flag to Cloud Firestore
      try {
        if (targetStringId.isNotEmpty && targetStringId != '1') {
          final existing = await _remoteDataSource.getUserPreferences(targetStringId);
          if (existing != null) {
            await _remoteDataSource.saveUserPreferences(
              targetStringId,
              existing.copyWith(hasCompletedOnboarding: true),
            );
          }
        }
      } catch (_) {}

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

      final targetNumericId = await _resolveNumericUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ? AND has_completed_onboarding = 1',
        whereArgs: [targetNumericId],
      );

      return Success(rows.isNotEmpty);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserPreferenceModel?>> getUserPreferences([String? userId]) async {
    try {
      final targetStringId = await _resolveStringUserId(userId);
      final targetNumericId = await _resolveNumericUserId(userId);

      // 1. Try Cloud Firestore first
      try {
        if (targetStringId.isNotEmpty && targetStringId != '1') {
          final remotePrefs =
              await _remoteDataSource.getUserPreferences(targetStringId);
          if (remotePrefs != null) {
            return Success(remotePrefs);
          }
        }
      } catch (_) {}

      // 2. Fallback to local SQLite
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUserPreferences,
        where: 'user_id = ?',
        whereArgs: [targetNumericId],
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
      final targetStringId = await _resolveStringUserId(userId);
      final targetNumericId = await _resolveNumericUserId(userId);

      // 1. Try Cloud Firestore first
      try {
        if (targetStringId.isNotEmpty && targetStringId != '1') {
          final remoteUser =
              await _remoteDataSource.getUserProfile(targetStringId);
          if (remoteUser != null) {
            await PreferenceHandler.setUser(remoteUser);
            return Success(remoteUser);
          }
        }
      } catch (_) {}

      // 2. Fallback to SQLite cache
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetNumericId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return Success(UserModel.fromMap(rows.first).copyWith(password: ''));
      }

      // 3. Fallback to PreferenceHandler cache
      final cachedUser = await PreferenceHandler.getUser();
      if (cachedUser != null) {
        return Success(cachedUser);
      }

      return const Success(null);
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
      final targetStringId = await _resolveStringUserId(userId);
      final targetNumericId = await _resolveNumericUserId(userId);
      final db = await _dbHelper.database;

      final updateValues = <String, dynamic>{};
      if (displayName != null) updateValues['display_name'] = displayName;
      if (username != null) updateValues['username'] = username;
      if (bio != null) updateValues['bio'] = bio;
      if (avatarUrl != null) updateValues['avatar_url'] = avatarUrl;

      if (updateValues.isNotEmpty) {
        // 1. Update SQLite for downstream relational integrity
        await db.update(
          DatabaseHelper.tableUsers,
          updateValues,
          where: 'id = ?',
          whereArgs: [targetNumericId],
        );

        // 2. Sync to Cloud Firestore
        try {
          if (targetStringId.isNotEmpty && targetStringId != '1') {
            await _remoteDataSource.updateUserProfile(targetStringId, updateValues);
          }
        } catch (_) {}

        // 3. Update active session cache
        final currentCached = await PreferenceHandler.getUser();
        if (currentCached != null) {
          final updated = currentCached.copyWith(
            displayName: displayName ?? currentCached.displayName,
            username: username ?? currentCached.username,
            bio: bio ?? currentCached.bio,
            avatarUrl: avatarUrl ?? currentCached.avatarUrl,
          );
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
      final targetNumericId = await _resolveNumericUserId(userId);
      final db = await _dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUsers,
        where: 'id = ?',
        whereArgs: [targetNumericId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Error(DatabaseFailure('User tidak ditemukan'));
      }
      final storedHash = rows.first['password'] as String? ?? '';
      bool isValid = false;
      if (storedHash.isEmpty) {
        isValid = true;
      } else {
        try {
          isValid = BCrypt.checkpw(currentPassword, storedHash);
        } catch (_) {
          isValid = (storedHash == currentPassword);
        }
      }
      if (!isValid) {
        return const Error(ValidationFailure('Kata sandi saat ini tidak cocok'));
      }

      final newHashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await db.update(
        DatabaseHelper.tableUsers,
        {'password': newHashed},
        where: 'id = ?',
        whereArgs: [targetNumericId],
      );

      // Also update Firebase Auth password if authenticated
      try {
        await _remoteDataSource.updatePassword(newPassword);
      } catch (_) {}

      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
