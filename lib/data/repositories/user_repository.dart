import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/user_model.dart';
import 'package:plenty/data/models/user_preference_model.dart';
import 'package:sqflite/sqflite.dart';

/// Repository managing user preferences, onboarding progression, and profiles.
class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
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

  /// Saves or updates the onboarding preferences for a user.
  Future<void> saveOnboardingPrefs({
    String? userId,
    required String experienceLevel,
    double dailyTimeMinutes = 15.0,
    bool hasPets = false,
    bool hasKids = false,
    bool hasCompletedOnboarding = false,
  }) async {
    final targetUserId = await _resolveUserId(userId);
    final db = await _dbHelper.database;

    // Ensure user row exists before inserting foreign key relation
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
  }

  /// Sets the onboarding completed flag.
  Future<void> setOnboardingCompleted([String? userId]) async {
    final targetUserId = await _resolveUserId(userId);
    final db = await _dbHelper.database;

    await db.update(
      DatabaseHelper.tableUserPreferences,
      {'has_completed_onboarding': 1},
      where: 'user_id = ?',
      whereArgs: [targetUserId],
    );

    await PreferenceHandler.setOnboard(true);
  }

  /// Checks if the user has completed the onboarding flow.
  Future<bool> hasCompletedOnboarding([String? userId]) async {
    // Check quick session flag in SharedPreferences first
    final isOnboardPref = PreferenceHandler.isOnboard;
    if (isOnboardPref) return true;

    final targetUserId = await _resolveUserId(userId);
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableUserPreferences,
      where: 'user_id = ? AND has_completed_onboarding = 1',
      whereArgs: [targetUserId],
    );

    return rows.isNotEmpty;
  }

  /// Retrieves user preferences for the active or given user.
  Future<UserPreferenceModel?> getUserPreferences([String? userId]) async {
    final targetUserId = await _resolveUserId(userId);
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableUserPreferences,
      where: 'user_id = ?',
      whereArgs: [targetUserId],
    );

    if (rows.isEmpty) return null;
    return UserPreferenceModel.fromMap(rows.first);
  }

  /// Retrieves user profile UserModel from SQLite users table.
  Future<UserModel?> getUserProfile([String? userId]) async {
    final targetUserId = await _resolveUserId(userId);
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [targetUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  /// Updates profile attributes (displayName, username, bio, avatarUrl) in SQLite and active session.
  Future<void> updateUserProfile({
    String? userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
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

      final updated = await getUserProfile(targetUserId.toString());
      if (updated != null) {
        await PreferenceHandler.setUser(updated);
      }
    }
  }
}
