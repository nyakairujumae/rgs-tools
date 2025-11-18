import 'package:flutter/foundation.dart';

/// Stub implementation for web - all methods are no-ops
class FirebaseMessagingService {
  static String? get fcmToken => null;
  
  static Future<void> initialize() async {
    debugPrint('🌐 Web platform - Firebase Messaging not available');
  }
  
  static Future<void> sendTokenToServer(String token, String userId) async {
    // No-op on web
  }
  
  static Future<void> unsubscribeFromTopics() async {
    // No-op on web
  }
  
  static Future<void> refreshToken() async {
    // No-op on web
  }
  
  static Future<void> clearBadge() async {
    // No-op on web
  }
}

/// Stub background handler for web
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // No-op on web
}

