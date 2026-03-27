import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'app_locale';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
  ];

  static const Map<String, String> localeDisplayNames = {
    'en': 'English',
    'ar': 'العربية',
    'fr': 'Français',
    'es': 'Español',
  };

  Locale? _locale;

  /// Returns the current locale, or null to use system default.
  Locale? get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (_) {}
  }

  /// Reset to system default locale.
  Future<void> clearLocale() async {
    _locale = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localeKey);
    } catch (_) {}
  }

  /// Display name for a given language code.
  String displayNameFor(String code) {
    return localeDisplayNames[code] ?? code;
  }
}
