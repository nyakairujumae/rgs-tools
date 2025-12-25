import 'package:shared_preferences/shared_preferences.dart';

class LastRouteService {
  static const String _lastRouteKey = 'last_route';

  static Future<String?> getLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastRouteKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastRouteKey, route);
    } catch (_) {
      // Ignore persistence errors to avoid blocking navigation.
    }
  }

  static Future<void> clearLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastRouteKey);
    } catch (_) {
      // Ignore persistence errors to avoid blocking logout.
    }
  }
}
