import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Reactive theme controller.
///
/// IMPORTANT: This class is itself a [WidgetsBindingObserver]. We do NOT
/// assign `WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged`
/// directly — doing so silently replaces Flutter's internal handler, which
/// breaks `MediaQuery.platformBrightnessOf(context)` and stops `MaterialApp`
/// from reacting to system dark/light toggles until the app is restarted.
class ThemeProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;
  bool _observerRegistered = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

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
    _registerObserver();
    _initializeTheme();
  }

  void _registerObserver() {
    if (_observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

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
          final brightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = brightness == Brightness.dark;
        } catch (_) {
          _isDarkMode = false;
        }
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _updateDarkMode();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }

  /// Cycle Light → Dark → System for a quick toggle UI.
  Future<void> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  void refreshTheme() {
    _updateDarkMode();
    notifyListeners();
  }

  Future<void> forceLightTheme() => setThemeMode(ThemeMode.light);
  Future<void> forceSystemTheme() => setThemeMode(ThemeMode.system);

  bool get isInitialized => true;

  // ── WidgetsBindingObserver ─────────────────────────────────────────────
  @override
  void didChangePlatformBrightness() {
    // Only react when following system; otherwise the user picked a fixed
    // theme and we leave it alone.
    if (_themeMode == ThemeMode.system) {
      final previous = _isDarkMode;
      _updateDarkMode();
      if (_isDarkMode != previous) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    super.dispose();
  }
}
