import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

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
    _initializeTheme();
    _listenToSystemBrightness();
  }

  // Initialize theme from persisted preference or default to system
  Future<void> _initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);
      if (saved != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    _updateDarkMode();
    notifyListeners();
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
        try {
          final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = brightness == Brightness.dark;
        } catch (_) {
          _isDarkMode = false;
        }
        break;
    }
  }

  // Listen to system brightness changes
  void _listenToSystemBrightness() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        _updateDarkMode();
        notifyListeners();
      }
    };
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // Set and persist theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _updateDarkMode();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }

  // Force refresh theme (useful for debugging or manual refresh)
  void refreshTheme() {
    _updateDarkMode();
    notifyListeners();
  }

  Future<void> forceLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> forceSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Check if theme is properly initialized
  bool get isInitialized => true;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(this));
    super.dispose();
  }
}

// App lifecycle observer to catch system theme changes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final ThemeProvider _themeProvider;

  _AppLifecycleObserver(this._themeProvider);

  @override
  void didChangePlatformBrightness() {
    if (_themeProvider._themeMode == ThemeMode.system) {
      _themeProvider._updateDarkMode();
      _themeProvider.notifyListeners();
    }
  }
}
