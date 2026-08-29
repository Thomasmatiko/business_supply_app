
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;

  bool _isLoaded = false;

  // ============================================================
  // GETTERS
  // ============================================================

  ThemeMode get themeMode => _themeMode;

  bool get notificationsEnabled => _notificationsEnabled;

  bool get isLoaded => _isLoaded;

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final savedTheme = prefs.getString(_themeKey);

    switch (savedTheme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      case 'system':
        _themeMode = ThemeMode.system;
        break;

      case 'light':
      default:
        _themeMode = ThemeMode.light;
        break;
    }

    // Load notifications
    _notificationsEnabled =
        prefs.getBool(_notificationsKey) ?? true;

    _isLoaded = true;

    notifyListeners();
  }

  // ============================================================
  // CHANGE THEME
  // ============================================================

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();

    String value;

    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;

      case ThemeMode.system:
        value = 'system';
        break;

      case ThemeMode.light:
        value = 'light';
        break;
    }

    await prefs.setString(_themeKey, value);

    notifyListeners();
  }

  // ============================================================
  // CHANGE NOTIFICATIONS
  // ============================================================

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _notificationsKey,
      enabled,
    );

    notifyListeners();
  }

  // ============================================================
  // RESET SETTINGS
  // ============================================================

  Future<void> resetSettings() async {
    _themeMode = ThemeMode.light;
    _notificationsEnabled = true;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_themeKey);
    await prefs.remove(_notificationsKey);

    notifyListeners();
  }
}
