import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Safe helper that reads dotenv without crashing if not initialized
String _env(String key, [String fallback = '']) {
  try {
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) return value;
  } catch (_) {}
  return fallback;
}

class FirebaseConfig {
  // Firebase project configuration
  static String get projectId =>
      _env('FIREBASE_PROJECT_ID', const String.fromEnvironment('FIREBASE_PROJECT_ID'));
  static String get apiKey =>
      _env('FIREBASE_ANDROID_API_KEY', const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'));
  static String get appId =>
      _env('FIREBASE_ANDROID_APP_ID', const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'));
  static String get messagingSenderId =>
      _env('FIREBASE_MESSAGING_SENDER_ID', const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'));

  // FCM topics
  static String get adminTopic =>
      _env('FCM_ADMIN_TOPIC', 'admin_notifications');
  static String get technicianTopic =>
      _env('FCM_TECHNICIAN_TOPIC', 'technician_notifications');
  static String get newRegistrationTopic =>
      _env('FCM_NEW_REGISTRATION_TOPIC', 'new_registrations');
  static String get toolIssuesTopic =>
      _env('FCM_TOOL_ISSUES_TOPIC', 'tool_issues');
}
