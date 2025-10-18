import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false; // Will be determined by system

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
    // Force system theme for all users (automatic adaptation)
    await forceSystemTheme();
  }

  // Load theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 2; // Default to system (index 2)
      _themeMode = ThemeMode.values[themeIndex];
      
      // Always ensure system theme is the default for new users
      if (!prefs.containsKey(_themeKey)) {
        _themeMode = ThemeMode.system;
        await _saveTheme();
      }
      
      // Update dark mode based on theme mode
      _updateDarkMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
      // Fallback to system theme
      _themeMode = ThemeMode.system;
      _updateDarkMode();
      notifyListeners();
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

  // Force app to always use system theme (removes any user overrides)
  Future<void> forceSystemTheme() async {
    _themeMode = ThemeMode.system;
    _updateDarkMode();
    await _saveTheme();
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
