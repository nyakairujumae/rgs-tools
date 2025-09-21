import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = true; // Default to dark mode

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;
  
  // Get the current theme data
  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  // Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // Get theme mode description
  String get themeModeDescription {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  // Load theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 2; // Default to system (index 2)
      _themeMode = ThemeMode.values[themeIndex];
      
      // Update dark mode based on theme mode
      _updateDarkMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Update dark mode based on current theme mode
  void _updateDarkMode() {
    switch (_themeMode) {
      case ThemeMode.light:
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        _isDarkMode = true;
        break;
      case ThemeMode.system:
        // For system mode, check the current system brightness
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
        break;
    }
  }

  // Change theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateDarkMode();
      await _saveTheme();
      notifyListeners();
    }
  }

  // Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    final newMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  // Set specific theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Get theme icon
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  // Get theme color
  Color get themeColor {
    switch (_themeMode) {
      case ThemeMode.light:
        return Colors.orange;
      case ThemeMode.dark:
        return Colors.blue;
      case ThemeMode.system:
        return Colors.purple;
    }
  }
}
