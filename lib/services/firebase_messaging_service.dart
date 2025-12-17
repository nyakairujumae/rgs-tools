import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'supabase_service.dart';
import 'badge_service.dart';

// Background notification channel constants (must be accessible from background handler)
const String _backgroundChannelId = 'rgs_notifications';
const String _backgroundChannelName = 'RGS Notifications';
const String _backgroundChannelDesc = 'Notifications from RGS Tools app';

/// Production-ready Firebase Messaging Service
/// Handles notifications in foreground, background, and terminated states
/// Compatible with notification + data payloads from any backend
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
      
      // Initialize local notifications FIRST (needed for foreground notifications)
      await _initializeLocalNotifications();
      
      // Request notification permissions
      final permission = await _requestPermission();
      
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ [FCM] Notification permission granted');
        
        // CRITICAL: Set iOS foreground notification presentation options
        // This ensures notifications appear when app is in foreground
        if (Platform.isIOS) {
          await _messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('✅ [FCM] iOS foreground notification options set');
        }
        
        // Get FCM token
        await _getFCMToken();
        
        // Set up message handlers
        _setupMessageHandlers();
        
        // Subscribe to topics
        await _subscribeToTopics();
        
        debugPrint('✅ [FCM] Initialization complete');
      } else {
        debugPrint('❌ [FCM] Notification permission denied: ${permission.authorizationStatus}');
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
      
      // Create Android notification channel (required for Android 8.0+)
      const androidChannel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
        showBadge: true,
        playSound: true,
        enableVibration: true,
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
        debugPrint('📱 [FCM] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
        debugPrint('📱 [FCM] Full token length: ${_fcmToken!.length}');
        
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
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error getting token: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Send FCM token to Supabase
  static Future<void> _sendTokenToServer(String token) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [FCM] No user logged in, skipping token save');
      return;
    }
    
    try {
      final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');
      
      debugPrint('📤 [FCM] Saving token for user: ${user.id}, platform: $platform');
      
      await SupabaseService.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': user.id,
            'fcm_token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,platform');
      
      debugPrint('✅ [FCM] Token saved to Supabase successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error saving token: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
      
      // Try update as fallback
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        try {
          final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');
          await SupabaseService.client
              .from('user_fcm_tokens')
              .update({
                'fcm_token': token,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id)
              .eq('platform', platform);
          debugPrint('✅ [FCM] Token updated successfully');
        } catch (updateError) {
          debugPrint('❌ [FCM] Update also failed: $updateError');
        }
      }
    }
  }

  /// Set up message handlers for foreground, background, and terminated states
  static void _setupMessageHandlers() {
    // ============================================
    // FOREGROUND MESSAGES (App is open)
    // ============================================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📱 [FCM] ========== FOREGROUND MESSAGE ==========');
      debugPrint('📱 [FCM] Message ID: ${message.messageId}');
      debugPrint('📱 [FCM] From: ${message.from}');
      debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
      debugPrint('📱 [FCM] Data: ${message.data}');
      debugPrint('📱 [FCM] Sent Time: ${message.sentTime}');
      
      // Show local notification (required for foreground on both platforms)
      await _showLocalNotification(message);
      
      // Update badge
      await _updateBadge();
      
      debugPrint('📱 [FCM] ======================================');
    });
    
    // ============================================
    // BACKGROUND MESSAGES (App is minimized)
    // ============================================
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 [FCM] ========== APP OPENED FROM BACKGROUND ==========');
      debugPrint('📱 [FCM] Message ID: ${message.messageId}');
      debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
      debugPrint('📱 [FCM] Data: ${message.data}');
      debugPrint('📱 [FCM] ================================================');
      
      // Handle navigation based on data
      _handleNotificationNavigation(message);
    });
    
    // ============================================
    // TERMINATED STATE (App was closed)
    // ============================================
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 [FCM] ========== APP OPENED FROM TERMINATED ==========');
        debugPrint('📱 [FCM] Message ID: ${message.messageId}');
        debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
        debugPrint('📱 [FCM] Data: ${message.data}');
        debugPrint('📱 [FCM] ================================================');
        
        // Handle navigation based on data
        _handleNotificationNavigation(message);
      }
    });
  }

  /// Show local notification (for foreground messages)
  /// Handles both notification payload and data-only messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Extract title and body from notification payload OR data payload
      String? title;
      String? body;
      
      if (message.notification != null) {
        title = message.notification!.title;
        body = message.notification!.body;
      } else if (message.data.isNotEmpty) {
        // Fallback to data payload if notification is null (data-only message)
        title = message.data['title'] as String? ?? message.data['notification_title'] as String?;
        body = message.data['body'] as String? ?? message.data['notification_body'] as String? ?? message.data['message'] as String?;
      }
      
      // If still no title/body, skip showing notification
      if (title == null || body == null) {
        debugPrint('⚠️ [FCM] No title/body found in notification or data payload');
        return;
      }
      
      debugPrint('📱 [FCM] Showing local notification: $title - $body');
      
      // Get current badge count
      final badgeCount = await BadgeService.getBadgeCount();
      
      const androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        number: null, // Don't show number in notification itself
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badgeCount > 0 ? badgeCount : null,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Use messageId as notification ID, or fallback to hash
      final notificationId = message.messageId?.hashCode ?? message.hashCode;
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: message.data.toString(), // Pass data as payload for tap handling
      );
      
      debugPrint('✅ [FCM] Local notification displayed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error showing local notification: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Handle notification tap navigation
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 [FCM] ========== NOTIFICATION TAPPED ==========');
    debugPrint('📱 [FCM] Notification ID: ${response.id}');
    debugPrint('📱 [FCM] Action ID: ${response.actionId}');
    debugPrint('📱 [FCM] Payload: ${response.payload}');
    debugPrint('📱 [FCM] =========================================');
    
    // Parse payload and handle navigation
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Payload might be data map as string, parse if needed
        // For now, just log it - navigation can be handled by app-specific logic
        debugPrint('📱 [FCM] Payload data available for navigation');
      } catch (e) {
        debugPrint('⚠️ [FCM] Error parsing payload: $e');
      }
    }
  }

  /// Handle navigation when app is opened from notification
  static void _handleNotificationNavigation(RemoteMessage message) {
    // Extract navigation data from message.data
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;
    
    debugPrint('📱 [FCM] Navigation - Type: $type, ID: $id');
    
    // Navigation logic can be implemented here based on app structure
    // For now, just log the data
  }

  /// Update app badge (increment by 1)
  static Future<void> _updateBadge() async {
    try {
      await BadgeService.incrementBadge();
      final badgeCount = await BadgeService.getBadgeCount();
      debugPrint('✅ [FCM] Badge updated to: $badgeCount');
    } catch (e) {
      debugPrint('❌ [FCM] Error updating badge: $e');
    }
  }

  /// Clear badge
  static Future<void> clearBadge() async {
    try {
      await BadgeService.clearBadge();
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
      final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');
      
      debugPrint('📤 [FCM] Sending token to server for user: $userId, platform: $platform');
      
      await SupabaseService.client
          .from('user_fcm_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,platform');
      
      debugPrint('✅ [FCM] Token sent to server successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error sending token: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Refresh FCM token manually
  static Future<void> refreshToken() async {
    try {
      await _getFCMToken();
      debugPrint('✅ [FCM] Token refreshed');
    } catch (e) {
      debugPrint('❌ [FCM] Error refreshing token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
/// This runs when app is in background or terminated state
/// Handles both notification + data and data-only payloads
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 [FCM] ========== BACKGROUND/TERMINATED MESSAGE ==========');
  debugPrint('📱 [FCM] Message ID: ${message.messageId}');
  debugPrint('📱 [FCM] From: ${message.from}');
  debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
  debugPrint('📱 [FCM] Data: ${message.data}');
  debugPrint('📱 [FCM] Sent Time: ${message.sentTime}');
  
  // Initialize Firebase if not already initialized (background handlers run in separate isolate)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ [FCM] Firebase initialized in background handler');
  }
  
  try {
    // Initialize local notifications plugin (needed in background isolate)
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
    
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.initialize(initSettings);
    
    // Create Android notification channel if needed
    const androidChannel = AndroidNotificationChannel(
      _backgroundChannelId,
      _backgroundChannelName,
      description: _backgroundChannelDesc,
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );
    
    final androidPlugin = localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    
    // Update badge (increment by 1)
    await BadgeService.incrementBadge();
    final badgeCount = await BadgeService.getBadgeCount();
    
    // Extract title and body from notification OR data payload
    String? title;
    String? body;
    
    if (message.notification != null) {
      title = message.notification!.title;
      body = message.notification!.body;
    } else if (message.data.isNotEmpty) {
      // Handle data-only messages (extract from data payload)
      title = message.data['title'] as String? ?? 
              message.data['notification_title'] as String? ??
              message.data['notification']?['title'] as String?;
      body = message.data['body'] as String? ?? 
             message.data['notification_body'] as String? ??
             message.data['message'] as String? ??
             message.data['notification']?['body'] as String?;
    }
    
    // Only show notification if we have title and body
    if (title != null && body != null) {
      debugPrint('📱 [FCM] Showing background notification: $title - $body');
      
      final androidDetails = AndroidNotificationDetails(
        _backgroundChannelId,
        _backgroundChannelName,
        channelDescription: _backgroundChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        number: null,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badgeCount > 0 ? badgeCount : null,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final notificationId = message.messageId?.hashCode ?? message.hashCode;
      
      await localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: message.data.toString(),
      );
      
      debugPrint('✅ [FCM] Background notification displayed with badge: $badgeCount');
    } else {
      debugPrint('⚠️ [FCM] No title/body found in notification or data payload - skipping display');
      // Still update badge even if we can't show notification
    }
    
    debugPrint('📱 [FCM] ====================================================');
  } catch (e, stackTrace) {
    debugPrint('❌ [FCM] Error handling background message: $e');
    debugPrint('❌ [FCM] Stack trace: $stackTrace');
  }
}
