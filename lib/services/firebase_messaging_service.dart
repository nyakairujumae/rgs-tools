import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'supabase_service.dart';
import 'badge_service.dart';
import '../main.dart' show globalNavigatorKey;
import '../screens/admin_notification_screen.dart';

// Background notification channel constants (must be accessible from background handler)
const String _backgroundChannelId = 'rgs_notifications';
const String _backgroundChannelName = 'RGS Notifications';
const String _backgroundChannelDesc = 'Notifications from RGS Tools app';

/// Production-ready Firebase Messaging Service
/// Handles notifications in foreground, background, and terminated states
/// Compatible with notification + data and data-only payloads
/// 
/// CRITICAL RULES:
/// 1. Permission requested ONCE and only once
/// 2. Notification payload → OS handles, NO local notification
/// 3. Data-only payload → Show local notification
/// 4. Listeners registered ONCE and only once
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Android notification channel
  static const String _androidChannelId = 'rgs_notifications';
  static const String _androidChannelName = 'RGS Notifications';
  static const String _androidChannelDesc = 'Notifications from RGS Tools app';

  // Guards to prevent duplicate initialization and permission requests
  static bool _isInitialized = false;
  static bool _permissionRequested = false;
  static bool _iosForegroundOptionsSet = false;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _backgroundSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  static String _getPlatformTag() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Register the current token to backend (app start + login)
  static Future<void> registerCurrentToken({bool forceRefresh = false}) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ [FCM] Cannot register token: Firebase not initialized');
        return;
      }

      String? token;
      if (forceRefresh) {
        token = await refreshToken();
      } else {
        token = await _messaging.getToken();
        if (token == null || token.isEmpty) {
          token = await refreshToken();
        }
      }

      if (token == null || token.isEmpty) {
        debugPrint('❌ [FCM] Cannot register token: token is null/empty');
        return;
      }

      _fcmToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await _sendTokenToServer(token);
      } else {
        debugPrint('⚠️ [FCM] Token saved locally, user not logged in');
      }

      _ensureTokenRefreshListener();
    } catch (e) {
      debugPrint('❌ [FCM] Error registering current token: $e');
    }
  }
  
  /// Force refresh FCM token (useful when token is null)
  static Future<String?> refreshToken() async {
    try {
      debugPrint('🔄 [FCM] Force refreshing FCM token...');
      
      // Verify Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ [FCM] Cannot refresh token: Firebase not initialized');
        return null;
      }
      
      // Check notification settings
      try {
        final settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('❌ [FCM] Cannot refresh token: Notification permission denied');
          return null;
        }
      } catch (e) {
        debugPrint('⚠️ [FCM] Could not check notification settings: $e');
      }
      
      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        _fcmToken = newToken;
        debugPrint('✅ [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        
        // Save to server if user is logged in
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await _sendTokenToServer(newToken);
        }
        
        return newToken;
      } else {
        debugPrint('❌ [FCM] Token refresh returned null');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error refreshing token: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Initialize Firebase Messaging
  /// Call this after Firebase.initializeApp() completes
  /// 
  /// CRITICAL: This method is idempotent - safe to call multiple times
  static Future<void> initialize() async {
    try {
      debugPrint('🔥 [FCM] ========== INITIALIZATION START ==========');
      
      // CRITICAL: Prevent duplicate initialization
      if (_isInitialized) {
        debugPrint('⚠️ [FCM] Already initialized, skipping duplicate initialization');
        debugPrint('⚠️ [FCM] Firebase apps count: ${Firebase.apps.length}');
        for (final app in Firebase.apps) {
          debugPrint('⚠️ [FCM] Firebase app: ${app.name} (${app.options.projectId})');
        }
        return;
      }
      
      // Verify Firebase is initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ [FCM] Firebase not initialized. Call Firebase.initializeApp() first.');
        return;
      }
      
      // Check for multiple Firebase apps (indicates duplicate initialization)
      if (Firebase.apps.length > 1) {
        debugPrint('⚠️ [FCM] WARNING: Multiple Firebase apps detected (${Firebase.apps.length})');
        debugPrint('⚠️ [FCM] This can cause duplicate notifications!');
        for (final app in Firebase.apps) {
          debugPrint('⚠️ [FCM] App: ${app.name}, Project: ${app.options.projectId}');
        }
        debugPrint('⚠️ [FCM] Using default app: ${Firebase.app().name}');
      }
      
      debugPrint('✅ [FCM] Firebase is initialized (${Firebase.apps.length} app(s))');
      
      // Initialize local notifications FIRST (needed for data-only messages)
      await _initializeLocalNotifications();
      
      // CRITICAL: Request notification permissions ONCE and only once
      final permission = await _requestPermissionOnce();
      
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ [FCM] Notification permission granted: ${permission.authorizationStatus}');
        
        // CRITICAL: Set iOS foreground notification presentation options ONCE
        // This ensures notifications appear when app is in foreground
        await _setIOSForegroundOptionsOnce();
        
        // Get FCM token
        await _getFCMToken();
        
        // CRITICAL: Set up message handlers ONCE
        _setupMessageHandlers();
        
        // Subscribe to topics
        await _subscribeToTopics();
        
        // Mark as initialized even if token wasn't obtained (handlers are set up)
        // Token can be obtained later via refreshToken()
        _isInitialized = true;
        
        debugPrint('✅ [FCM] Initialization complete');
        if (_fcmToken == null || _fcmToken!.isEmpty) {
          debugPrint('⚠️ [FCM] WARNING: Initialization complete but token is null');
          debugPrint('⚠️ [FCM] Token will be obtained on next refresh or when permissions are granted');
          
          // Retry getting token after a delay (in case permissions were just granted)
          Future.delayed(const Duration(seconds: 3), () async {
            if (_fcmToken == null || _fcmToken!.isEmpty) {
              debugPrint('🔄 [FCM] Retrying token retrieval after initialization...');
              final retryToken = await refreshToken();
              if (retryToken != null) {
                debugPrint('✅ [FCM] Token obtained on retry');
              } else {
                debugPrint('⚠️ [FCM] Token still null after retry - check notification permissions');
              }
            }
          });
        }
        debugPrint('🔥 [FCM] =========================================');
      } else {
        debugPrint('❌ [FCM] Notification permission denied: ${permission.authorizationStatus}');
        debugPrint('❌ [FCM] Token cannot be obtained without permission');
        debugPrint('❌ [FCM] User must grant notification permission in device settings');
        debugPrint('❌ [FCM] Initialization will be retried when permission is granted');
        // Don't mark as initialized if permission is denied - we want to retry
        // But set up handlers anyway in case permission is granted later
        _setupMessageHandlers();
        debugPrint('🔥 [FCM] =========================================');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Initialization error: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
      debugPrint('🔥 [FCM] =========================================');
      // Don't mark as initialized if there was an error
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We request via Firebase Messaging
        requestBadgePermission: false, // We request via Firebase Messaging
        requestSoundPermission: false, // We request via Firebase Messaging
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

  /// Request notification permissions ONCE and only once
  /// 
  /// CRITICAL: This method is idempotent - safe to call multiple times
  /// It will only request permission once, even across hot restarts
  static Future<NotificationSettings> _requestPermissionOnce() async {
    if (_permissionRequested) {
      debugPrint('⚠️ [FCM] Permission already requested, checking current status...');
      final currentSettings = await _messaging.getNotificationSettings();
      debugPrint('📱 [FCM] Current permission status: ${currentSettings.authorizationStatus}');
      return currentSettings;
    }
    
    debugPrint('📱 [FCM] ========== REQUESTING PERMISSION ==========');
    debugPrint('📱 [FCM] This should only happen ONCE per app install');
    
    _permissionRequested = true;
    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    
    debugPrint('📱 [FCM] Permission request result: ${permission.authorizationStatus}');
    debugPrint('📱 [FCM] Alert: ${permission.alert}');
    debugPrint('📱 [FCM] Badge: ${permission.badge}');
    debugPrint('📱 [FCM] Sound: ${permission.sound}');
    debugPrint('📱 [FCM] ===========================================');
    
    return permission;
  }

  /// Set iOS foreground notification presentation options ONCE
  /// 
  /// CRITICAL: This must be called only once to prevent duplicate handling
  static Future<void> _setIOSForegroundOptionsOnce() async {
    if (!Platform.isIOS) {
      return; // Android doesn't need this
    }
    
    if (_iosForegroundOptionsSet) {
      debugPrint('⚠️ [FCM] iOS foreground options already set, skipping');
      return;
    }
    
    debugPrint('📱 [FCM] ========== SETTING iOS FOREGROUND OPTIONS ==========');
    debugPrint('📱 [FCM] This should only happen ONCE');
    
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    _iosForegroundOptionsSet = true;
    debugPrint('✅ [FCM] iOS foreground notification options set');
    debugPrint('📱 [FCM] ===================================================');
  }

  /// Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      debugPrint('🔄 [FCM] Requesting FCM token...');
      debugPrint('🔄 [FCM] Firebase apps count: ${Firebase.apps.length}');
      debugPrint('🔄 [FCM] Platform: ${Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Unknown")}');
      
      // Check notification settings before requesting token
      try {
        final settings = await _messaging.getNotificationSettings();
        debugPrint('🔄 [FCM] Notification settings:');
        debugPrint('🔄 [FCM]   Authorization: ${settings.authorizationStatus}');
        debugPrint('🔄 [FCM]   Alert: ${settings.alert}');
        debugPrint('🔄 [FCM]   Badge: ${settings.badge}');
        debugPrint('🔄 [FCM]   Sound: ${settings.sound}');
        
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('❌ [FCM] Notification permission is DENIED - token cannot be obtained');
          debugPrint('❌ [FCM] User must grant notification permission in device settings');
          return;
        }
      } catch (settingsError) {
        debugPrint('⚠️ [FCM] Could not check notification settings: $settingsError');
      }
      
      _fcmToken = await _messaging.getToken();
      debugPrint('🔄 [FCM] getToken() returned: ${_fcmToken != null ? "Token (${_fcmToken!.length} chars)" : "NULL"}');
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('✅ [FCM] ========== TOKEN OBTAINED ==========');
        debugPrint('✅ [FCM] Token obtained: ${_fcmToken!.substring(0, 20)}...');
        debugPrint('📱 [FCM] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
        debugPrint('📱 [FCM] Full token length: ${_fcmToken!.length}');
        
        // Save token locally FIRST (always, even if user not logged in)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        debugPrint('✅ [FCM] Token saved to local storage');
        
        // Check if user is logged in
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          debugPrint('✅ [FCM] User is logged in, saving to server...');
        await _sendTokenToServer(_fcmToken!);
        } else {
          debugPrint('⚠️ [FCM] User not logged in yet, token saved locally');
          debugPrint('⚠️ [FCM] Token will be synced to server after login');
        }
        
        debugPrint('✅ [FCM] ===================================');
        
        _ensureTokenRefreshListener();
      } else {
        debugPrint('❌ [FCM] ========== TOKEN IS NULL OR EMPTY ==========');
        debugPrint('❌ [FCM] FCM token is null or empty');
        debugPrint('❌ [FCM] This may indicate:');
        debugPrint('❌ [FCM] 1. Firebase not properly initialized');
        debugPrint('❌ [FCM] 2. Notification permissions not granted');
        debugPrint('❌ [FCM] 3. Network connectivity issues');
        debugPrint('❌ [FCM] 4. Platform-specific issue (iOS simulator, etc.)');
        
        // Try to get more diagnostic info
        try {
          final settings = await _messaging.getNotificationSettings();
          debugPrint('❌ [FCM] Current notification settings:');
          debugPrint('❌ [FCM]   Authorization: ${settings.authorizationStatus}');
          debugPrint('❌ [FCM]   Alert: ${settings.alert}');
          debugPrint('❌ [FCM]   Badge: ${settings.badge}');
          debugPrint('❌ [FCM]   Sound: ${settings.sound}');
          
          if (settings.authorizationStatus == AuthorizationStatus.denied) {
            debugPrint('❌ [FCM] ACTION REQUIRED: Notification permission is DENIED');
            debugPrint('❌ [FCM] User must enable notifications in device settings');
          } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
            debugPrint('❌ [FCM] Permission not yet requested - this should not happen');
          }
        } catch (e) {
          debugPrint('⚠️ [FCM] Could not get notification settings for diagnosis: $e');
        }
        
        debugPrint('❌ [FCM] ============================================');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] ========== TOKEN GET ERROR ==========');
      debugPrint('❌ [FCM] Error getting token: $e');
      debugPrint('❌ [FCM] Error type: ${e.runtimeType}');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
      debugPrint('❌ [FCM] ======================================');
    }
  }

  static void _ensureTokenRefreshListener() {
    if (_tokenRefreshSubscription != null) {
      return;
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isEmpty) {
        debugPrint('⚠️ [FCM] Token refresh returned empty token');
        return;
      }

      debugPrint('🔄 [FCM] ========== TOKEN REFRESHED ==========');
      debugPrint('🔄 [FCM] New token: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);

      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        debugPrint('🔄 [FCM] User is logged in, saving refreshed token...');
        await _sendTokenToServer(newToken);
      } else {
        debugPrint('⚠️ [FCM] User not logged in, refreshed token saved locally');
      }
      debugPrint('🔄 [FCM] =====================================');
    });
  }

  /// Send FCM token to Supabase
  static Future<void> _sendTokenToServer(String token) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [FCM] No user logged in, skipping token save');
      debugPrint('⚠️ [FCM] Token will be saved to local storage and synced after login');
      return;
    }
    
    try {
      final platform = _getPlatformTag();
      final trimmedToken = token.trim();

      if (trimmedToken.isEmpty) {
        debugPrint('⚠️ [FCM] Token is empty after trimming, skipping save');
        return;
      }

      if (platform == 'unknown') {
        debugPrint('⚠️ [FCM] Platform is unknown, skipping token save');
        return;
      }
      
      debugPrint('📤 [FCM] ========== SAVING TOKEN ==========');
      debugPrint('📤 [FCM] User ID: ${user.id}');
      debugPrint('📤 [FCM] Platform: $platform');
      debugPrint('📤 [FCM] Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      debugPrint('📤 [FCM] Token length: ${token.length}');
      
      try {
        await SupabaseService.client
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('platform', platform);
        debugPrint('✅ [FCM] Existing token deleted for user/platform');
      } catch (deleteError) {
        debugPrint('⚠️ [FCM] Delete existing token failed (continuing): $deleteError');
      }

      await SupabaseService.client
          .from('user_fcm_tokens')
          .insert({
            'user_id': user.id,
            'fcm_token': trimmedToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
      debugPrint('✅ [FCM] Insert successful');
      
      // Verify token was saved by querying it back
      try {
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay for DB consistency
        
        final verifyResponse = await SupabaseService.client
            .from('user_fcm_tokens')
            .select('fcm_token, platform, updated_at')
            .eq('user_id', user.id)
            .eq('platform', platform)
            .maybeSingle();
        
        if (verifyResponse != null) {
          final savedToken = verifyResponse['fcm_token'] as String?;
          if (savedToken != null && savedToken == trimmedToken) {
            debugPrint('✅ [FCM] Token verified in database');
            debugPrint('✅ [FCM] Saved token matches: ${savedToken.substring(0, 20)}...');
          } else {
            debugPrint('⚠️ [FCM] Token saved but verification failed - token mismatch');
          }
        } else {
          debugPrint('⚠️ [FCM] Token not found in database after save - possible RLS issue');
          debugPrint('⚠️ [FCM] Check RLS policies for user_fcm_tokens table');
        }
      } catch (verifyError) {
        debugPrint('⚠️ [FCM] Could not verify token save: $verifyError');
      }
      
      debugPrint('✅ [FCM] Token save process completed');
      debugPrint('📤 [FCM] ==================================');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] ========== TOKEN SAVE ERROR ==========');
      debugPrint('❌ [FCM] Error: $e');
      debugPrint('❌ [FCM] Error type: ${e.runtimeType}');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('permission denied') || 
          e.toString().contains('RLS') ||
          e.toString().contains('row-level security')) {
        debugPrint('⚠️ [FCM] RLS policy is blocking the insert/update');
        debugPrint('⚠️ [FCM] Check Supabase RLS policies for user_fcm_tokens table');
        debugPrint('⚠️ [FCM] Policy should allow: INSERT/UPDATE WHERE auth.uid() = user_id');
      }
      
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('unique constraint') ||
          e.toString().contains('23505')) {
        debugPrint('⚠️ [FCM] Duplicate key error - this is expected if token already exists');
        debugPrint('⚠️ [FCM] Token may already be saved, verification will confirm');
      }
      
      if (e.toString().contains('foreign key') || e.toString().contains('23503')) {
        debugPrint('⚠️ [FCM] Foreign key constraint error');
        debugPrint('⚠️ [FCM] User ID may not exist in auth.users table');
      }
      
      debugPrint('❌ [FCM] ======================================');
    }
  }

  /// Set up message handlers for foreground, background, and terminated states
  /// 
  /// CRITICAL: This method cancels existing subscriptions before creating new ones
  /// This ensures listeners are registered ONCE and only once
  static void _setupMessageHandlers() {
    // CRITICAL: Cancel existing subscriptions to prevent duplicates
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
    
    debugPrint('📱 [FCM] ========== SETTING UP HANDLERS ==========');
    debugPrint('📱 [FCM] Previous subscriptions cancelled');
    debugPrint('📱 [FCM] This should only happen ONCE per app launch');
    
    // ============================================
    // FOREGROUND MESSAGES (App is open)
    // ============================================
    // NOTE: onMessage only fires when app is in FOREGROUND
    // When app is in background/terminated, the background handler processes it
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📱 [FCM] ========== FOREGROUND MESSAGE ==========');
      debugPrint('📱 [FCM] Message ID: ${message.messageId}');
      debugPrint('📱 [FCM] From: ${message.from}');
      debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
      debugPrint('📱 [FCM] Data: ${message.data}');
      debugPrint('📱 [FCM] Sent Time: ${message.sentTime}');
      debugPrint('📱 [FCM] App State: FOREGROUND');
      
      // FCM automatically shows notifications when notification field is present
      // Only show local notification if this is a data-only message (no notification field)
      // This prevents duplicate notifications
      if (message.notification == null) {
        debugPrint('📱 [FCM] Data-only message, showing local notification');
      await _showLocalNotification(message);
      } else {
        debugPrint('📱 [FCM] Notification field present, FCM will show it automatically (skipping local notification to avoid duplicates)');
      }
      
      // Update badge regardless of notification type
      await _updateBadge();
      
      debugPrint('📱 [FCM] ======================================');
    });
    
    // ============================================
    // BACKGROUND MESSAGES (App is minimized)
    // ============================================
    _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
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
    
    debugPrint('✅ [FCM] Message handlers set up successfully');
    debugPrint('📱 [FCM] =========================================');
  }

  /// Show local notification for every incoming message when the app is in the foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      String? title = message.notification?.title ??
          (message.data['title'] as String?) ??
          (message.data['notification_title'] as String?);
      String? body = message.notification?.body ??
          (message.data['body'] as String?) ??
          (message.data['notification_body'] as String?) ??
          (message.data['message'] as String?);
      
      // If still no title/body, skip showing notification
      if (title == null || body == null) {
        debugPrint('⚠️ [FCM] No title/body found in payload - skipping local notification');
        return;
      }
      
      debugPrint('📱 [FCM] Showing local notification: $title - $body');
      debugPrint('📱 [FCM] Local notification shown while app is foreground');
      
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
      
      // Use messageId as notification ID, or fallback to hash
      // Use absolute value to ensure positive ID (required by some platforms)
      final notificationId = (message.messageId?.hashCode ?? message.hashCode).abs() % 2147483647;
      
      // Check if we've already shown this notification (prevent duplicates)
      // Use a combination of messageId and timestamp to create unique ID
      final uniqueId = '${message.messageId}_${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
      final notificationKey = 'shown_notification_$uniqueId';
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we've already shown this notification in the last 5 seconds (deduplication window)
      final lastShown = prefs.getInt(notificationKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastShown < 5000) {
        debugPrint('⚠️ [FCM] Duplicate notification detected, skipping (shown ${(now - lastShown) / 1000}s ago)');
        return;
      }
      
      // Mark as shown
      await prefs.setInt(notificationKey, now);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: message.data.toString(),
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
    
    // Navigate to notification center
    _navigateToNotificationCenter();
  }

  /// Handle navigation when app is opened from notification
  static void _handleNotificationNavigation(RemoteMessage message) {
    // Extract navigation data from message.data
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;
    
    debugPrint('📱 [FCM] Navigation - Type: $type, ID: $id');
    
    // Navigate to notification center
    _navigateToNotificationCenter();
  }
  
  /// Navigate to the appropriate notification center based on user role
  static void _navigateToNotificationCenter() {
    debugPrint('📱 [FCM] Navigating to notification center...');
    
    // Use post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = globalNavigatorKey.currentState;
      if (navigator == null) {
        debugPrint('⚠️ [FCM] Navigator not available, cannot navigate');
        return;
      }
      
      try {
        // Check user role from Supabase
        final currentUser = SupabaseService.client.auth.currentUser;
        if (currentUser == null) {
          debugPrint('⚠️ [FCM] No user logged in, cannot navigate to notifications');
          return;
        }
        
        final userRole = currentUser.userMetadata?['role'] as String?;
        debugPrint('📱 [FCM] User role: $userRole');
        
        if (userRole == 'admin') {
          // Navigate to admin notification center (separate screen)
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const AdminNotificationScreen(),
            ),
          );
          debugPrint('✅ [FCM] Navigated to Admin Notification Center');
        } else if (userRole == 'technician') {
          // For technicians, just go to home - they have a notification bell there
          // The notification badge will show and they can tap to see notifications
          navigator.pushNamedAndRemoveUntil('/technician', (route) => false);
          debugPrint('✅ [FCM] Navigated to Technician Home');
        } else {
          debugPrint('⚠️ [FCM] Unknown user role: $userRole');
        }
      } catch (e) {
        debugPrint('❌ [FCM] Error navigating to notification center: $e');
      }
    });
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
      final platform = _getPlatformTag();
      final trimmedToken = token.trim();

      if (trimmedToken.isEmpty) {
        debugPrint('⚠️ [FCM] Token is empty after trimming, skipping save');
        return;
      }

      if (platform == 'unknown') {
        debugPrint('⚠️ [FCM] Platform is unknown, skipping token save');
        return;
      }
      
      debugPrint('📤 [FCM] Sending token to server for user: $userId, platform: $platform');
      
      try {
        await SupabaseService.client
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('platform', platform);
        debugPrint('✅ [FCM] Existing token deleted for user/platform');
      } catch (deleteError) {
        debugPrint('⚠️ [FCM] Delete existing token failed (continuing): $deleteError');
      }

      await SupabaseService.client
          .from('user_fcm_tokens')
          .insert({
            'user_id': userId,
            'fcm_token': trimmedToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      debugPrint('✅ [FCM] Token sent to server successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Error sending token: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Save token from local storage to server (for when user logs in after token was generated)
  static Future<void> saveTokenFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      
      if (savedToken == null || savedToken.isEmpty) {
        debugPrint('⚠️ [FCM] No token found in local storage');
        return;
      }
      
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [FCM] No user logged in, cannot save token from local storage');
        return;
      }
      
      debugPrint('📤 [FCM] Saving token from local storage for user: ${user.id}');
      await sendTokenToServer(savedToken, user.id);
    } catch (e) {
      debugPrint('❌ [FCM] Error saving token from local storage: $e');
    }
  }

}

/// Background message handler (must be top-level function)
/// This runs when app is in background or terminated state
/// Handles both notification + data and data-only payloads
/// 
/// CRITICAL RULES:
/// 1. This handler ONLY runs when app is in BACKGROUND or TERMINATED
/// 2. When app is in FOREGROUND, onMessage.listen() handles it instead
/// 3. If message has notification payload → OS shows it, handler only updates badge
/// 4. If message is data-only → Handler shows local notification
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 [FCM] ========== BACKGROUND/TERMINATED MESSAGE ==========');
  debugPrint('📱 [FCM] Message ID: ${message.messageId}');
  debugPrint('📱 [FCM] From: ${message.from}');
  debugPrint('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
  debugPrint('📱 [FCM] Data: ${message.data}');
  debugPrint('📱 [FCM] Sent Time: ${message.sentTime}');
  debugPrint('📱 [FCM] App State: BACKGROUND/TERMINATED');
  
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
      requestAlertPermission: false, // Already requested in main app
      requestBadgePermission: false, // Already requested in main app
      requestSoundPermission: false, // Already requested in main app
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
    
    // CRITICAL RULE: Check if message has notification payload
    if (message.notification != null) {
      // Message has notification payload → OS shows it automatically
      // DO NOT show local notification (would cause duplicate)
      debugPrint('📱 [FCM] Message has notification payload → OS handles display');
      debugPrint('📱 [FCM] System will show notification automatically');
      debugPrint('📱 [FCM] NOT showing local notification (prevents duplicate)');
      debugPrint('📱 [FCM] Only updating badge: $badgeCount');
    } else if (message.data.isNotEmpty) {
      // Data-only message → We must show local notification
      debugPrint('📱 [FCM] Data-only message → Showing local notification');
      
      // Extract title and body from data payload
      final title = message.data['title'] as String? ?? 
                    message.data['notification_title'] as String?;
      final body = message.data['body'] as String? ?? 
                   message.data['notification_body'] as String? ??
                   message.data['message'] as String?;
      
      if (title != null && body != null) {
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
        debugPrint('⚠️ [FCM] No title/body found in data payload - skipping local notification');
      }
    } else {
      debugPrint('⚠️ [FCM] Message has no notification payload and no data - skipping');
    }
    
    debugPrint('📱 [FCM] ====================================================');
  } catch (e, stackTrace) {
    debugPrint('❌ [FCM] Error handling background message: $e');
    debugPrint('❌ [FCM] Stack trace: $stackTrace');
  }
}
