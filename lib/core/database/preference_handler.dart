import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Preferences Handler managing local user flags and app state.
abstract final class PreferenceHandler {
  PreferenceHandler._();

  static late SharedPreferences _prefs;

  static const String _keyIsLogin = "isLogin";
  static const String _keyIsOnboard = "isOnboard";
  static const String _keyProfileName = "profile_name";
  static const String _keyStreak = "streak_count";
  static const String _keyUserPlants = "user_plants";

  /// Initialize SharedPreferences instance.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Login State ---
  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
  }

  // --- Onboarding State ---
  static Future<void> setOnboard(bool isOnboard) async {
    await _prefs.setBool(_keyIsOnboard, isOnboard);
  }

  static bool get isOnboard {
    return _prefs.getBool(_keyIsOnboard) ?? false;
  }

  // --- Profile Name ---
  static Future<void> setProfileName(String name) async {
    await _prefs.setString(_keyProfileName, name);
  }

  static String get profileName {
    return _prefs.getString(_keyProfileName) ?? "John";
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
