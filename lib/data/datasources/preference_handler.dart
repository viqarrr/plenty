import 'dart:convert';

import 'package:plenty/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  PreferenceHandler._();

  static late SharedPreferences _prefs;

  static const String _keyUser = 'active_user_session';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsOnboard = 'is_onboarded';
  static const String _keyStreak = "streak_count";
  static const String _keyUserPlants = "user_plants";

  /// Initialize SharedPreferences instance.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save full UserModel
  static Future<bool> setUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_keyUser, userJson);
  }

  // --- Login State ---
  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLoggedIn, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clear session on Logout
  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUser);
  }

  /// Get active UserModel (returns null if not logged in or absent)
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        return UserModel.fromJson(map);
      } catch (_) {}
    }
    final legacyProfileName = prefs.getString('profile_name');
    if (legacyProfileName != null && legacyProfileName.isNotEmpty) {
      return UserModel(
        id: 0,
        email: 'user@plenty.app',
        password: '',
        username: legacyProfileName,
        displayName: legacyProfileName,
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    return null;
  }

  static Future<int?> getUserId() async {
    final user = await getUser();
    return user?.id;
  }

  // --- Onboarding State ---
  static Future<void> setOnboard(bool isOnboard) async {
    await _prefs.setBool(_keyIsOnboard, isOnboard);
  }

  static bool get isOnboard {
    return _prefs.getBool(_keyIsOnboard) ?? false;
  }

  /// Login helper saving both status and user data
  static Future<void> setLoginSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await setUser(user);
  }

  // --- Streak Count ---
  static Future<void> setStreakCount(int count) async {
    await _prefs.setInt(_keyStreak, count);
  }

  static int get streakCount {
    return _prefs.getInt(_keyStreak) ?? 1;
  }

  // --- User Plants JSON Cache ---
  static Future<void> saveUserPlantsJson(String jsonString) async {
    await _prefs.setString(_keyUserPlants, jsonString);
  }

  static String? getUserPlantsJson() {
    return _prefs.getString(_keyUserPlants);
  }
}
