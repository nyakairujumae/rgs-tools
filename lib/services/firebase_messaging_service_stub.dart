import 'package:flutter/foundation.dart';
import 'firebase_messaging_stub.dart';
import '../utils/logger.dart';

/// Stub implementation for web - all methods are no-ops
class FirebaseMessagingService {
  static String? get fcmToken => null;
  
  static Future<void> initialize() async {
    Logger.debug('🌐 Web platform - Firebase Messaging not available');
  }
  
  static Future<void> sendTokenToServer(String token, String userId) async {
    // No-op on web
  }
  
  static Future<void> unsubscribeFromTopics() async {
    // No-op on web
  }
  
  static Future<void> refreshToken() async {
    // Stub - no-op on web
    // No-op on web
  }
  
  static Future<void> clearBadge() async {
    // No-op on web
  }
}

/// Stub background handler for web - uses stub RemoteMessage type
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op on web
}

