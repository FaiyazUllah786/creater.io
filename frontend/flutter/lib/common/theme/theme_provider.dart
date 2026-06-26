import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(themeKey, mode.name);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString(themeKey) ?? ThemeMode.system.name;

    _themeMode = ThemeMode.values.firstWhere(
      (element) => element.name == savedTheme,
      orElse: () => ThemeMode.system,
    );

    notifyListeners();
  }
}
