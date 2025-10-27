import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 Initializing Firebase Messaging...');
      
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔥 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔥 Notification permission granted');
        
        // Get FCM token
        await _getFCMToken();
        
        // Set up message handlers
        _setupMessageHandlers();
        
        // Subscribe to topics
        await _subscribeToTopics();
        
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('🔥 Provisional notification permission granted');
        await _getFCMToken();
        _setupMessageHandlers();
      } else {
        debugPrint('❌ Notification permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('🔥 FCM Token: $_fcmToken');
      
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken ?? '');
      
      // TODO: Send token to your backend server
      // await _sendTokenToServer(_fcmToken);
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    _messaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔥 Received foreground message: ${message.messageId}');
      debugPrint('🔥 Message data: ${message.data}');
      debugPrint('🔥 Message notification: ${message.notification?.title}');
      
      // Show local notification or handle in-app
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    _messaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔥 App opened from background message: ${message.messageId}');
      _handleBackgroundMessage(message);
    });

    // Handle messages when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔥 App opened from terminated state: ${message.messageId}');
        _handleBackgroundMessage(message);
      }
    });
  }

  /// Subscribe to relevant topics
  static Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic(FirebaseConfig.adminTopic);
      await _messaging.subscribeToTopic(FirebaseConfig.newRegistrationTopic);
      await _messaging.subscribeToTopic(FirebaseConfig.toolIssuesTopic);
      
      debugPrint('🔥 Subscribed to FCM topics');
    } catch (e) {
      debugPrint('❌ Error subscribing to topics: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification or snackbar
    if (kDebugMode) {
      debugPrint('🔥 Foreground message: ${message.notification?.title}');
    }
    
    // You can show a custom in-app notification here
    // For now, just log the message
  }

  /// Handle background messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('🔥 Background message: ${message.notification?.title}');
    
    // Navigate to relevant screen based on message data
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'new_registration':
          // Navigate to admin approval screen
          debugPrint('🔥 Navigate to admin approval screen');
          break;
        case 'tool_issue':
          // Navigate to tool issues screen
          debugPrint('🔥 Navigate to tool issues screen');
          break;
        default:
          debugPrint('🔥 Unknown message type: ${data['type']}');
      }
    }
  }

  /// Send token to server (implement based on your backend)
  static Future<void> sendTokenToServer(String token, String userId) async {
    try {
      // TODO: Implement API call to send token to your backend
      debugPrint('🔥 Sending FCM token to server for user: $userId');
      
      // Example API call:
      // await SupabaseService.client
      //     .from('user_fcm_tokens')
      //     .upsert({
      //       'user_id': userId,
      //       'fcm_token': token,
      //       'updated_at': DateTime.now().toIso8601String(),
      //     });
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');
    }
  }

  /// Unsubscribe from topics
  static Future<void> unsubscribeFromTopics() async {
    try {
      await _messaging.unsubscribeFromTopic(FirebaseConfig.adminTopic);
      await _messaging.unsubscribeFromTopic(FirebaseConfig.newRegistrationTopic);
      await _messaging.unsubscribeFromTopic(FirebaseConfig.toolIssuesTopic);
      
      debugPrint('🔥 Unsubscribed from FCM topics');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topics: $e');
    }
  }

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    try {
      await _getFCMToken();
      debugPrint('🔥 FCM token refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔥 Background message handler: ${message.messageId}');
  debugPrint('🔥 Message data: ${message.data}');
}
