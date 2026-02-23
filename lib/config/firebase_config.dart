import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  // Firebase project configuration
  static String get projectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? const String.fromEnvironment('FIREBASE_PROJECT_ID');
  static String get apiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? const String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static String get appId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? const String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static String get messagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  // FCM topics
  static String get adminTopic =>
      dotenv.env['FCM_ADMIN_TOPIC'] ?? 'admin_notifications';
  static String get technicianTopic =>
      dotenv.env['FCM_TECHNICIAN_TOPIC'] ?? 'technician_notifications';
  static String get newRegistrationTopic =>
      dotenv.env['FCM_NEW_REGISTRATION_TOPIC'] ?? 'new_registrations';
  static String get toolIssuesTopic =>
      dotenv.env['FCM_TOOL_ISSUES_TOPIC'] ?? 'tool_issues';
}
