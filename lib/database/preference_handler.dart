import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyIsOnboard = "isOnboard";

  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
  }

  static Future<void> setOnboard(bool isOnboard) async {
    await _prefs.setBool(_keyIsOnboard, isOnboard);
  }

  static bool get isOnboard {
    return _prefs.getBool(_keyIsOnboard) ?? false;
  }
}
