import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/firebase_config.dart';
import 'supabase_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const String _androidChannelId = 'default_channel';
  static const String _androidChannelName = 'General';
  static const String _androidChannelDesc = 'General notifications';

  static String? get fcmToken {
    try {
      // Check if Firebase is initialized before accessing messaging
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ Firebase not initialized, cannot get FCM token');
        return null;
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 Initializing Firebase Messaging...');
      
      // Check if Firebase is initialized - wait a bit and retry if needed
      int retries = 0;
      while (Firebase.apps.isEmpty && retries < 5) {
        debugPrint('⏳ Waiting for Firebase initialization... (attempt ${retries + 1}/5)');
        await Future.delayed(Duration(milliseconds: 500));
        retries++;
      }
      
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ Firebase not initialized after waiting. Please check Firebase setup.');
        return;
      }
      
      debugPrint('✅ Firebase is initialized. Proceeding with FCM setup...');
      
      // Initialize local notifications (for foreground + badge number)
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );
      await _local.initialize(initializationSettings);
      // Ensure channel exists with showBadge
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.defaultImportance,
        showBadge: true,
      );
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      
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
      
      // Send token to Supabase if user is authenticated
      if (_fcmToken != null) {
        try {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            await sendTokenToServer(_fcmToken!, currentUser.id);
          }
        } catch (e) {
          debugPrint('⚠️ Could not send FCM token to server (user may not be logged in): $e');
        }
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        
        // Send new token to server if user is authenticated
        try {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            await sendTokenToServer(newToken, currentUser.id);
          }
        } catch (e) {
          debugPrint('⚠️ Could not send refreshed FCM token to server: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔥 Received foreground message: ${message.messageId}');
      debugPrint('🔥 Message data: ${message.data}');
      debugPrint('🔥 Message notification: ${message.notification?.title}');
      
      // Show local notification or handle in-app
      _handleForegroundMessage(message);
      final newCount = await _incrementBadgeCount();
      await _showLocalFromMessage(message, badgeCount: newCount);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔥 App opened from background message: ${message.messageId}');
      _handleBackgroundMessage(message);
    });

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
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

  /// Badge helpers
  static const String _badgeKey = 'app_badge_count';

  static Future<int> _incrementBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_badgeKey) ?? 0;
      final updated = current + 1;
      await prefs.setInt(_badgeKey, updated);
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.updateBadgeCount(updated);
      }
      return updated;
    } catch (e) {
      debugPrint('⚠️ Failed to increment badge: $e');
      return 0;
    }
  }

  static Future<void> clearBadge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeKey, 0);
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to clear badge: $e');
    }
  }

  static Future<void> _showLocalFromMessage(RemoteMessage msg,
      {required int badgeCount}) async {
    final title = msg.notification?.title ?? 'RGS';
    final body = msg.notification?.body ?? 'You have a new notification';
    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      number: badgeCount,
    );
    final darwinDetails = DarwinNotificationDetails(
      badgeNumber: badgeCount,
    );
    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);
    await _local.show(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000,
      title,
      body,
      details,
      payload: msg.data.isNotEmpty ? msg.data.toString() : null,
    );
  }

  /// Send token to server (Supabase)
  static Future<void> sendTokenToServer(String token, String userId) async {
    try {
      debugPrint('🔥 Sending FCM token to server for user: $userId');
      
      // Upsert FCM token to Supabase
      await SupabaseService.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
      
      debugPrint('✅ FCM token saved to Supabase successfully');
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');
      // Don't throw - this is not critical for app functionality
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
  // Increment stored count and update badge immediately; also show a local notif
  try {
    final prefs = await SharedPreferences.getInstance();
    const badgeKey = 'app_badge_count';
    final current = prefs.getInt(badgeKey) ?? 0;
    final updated = current + 1;
    await prefs.setInt(badgeKey, updated);
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      FlutterAppBadger.updateBadgeCount(updated);
    }
    // Show local notification from background isolate
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(initializationSettings);
    const androidChannelId = 'default_channel';
    const androidChannelName = 'General';
    const androidChannelDesc = 'General notifications';
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      description: androidChannelDesc,
      importance: Importance.defaultImportance,
      showBadge: true,
    );
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    final androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      number: updated,
    );
    final darwinDetails = DarwinNotificationDetails(
      badgeNumber: updated,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: darwinDetails);
    await plugin.show(
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000,
      message.notification?.title ?? 'RGS',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  } catch (e) {
    debugPrint('⚠️ Background badge/local notification failed: $e');
  }
}
