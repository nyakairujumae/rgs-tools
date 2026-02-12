import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => ThemeMode.system;
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

  // Initialize theme: always follow device system
  Future<void> _initializeTheme() async {
    _themeMode = ThemeMode.system;
    _updateDarkMode();
    notifyListeners();
  }

  // Update dark mode from device system brightness
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
        try {
          final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = brightness == Brightness.dark;
        } catch (e) {
          // Fallback to light mode if there's an error
          _isDarkMode = false;
        }
        break;
    }
  }

  // Listen to system brightness changes
  void _listenToSystemBrightness() {
    // Use a more robust approach to listen to system brightness changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        _updateDarkMode();
        notifyListeners();
      }
    };
    
    // Also listen to app lifecycle changes to catch system theme changes
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // Theme always follows device – user cannot override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = ThemeMode.system;
    _updateDarkMode();
    notifyListeners();
  }

  // Force refresh theme (useful for debugging or manual refresh)
  void refreshTheme() {
    _updateDarkMode();
    notifyListeners();
  }

  Future<void> forceLightTheme() async {
    _themeMode = ThemeMode.system;
    _updateDarkMode();
    notifyListeners();
  }

  Future<void> forceSystemTheme() async {
    _themeMode = ThemeMode.system;
    _updateDarkMode();
    notifyListeners();
  }

  // Check if theme is properly initialized
  bool get isInitialized => _themeMode != null;

  // Dispose method to clean up observers
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
