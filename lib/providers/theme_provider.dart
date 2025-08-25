import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum for theme options, stored in SharedPreferences
enum ThemeModeOption { light, dark, system }

final themeNotifierProvider = ChangeNotifierProvider<ThemeNotifier>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themePreferenceKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  // Load theme from shared preferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the stored index, defaulting to system
    final themeIndex = prefs.getInt(_themePreferenceKey) ?? ThemeModeOption.system.index;
    _themeMode = _mapIndexToThemeMode(themeIndex);
    notifyListeners();
  }

  // Update and save theme
  Future<void> setTheme(ThemeModeOption themeOption) async {
    _themeMode = _mapOptionToThemeMode(themeOption);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, themeOption.index);
    notifyListeners();
  }

  ThemeMode _mapOptionToThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeMode _mapIndexToThemeMode(int index) {
    try {
      final option = ThemeModeOption.values[index];
      return _mapOptionToThemeMode(option);
    } catch (e) {
      return ThemeMode.system;
    }
  }
}
