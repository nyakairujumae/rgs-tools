import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false; // Always light mode

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

  // Initialize theme properly
  Future<void> _initializeTheme() async {
    await _loadTheme();
    // Force light theme for all users
    await forceLightTheme();
  }

  // Load theme from SharedPreferences (always light mode)
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      // Always use light mode – ignore saved preference
      _themeMode = ThemeMode.light;
      if (!prefs.containsKey(_themeKey)) {
        await _saveTheme();
      }

      _updateDarkMode();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error loading theme: $e');
      debugPrint('⚠️ Error type: ${e.runtimeType}');
      _themeMode = ThemeMode.light;
      _updateDarkMode();
      notifyListeners();
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      debugPrint('⚠️ Error saving theme: $e');
      debugPrint('⚠️ Error type: ${e.runtimeType}');
      // Don't throw - theme will still work, just won't persist
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

  // Change theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateDarkMode();
      await _saveTheme();
      notifyListeners();
    }
  }

  // Force refresh theme (useful for debugging or manual refresh)
  void refreshTheme() {
    _updateDarkMode();
    notifyListeners();
  }

  // Force app to always use light theme
  Future<void> forceLightTheme() async {
    _themeMode = ThemeMode.light;
    _updateDarkMode();
    await _saveTheme();
    notifyListeners();
  }

  /// @deprecated Use forceLightTheme – app is light-only
  Future<void> forceSystemTheme() async => forceLightTheme();

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
