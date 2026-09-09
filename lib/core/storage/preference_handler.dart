import 'dart:convert';

import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  PreferenceHandler._();

  static SharedPreferences? _prefs;

  static const String _keyUser = 'active_user_session';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsOnboard = 'is_onboarded';
  static const String _keyStreak = 'streak_count';
  static const String _keyUserPlants = 'user_plants';

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Initialize SharedPreferences instance.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save full UserModel
  static Future<bool> setUser(UserModel user) async {
    final prefs = await _getPrefs();
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_keyUser, userJson);
  }

  // --- Login State ---
  static Future<void> setLogin(bool isLogin) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsLoggedIn, isLogin);
  }

  static bool get isLogin {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clear session on Logout
  static Future<void> logOut() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUser);
  }

  /// Get active UserModel (returns null if not logged in or absent)
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await _getPrefs();
      final userJson = prefs.getString(_keyUser);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          return UserModel.fromJson(map);
        } catch (_) {}
      }
      final legacyProfileName = prefs.getString('profile_name');
      if (legacyProfileName != null && legacyProfileName.isNotEmpty) {
        return UserModel(
          id: '1',
          email: 'user@plenty.app',
          password: '',
          username: legacyProfileName,
          displayName: legacyProfileName,
          createdAt: DateTime.now().toIso8601String(),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getUserId() async {
    final user = await getUser();
    return user?.id;
  }

  static Future<int?> getNumericUserId() async {
    final user = await getUser();
    return user?.numericId;
  }

  // --- Onboarding State ---
  static Future<void> setOnboard(bool isOnboard) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsOnboard, isOnboard);
  }

  static bool get isOnboard {
    try {
      return _prefs?.getBool(_keyIsOnboard) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Login helper saving both status and user data
  static Future<void> setLoginSession(UserModel user) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsLoggedIn, true);
    await setUser(user);
  }

  // --- Streak Count ---
  static Future<void> setStreakCount(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyStreak, count);
  }

  static int get streakCount {
    try {
      return _prefs?.getInt(_keyStreak) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  // --- User Plants JSON Cache ---
  static Future<void> saveUserPlantsJson(String jsonString) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserPlants, jsonString);
  }

  static String? getUserPlantsJson() {
    try {
      return _prefs?.getString(_keyUserPlants);
    } catch (_) {
      return null;
    }
  }
}
