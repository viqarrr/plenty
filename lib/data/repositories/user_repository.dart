import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/user_preference_model.dart';

/// Repository managing user preferences, onboarding progression, and profiles.
class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<String> _resolveUserId(String? userId) async {
    if (userId != null && userId.isNotEmpty) return userId;
    final activeUser = await PreferenceHandler.getUser();
    return activeUser?.id.toString() ?? 'usr_default';
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
      userId: targetUserId,
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
}
