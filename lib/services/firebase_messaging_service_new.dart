import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

/// Clean Firebase Messaging Service - Fresh Implementation
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Android notification channel
  static const String _androidChannelId = 'rgs_notifications';
  static const String _androidChannelName = 'RGS Notifications';
  static const String _androidChannelDesc = 'Notifications from RGS Tools app';

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  /// Call this after Firebase.initializeApp() completes
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 [FCM] Starting initialization...');
      
      // Verify Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ [FCM] Firebase not initialized. Call Firebase.initializeApp() first.');
        return;
      }
      
      debugPrint('✅ [FCM] Firebase is initialized');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request notification permissions
      final permission = await _requestPermission();
      
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ [FCM] Notification permission granted');
        
        // Get FCM token
        await _getFCMToken();
        
        // Set up message handlers
        _setupMessageHandlers();
        
        // Subscribe to topics
        await _subscribeToTopics();
        
        debugPrint('✅ [FCM] Initialization complete');
      } else {
        debugPrint('❌ [FCM] Notification permission denied');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Initialization error: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create Android notification channel
      const androidChannel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
        showBadge: true,
      );
      
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(androidChannel);
      
      debugPrint('✅ [FCM] Local notifications initialized');
    } catch (e) {
      debugPrint('❌ [FCM] Local notifications init error: $e');
    }
  }

  /// Request notification permissions
  static Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  /// Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        debugPrint('✅ [FCM] Token obtained: ${_fcmToken!.substring(0, 20)}...');
        
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // Send token to server if user is logged in
        await _sendTokenToServer(_fcmToken!);
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('🔄 [FCM] Token refreshed');
          _fcmToken = newToken;
          await prefs.setString('fcm_token', newToken);
          await _sendTokenToServer(newToken);
        });
      } else {
        debugPrint('⚠️ [FCM] FCM token is null');
      }
    } catch (e) {
      debugPrint('❌ [FCM] Error getting token: $e');
    }
  }

  /// Send FCM token to Supabase
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [FCM] No user logged in, skipping token save');
        return;
      }
      
      await SupabaseService.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': user.id,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      debugPrint('✅ [FCM] Token saved to Supabase');
    } catch (e) {
      debugPrint('❌ [FCM] Error saving token: $e');
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📱 [FCM] Foreground message received: ${message.notification?.title}');
      
      // Show local notification
      await _showLocalNotification(message);
      
      // Update badge
      await _updateBadge();
    });
    
    // Background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 [FCM] App opened from notification: ${message.notification?.title}');
      // Handle navigation if needed
    });
    
    // Check if app was opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 [FCM] App opened from terminated state: ${message.notification?.title}');
        // Handle navigation if needed
      }
    });
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;
      
      const androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
      
      debugPrint('✅ [FCM] Local notification shown');
    } catch (e) {
      debugPrint('❌ [FCM] Error showing notification: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 [FCM] Notification tapped: ${response.id}');
    // Handle navigation if needed
  }

  /// Update app badge
  static Future<void> _updateBadge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int badgeCount = prefs.getInt('badge_count') ?? 0;
      badgeCount++;
      await prefs.setInt('badge_count', badgeCount);
      
      await FlutterAppBadger.updateBadgeCount(badgeCount);
      debugPrint('✅ [FCM] Badge updated: $badgeCount');
    } catch (e) {
      debugPrint('❌ [FCM] Error updating badge: $e');
    }
  }

  /// Clear badge
  static Future<void> clearBadge() async {
    try {
      await FlutterAppBadger.removeBadge();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_count', 0);
      debugPrint('✅ [FCM] Badge cleared');
    } catch (e) {
      debugPrint('❌ [FCM] Error clearing badge: $e');
    }
  }

  /// Subscribe to FCM topics
  static Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('admin');
      await _messaging.subscribeToTopic('new_registration');
      await _messaging.subscribeToTopic('tool_issues');
      debugPrint('✅ [FCM] Subscribed to topics');
    } catch (e) {
      debugPrint('❌ [FCM] Error subscribing to topics: $e');
    }
  }

  /// Send token to server (public method for manual refresh)
  static Future<void> sendTokenToServer(String token, String userId) async {
    try {
      await SupabaseService.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          });
      debugPrint('✅ [FCM] Token sent to server');
    } catch (e) {
      debugPrint('❌ [FCM] Error sending token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 [FCM] Background message: ${message.notification?.title}');
  
  // Update badge
  try {
    final prefs = await SharedPreferences.getInstance();
    int badgeCount = prefs.getInt('badge_count') ?? 0;
    badgeCount++;
    await prefs.setInt('badge_count', badgeCount);
    await FlutterAppBadger.updateBadgeCount(badgeCount);
  } catch (e) {
    debugPrint('❌ [FCM] Error updating badge in background: $e');
  }
}



