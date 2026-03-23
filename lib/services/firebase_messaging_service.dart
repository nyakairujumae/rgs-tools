import 'dart:convert';
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
import '../screens/admin_approval_screen.dart';
import '../screens/approval_workflows_screen.dart';
import '../screens/tool_issues_screen.dart';
import '../screens/maintenance_screen.dart';
import '../screens/technician_home_screen.dart';
import '../utils/logger.dart';

// Background notification channel constants (must be accessible from background handler)
const String _backgroundChannelId = 'app_notifications';
const String _backgroundChannelName = 'App Notifications';
const String _backgroundChannelDesc = 'Notifications from the app';

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
  static const String _androidChannelId = 'app_notifications';
  static const String _androidChannelName = 'App Notifications';
  static const String _androidChannelDesc = 'Notifications from the app';

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
        Logger.debug('❌ [FCM] Cannot register token: Firebase not initialized');
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
        Logger.debug('❌ [FCM] Cannot register token: token is null/empty');
        return;
      }

      _fcmToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await _sendTokenToServer(token);
      } else {
        Logger.debug('⚠️ [FCM] Token saved locally, user not logged in');
      }

      _ensureTokenRefreshListener();
    } catch (e) {
      Logger.debug('❌ [FCM] Error registering current token: $e');
    }
  }
  
  /// Force refresh FCM token (useful when token is null)
  static Future<String?> refreshToken() async {
    try {
      Logger.debug('🔄 [FCM] Force refreshing FCM token...');
      
      // Verify Firebase is initialized
      if (Firebase.apps.isEmpty) {
        Logger.debug('❌ [FCM] Cannot refresh token: Firebase not initialized');
        return null;
      }
      
      // Check notification settings
      try {
        final settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          Logger.debug('❌ [FCM] Cannot refresh token: Notification permission denied');
          return null;
        }
      } catch (e) {
        Logger.debug('⚠️ [FCM] Could not check notification settings: $e');
      }
      
      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        _fcmToken = newToken;
        Logger.debug('✅ [FCM] Token refreshed: ${newToken.substring(0, 20)}...');
        
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
        Logger.debug('❌ [FCM] Token refresh returned null');
        return null;
      }
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] Error refreshing token: $e');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Initialize Firebase Messaging
  /// Call this after Firebase.initializeApp() completes
  /// 
  /// CRITICAL: This method is idempotent - safe to call multiple times
  static Future<void> initialize() async {
    try {
      Logger.debug('🔥 [FCM] ========== INITIALIZATION START ==========');
      
      // CRITICAL: Prevent duplicate initialization
      if (_isInitialized) {
        Logger.debug('⚠️ [FCM] Already initialized, skipping duplicate initialization');
        Logger.debug('⚠️ [FCM] Firebase apps count: ${Firebase.apps.length}');
        for (final app in Firebase.apps) {
          Logger.debug('⚠️ [FCM] Firebase app: ${app.name} (${app.options.projectId})');
        }
        return;
      }
      
      // Verify Firebase is initialized
      if (Firebase.apps.isEmpty) {
        Logger.debug('❌ [FCM] Firebase not initialized. Call Firebase.initializeApp() first.');
        return;
      }
      
      // Check for multiple Firebase apps (indicates duplicate initialization)
      if (Firebase.apps.length > 1) {
        Logger.debug('⚠️ [FCM] WARNING: Multiple Firebase apps detected (${Firebase.apps.length})');
        Logger.debug('⚠️ [FCM] This can cause duplicate notifications!');
        for (final app in Firebase.apps) {
          Logger.debug('⚠️ [FCM] App: ${app.name}, Project: ${app.options.projectId}');
        }
        Logger.debug('⚠️ [FCM] Using default app: ${Firebase.app().name}');
      }
      
      Logger.debug('✅ [FCM] Firebase is initialized (${Firebase.apps.length} app(s))');
      
      // Initialize local notifications FIRST (needed for data-only messages)
      await _initializeLocalNotifications();
      
      // CRITICAL: Request notification permissions ONCE and only once
      final permission = await _requestPermissionOnce();
      
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        Logger.debug('✅ [FCM] Notification permission granted: ${permission.authorizationStatus}');
        
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
        
        Logger.debug('✅ [FCM] Initialization complete');
        if (_fcmToken == null || _fcmToken!.isEmpty) {
          Logger.debug('⚠️ [FCM] WARNING: Initialization complete but token is null');
          Logger.debug('⚠️ [FCM] Token will be obtained on next refresh or when permissions are granted');
          
          // Retry getting token after a delay (in case permissions were just granted)
          Future.delayed(const Duration(seconds: 3), () async {
            if (_fcmToken == null || _fcmToken!.isEmpty) {
              Logger.debug('🔄 [FCM] Retrying token retrieval after initialization...');
              final retryToken = await refreshToken();
              if (retryToken != null) {
                Logger.debug('✅ [FCM] Token obtained on retry');
              } else {
                Logger.debug('⚠️ [FCM] Token still null after retry - check notification permissions');
              }
            }
          });
        }
        Logger.debug('🔥 [FCM] =========================================');
      } else {
        Logger.debug('❌ [FCM] Notification permission denied: ${permission.authorizationStatus}');
        Logger.debug('❌ [FCM] Token cannot be obtained without permission');
        Logger.debug('❌ [FCM] User must grant notification permission in device settings');
        Logger.debug('❌ [FCM] Initialization will be retried when permission is granted');
        // Don't mark as initialized if permission is denied - we want to retry
        // But set up handlers anyway in case permission is granted later
        _setupMessageHandlers();
        Logger.debug('🔥 [FCM] =========================================');
      }
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] Initialization error: $e');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
      Logger.debug('🔥 [FCM] =========================================');
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
      
      Logger.debug('✅ [FCM] Local notifications initialized');
    } catch (e) {
      Logger.debug('❌ [FCM] Local notifications init error: $e');
    }
  }

  /// Request notification permissions ONCE and only once
  /// 
  /// CRITICAL: This method is idempotent - safe to call multiple times
  /// It will only request permission once, even across hot restarts
  static Future<NotificationSettings> _requestPermissionOnce() async {
    if (_permissionRequested) {
      Logger.debug('⚠️ [FCM] Permission already requested, checking current status...');
      final currentSettings = await _messaging.getNotificationSettings();
      Logger.debug('📱 [FCM] Current permission status: ${currentSettings.authorizationStatus}');
      return currentSettings;
    }
    
    Logger.debug('📱 [FCM] ========== REQUESTING PERMISSION ==========');
    Logger.debug('📱 [FCM] This should only happen ONCE per app install');
    
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
    
    Logger.debug('📱 [FCM] Permission request result: ${permission.authorizationStatus}');
    Logger.debug('📱 [FCM] Alert: ${permission.alert}');
    Logger.debug('📱 [FCM] Badge: ${permission.badge}');
    Logger.debug('📱 [FCM] Sound: ${permission.sound}');
    Logger.debug('📱 [FCM] ===========================================');
    
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
      Logger.debug('⚠️ [FCM] iOS foreground options already set, skipping');
      return;
    }
    
    Logger.debug('📱 [FCM] ========== SETTING iOS FOREGROUND OPTIONS ==========');
    Logger.debug('📱 [FCM] This should only happen ONCE');
    
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    _iosForegroundOptionsSet = true;
    Logger.debug('✅ [FCM] iOS foreground notification options set');
    Logger.debug('📱 [FCM] ===================================================');
  }

  /// Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      Logger.debug('🔄 [FCM] Requesting FCM token...');
      Logger.debug('🔄 [FCM] Firebase apps count: ${Firebase.apps.length}');
      Logger.debug('🔄 [FCM] Platform: ${Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Unknown")}');
      
      // Check notification settings before requesting token
      try {
        final settings = await _messaging.getNotificationSettings();
        Logger.debug('🔄 [FCM] Notification settings:');
        Logger.debug('🔄 [FCM]   Authorization: ${settings.authorizationStatus}');
        Logger.debug('🔄 [FCM]   Alert: ${settings.alert}');
        Logger.debug('🔄 [FCM]   Badge: ${settings.badge}');
        Logger.debug('🔄 [FCM]   Sound: ${settings.sound}');
        
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          Logger.debug('❌ [FCM] Notification permission is DENIED - token cannot be obtained');
          Logger.debug('❌ [FCM] User must grant notification permission in device settings');
          return;
        }
      } catch (settingsError) {
        Logger.debug('⚠️ [FCM] Could not check notification settings: $settingsError');
      }
      
      _fcmToken = await _messaging.getToken();
      Logger.debug('🔄 [FCM] getToken() returned: ${_fcmToken != null ? "Token (${_fcmToken!.length} chars)" : "NULL"}');
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        Logger.debug('✅ [FCM] ========== TOKEN OBTAINED ==========');
        Logger.debug('✅ [FCM] Token obtained: ${_fcmToken!.substring(0, 20)}...');
        Logger.debug('📱 [FCM] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
        Logger.debug('📱 [FCM] Full token length: ${_fcmToken!.length}');
        
        // Save token locally FIRST (always, even if user not logged in)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        Logger.debug('✅ [FCM] Token saved to local storage');
        
        // Check if user is logged in
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          Logger.debug('✅ [FCM] User is logged in, saving to server...');
        await _sendTokenToServer(_fcmToken!);
        } else {
          Logger.debug('⚠️ [FCM] User not logged in yet, token saved locally');
          Logger.debug('⚠️ [FCM] Token will be synced to server after login');
        }
        
        Logger.debug('✅ [FCM] ===================================');
        
        _ensureTokenRefreshListener();
      } else {
        Logger.debug('❌ [FCM] ========== TOKEN IS NULL OR EMPTY ==========');
        Logger.debug('❌ [FCM] FCM token is null or empty');
        Logger.debug('❌ [FCM] This may indicate:');
        Logger.debug('❌ [FCM] 1. Firebase not properly initialized');
        Logger.debug('❌ [FCM] 2. Notification permissions not granted');
        Logger.debug('❌ [FCM] 3. Network connectivity issues');
        Logger.debug('❌ [FCM] 4. Platform-specific issue (iOS simulator, etc.)');
        
        // Try to get more diagnostic info
        try {
          final settings = await _messaging.getNotificationSettings();
          Logger.debug('❌ [FCM] Current notification settings:');
          Logger.debug('❌ [FCM]   Authorization: ${settings.authorizationStatus}');
          Logger.debug('❌ [FCM]   Alert: ${settings.alert}');
          Logger.debug('❌ [FCM]   Badge: ${settings.badge}');
          Logger.debug('❌ [FCM]   Sound: ${settings.sound}');
          
          if (settings.authorizationStatus == AuthorizationStatus.denied) {
            Logger.debug('❌ [FCM] ACTION REQUIRED: Notification permission is DENIED');
            Logger.debug('❌ [FCM] User must enable notifications in device settings');
          } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
            Logger.debug('❌ [FCM] Permission not yet requested - this should not happen');
          }
        } catch (e) {
          Logger.debug('⚠️ [FCM] Could not get notification settings for diagnosis: $e');
        }
        
        Logger.debug('❌ [FCM] ============================================');
      }
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] ========== TOKEN GET ERROR ==========');
      Logger.debug('❌ [FCM] Error getting token: $e');
      Logger.debug('❌ [FCM] Error type: ${e.runtimeType}');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
      Logger.debug('❌ [FCM] ======================================');
    }
  }

  static void _ensureTokenRefreshListener() {
    if (_tokenRefreshSubscription != null) {
      return;
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isEmpty) {
        Logger.debug('⚠️ [FCM] Token refresh returned empty token');
        return;
      }

      Logger.debug('🔄 [FCM] ========== TOKEN REFRESHED ==========');
      Logger.debug('🔄 [FCM] New token: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);

      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        Logger.debug('🔄 [FCM] User is logged in, saving refreshed token...');
        await _sendTokenToServer(newToken);
      } else {
        Logger.debug('⚠️ [FCM] User not logged in, refreshed token saved locally');
      }
      Logger.debug('🔄 [FCM] =====================================');
    });
  }

  /// Send FCM token to Supabase
  static Future<void> _sendTokenToServer(String token) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      Logger.debug('⚠️ [FCM] No user logged in, skipping token save');
      Logger.debug('⚠️ [FCM] Token will be saved to local storage and synced after login');
      return;
    }
    
    try {
      final platform = _getPlatformTag();
      final trimmedToken = token.trim();

      if (trimmedToken.isEmpty) {
        Logger.debug('⚠️ [FCM] Token is empty after trimming, skipping save');
        return;
      }

      if (platform == 'unknown') {
        Logger.debug('⚠️ [FCM] Platform is unknown, skipping token save');
        return;
      }
      
      Logger.debug('📤 [FCM] ========== SAVING TOKEN ==========');
      Logger.debug('📤 [FCM] User ID: ${user.id}');
      Logger.debug('📤 [FCM] Platform: $platform');
      Logger.debug('📤 [FCM] Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      Logger.debug('📤 [FCM] Token length: ${token.length}');
      
      try {
        await SupabaseService.client
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('platform', platform);
        Logger.debug('✅ [FCM] Existing token deleted for user/platform');
      } catch (deleteError) {
        Logger.debug('⚠️ [FCM] Delete existing token failed (continuing): $deleteError');
      }

      await SupabaseService.client
          .from('user_fcm_tokens')
          .insert({
            'user_id': user.id,
            'fcm_token': trimmedToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
      Logger.debug('✅ [FCM] Insert successful');
      
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
            Logger.debug('✅ [FCM] Token verified in database');
            Logger.debug('✅ [FCM] Saved token matches: ${savedToken.substring(0, 20)}...');
          } else {
            Logger.debug('⚠️ [FCM] Token saved but verification failed - token mismatch');
          }
        } else {
          Logger.debug('⚠️ [FCM] Token not found in database after save - possible RLS issue');
          Logger.debug('⚠️ [FCM] Check RLS policies for user_fcm_tokens table');
        }
      } catch (verifyError) {
        Logger.debug('⚠️ [FCM] Could not verify token save: $verifyError');
      }
      
      Logger.debug('✅ [FCM] Token save process completed');
      Logger.debug('📤 [FCM] ==================================');
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] ========== TOKEN SAVE ERROR ==========');
      Logger.debug('❌ [FCM] Error: $e');
      Logger.debug('❌ [FCM] Error type: ${e.runtimeType}');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('permission denied') || 
          e.toString().contains('RLS') ||
          e.toString().contains('row-level security')) {
        Logger.debug('⚠️ [FCM] RLS policy is blocking the insert/update');
        Logger.debug('⚠️ [FCM] Check Supabase RLS policies for user_fcm_tokens table');
        Logger.debug('⚠️ [FCM] Policy should allow: INSERT/UPDATE WHERE auth.uid() = user_id');
      }
      
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('unique constraint') ||
          e.toString().contains('23505')) {
        Logger.debug('⚠️ [FCM] Duplicate key error - this is expected if token already exists');
        Logger.debug('⚠️ [FCM] Token may already be saved, verification will confirm');
      }
      
      if (e.toString().contains('foreign key') || e.toString().contains('23503')) {
        Logger.debug('⚠️ [FCM] Foreign key constraint error');
        Logger.debug('⚠️ [FCM] User ID may not exist in auth.users table');
      }
      
      Logger.debug('❌ [FCM] ======================================');
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
    
    Logger.debug('📱 [FCM] ========== SETTING UP HANDLERS ==========');
    Logger.debug('📱 [FCM] Previous subscriptions cancelled');
    Logger.debug('📱 [FCM] This should only happen ONCE per app launch');
    
    // ============================================
    // FOREGROUND MESSAGES (App is open)
    // ============================================
    // NOTE: onMessage only fires when app is in FOREGROUND
    // When app is in background/terminated, the background handler processes it
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      Logger.debug('📱 [FCM] ========== FOREGROUND MESSAGE ==========');
      Logger.debug('📱 [FCM] Message ID: ${message.messageId}');
      Logger.debug('📱 [FCM] From: ${message.from}');
      Logger.debug('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
      Logger.debug('📱 [FCM] Data: ${message.data}');
      Logger.debug('📱 [FCM] Sent Time: ${message.sentTime}');
      Logger.debug('📱 [FCM] App State: FOREGROUND');
      
      // FCM automatically shows notifications when notification field is present
      // Only show local notification if this is a data-only message (no notification field)
      // This prevents duplicate notifications
      if (message.notification == null) {
        Logger.debug('📱 [FCM] Data-only message, showing local notification');
      await _showLocalNotification(message);
      } else {
        Logger.debug('📱 [FCM] Notification field present, FCM will show it automatically (skipping local notification to avoid duplicates)');
      }
      
      // Update badge regardless of notification type
      await _updateBadge();
      
      Logger.debug('📱 [FCM] ======================================');
    });
    
    // ============================================
    // BACKGROUND MESSAGES (App is minimized)
    // ============================================
    _backgroundSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.debug('📱 [FCM] ========== APP OPENED FROM BACKGROUND ==========');
      Logger.debug('📱 [FCM] Message ID: ${message.messageId}');
      Logger.debug('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
      Logger.debug('📱 [FCM] Data: ${message.data}');
      Logger.debug('📱 [FCM] ================================================');
      
      // Handle navigation based on data
      _handleNotificationNavigation(message);
    });
    
    // ============================================
    // TERMINATED STATE (App was closed)
    // ============================================
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Logger.debug('📱 [FCM] ========== APP OPENED FROM TERMINATED ==========');
        Logger.debug('📱 [FCM] Message ID: ${message.messageId}');
        Logger.debug('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
        Logger.debug('📱 [FCM] Data: ${message.data}');
        Logger.debug('📱 [FCM] ================================================');
        
        // Handle navigation based on data
        _handleNotificationNavigation(message);
      }
    });
    
    Logger.debug('✅ [FCM] Message handlers set up successfully');
    Logger.debug('📱 [FCM] =========================================');
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
        Logger.debug('⚠️ [FCM] No title/body found in payload - skipping local notification');
        return;
      }
      
      Logger.debug('📱 [FCM] Showing local notification: $title - $body');
      Logger.debug('📱 [FCM] Local notification shown while app is foreground');
      
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
        Logger.debug('⚠️ [FCM] Duplicate notification detected, skipping (shown ${(now - lastShown) / 1000}s ago)');
        return;
      }
      
      // Mark as shown
      await prefs.setInt(notificationKey, now);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );
      
      Logger.debug('✅ [FCM] Local notification displayed successfully');
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] Error showing local notification: $e');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Handle notification tap navigation (local notifications - e.g. foreground)
  static void _onNotificationTapped(NotificationResponse response) {
    Logger.debug('📱 [FCM] ========== NOTIFICATION TAPPED ==========');
    Logger.debug('📱 [FCM] Notification ID: ${response.id}');
    Logger.debug('📱 [FCM] Action ID: ${response.actionId}');
    Logger.debug('📱 [FCM] Payload: ${response.payload}');
    Logger.debug('📱 [FCM] =========================================');
    
    // Parse payload and navigate by type (same as _handleNotificationNavigation)
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        final type = decoded is Map ? decoded['type']?.toString() : null;
        if (type != null && type.isNotEmpty) {
          _navigateByType(type);
          return;
        }
      } catch (_) {}
    }
    _navigateToNotificationCenter();
  }

  /// Navigate to the appropriate screen based on notification type.
  /// Fetches the user role from DB if not available in metadata.
  static void _navigateByType(String? type) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = globalNavigatorKey.currentState;
      if (navigator == null) {
        _navigateToNotificationCenter();
        return;
      }
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;

      // Try metadata first, fall back to DB query for reliability
      String? userRole = currentUser.userMetadata?['role'] as String?;
      if (userRole == null) {
        try {
          final record = await SupabaseService.client
              .from('users')
              .select('role')
              .eq('id', currentUser.id)
              .maybeSingle();
          userRole = record?['role'] as String?;
        } catch (e) {
          Logger.debug('⚠️ [FCM] Could not fetch user role from DB: $e');
        }
      }

      Logger.debug('📱 [FCM] Navigating by type: $type, role: $userRole');

      if (userRole == 'admin') {
        Widget? targetScreen;
        switch (type) {
          case 'access_request':
            targetScreen = const AdminApprovalScreen();
            break;
          case 'tool_request':
            targetScreen = const ApprovalWorkflowsScreen();
            break;
          case 'maintenance_request':
            targetScreen = const MaintenanceScreen();
            break;
          case 'issue_report':
            targetScreen = const ToolIssuesScreen();
            break;
        }
        if (targetScreen != null) {
          navigator.push(MaterialPageRoute(builder: (_) => targetScreen!));
          Logger.debug('✅ [FCM] Admin navigated to specific screen for type: $type');
          return;
        }
        // Admin types without a specific screen → notification center
        _navigateToNotificationCenter();
        return;
      }

      if (userRole == 'technician') {
        if (type == 'user_approved') {
          // Newly approved — just open home, no notification needed
          navigator.pushNamedAndRemoveUntil('/technician', (route) => false);
          Logger.debug('✅ [FCM] Technician navigated to home (user_approved)');
        } else {
          // All other types → open notification center so they can act on it
          TechnicianHomeScreen.openNotificationsOnLoad = true;
          navigator.pushNamedAndRemoveUntil('/technician', (route) => false);
          Logger.debug('✅ [FCM] Technician: set openNotificationsOnLoad for type: $type');
        }
        return;
      }

      _navigateToNotificationCenter();
    });
  }

  /// Handle navigation when app is opened from notification (FCM - background/terminated)
  static void _handleNotificationNavigation(RemoteMessage message) {
    final type = message.data['type'] as String?;
    Logger.debug('📱 [FCM] Navigation - Type: $type, Data: ${message.data}');
    _navigateByType(type);
  }
  
  /// Navigate to the appropriate notification center based on user role.
  /// Admin → pushes AdminNotificationScreen directly.
  /// Technician → navigates to home and auto-opens the notification bottom sheet.
  static void _navigateToNotificationCenter() {
    Logger.debug('📱 [FCM] Navigating to notification center...');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = globalNavigatorKey.currentState;
      if (navigator == null) {
        Logger.debug('⚠️ [FCM] Navigator not available, cannot navigate');
        return;
      }

      try {
        final currentUser = SupabaseService.client.auth.currentUser;
        if (currentUser == null) {
          Logger.debug('⚠️ [FCM] No user logged in, cannot navigate to notifications');
          return;
        }

        // Try metadata first, fall back to DB
        String? userRole = currentUser.userMetadata?['role'] as String?;
        if (userRole == null) {
          try {
            final record = await SupabaseService.client
                .from('users')
                .select('role')
                .eq('id', currentUser.id)
                .maybeSingle();
            userRole = record?['role'] as String?;
          } catch (e) {
            Logger.debug('⚠️ [FCM] Could not fetch role for notification center nav: $e');
          }
        }
        Logger.debug('📱 [FCM] User role: $userRole');

        if (userRole == 'admin') {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const AdminNotificationScreen(),
            ),
          );
          Logger.debug('✅ [FCM] Navigated to Admin Notification Center');
        } else if (userRole == 'technician') {
          // Set flag so TechnicianHomeScreen auto-opens the notification sheet
          TechnicianHomeScreen.openNotificationsOnLoad = true;
          navigator.pushNamedAndRemoveUntil('/technician', (route) => false);
          Logger.debug('✅ [FCM] Navigated to Technician Home → notification center will auto-open');
        } else {
          Logger.debug('⚠️ [FCM] Unknown user role: $userRole');
        }
      } catch (e) {
        Logger.debug('❌ [FCM] Error navigating to notification center: $e');
      }
    });
  }

  /// Update app badge — increment immediately then sync with DB after a short delay.
  /// Increment-first avoids the race condition where the new notification row
  /// isn't committed yet when we query the DB.
  static Future<void> _updateBadge() async {
    try {
      await BadgeService.incrementBadge();
      final badgeCount = await BadgeService.getBadgeCount();
      Logger.debug('✅ [FCM] Badge incremented to: $badgeCount');
      // Delayed sync to correct the count once the DB row is committed
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await BadgeService.syncBadgeWithDatabase(null);
        } catch (_) {}
      });
    } catch (e) {
      Logger.debug('❌ [FCM] Error updating badge: $e');
    }
  }

  /// Clear badge
  static Future<void> clearBadge() async {
    try {
      await BadgeService.clearBadge();
      Logger.debug('✅ [FCM] Badge cleared');
    } catch (e) {
      Logger.debug('❌ [FCM] Error clearing badge: $e');
    }
  }

  /// Subscribe to FCM topics
  static Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('admin');
      await _messaging.subscribeToTopic('new_registration');
      await _messaging.subscribeToTopic('tool_issues');
      Logger.debug('✅ [FCM] Subscribed to topics');
    } catch (e) {
      Logger.debug('❌ [FCM] Error subscribing to topics: $e');
    }
  }

  /// Send token to server (public method for manual refresh)
  static Future<void> sendTokenToServer(String token, String userId) async {
    try {
      final platform = _getPlatformTag();
      final trimmedToken = token.trim();

      if (trimmedToken.isEmpty) {
        Logger.debug('⚠️ [FCM] Token is empty after trimming, skipping save');
        return;
      }

      if (platform == 'unknown') {
        Logger.debug('⚠️ [FCM] Platform is unknown, skipping token save');
        return;
      }
      
      Logger.debug('📤 [FCM] Sending token to server for user: $userId, platform: $platform');
      
      try {
        await SupabaseService.client
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('platform', platform);
        Logger.debug('✅ [FCM] Existing token deleted for user/platform');
      } catch (deleteError) {
        Logger.debug('⚠️ [FCM] Delete existing token failed (continuing): $deleteError');
      }

      await SupabaseService.client
          .from('user_fcm_tokens')
          .insert({
            'user_id': userId,
            'fcm_token': trimmedToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      Logger.debug('✅ [FCM] Token sent to server successfully');
    } catch (e, stackTrace) {
      Logger.debug('❌ [FCM] Error sending token: $e');
      Logger.debug('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Save token from local storage to server (for when user logs in after token was generated)
  static Future<void> saveTokenFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      
      if (savedToken == null || savedToken.isEmpty) {
        Logger.debug('⚠️ [FCM] No token found in local storage');
        return;
      }
      
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        Logger.debug('⚠️ [FCM] No user logged in, cannot save token from local storage');
        return;
      }
      
      Logger.debug('📤 [FCM] Saving token from local storage for user: ${user.id}');
      await sendTokenToServer(savedToken, user.id);
    } catch (e) {
      Logger.debug('❌ [FCM] Error saving token from local storage: $e');
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
  Logger.debug('📱 [FCM] ========== BACKGROUND/TERMINATED MESSAGE ==========');
  Logger.debug('📱 [FCM] Message ID: ${message.messageId}');
  Logger.debug('📱 [FCM] From: ${message.from}');
  Logger.debug('📱 [FCM] Notification: ${message.notification?.title} - ${message.notification?.body}');
  Logger.debug('📱 [FCM] Data: ${message.data}');
  Logger.debug('📱 [FCM] Sent Time: ${message.sentTime}');
  Logger.debug('📱 [FCM] App State: BACKGROUND/TERMINATED');
  
  // Initialize Firebase if not already initialized (background handlers run in separate isolate)
  // Wrapped in try-catch to handle concurrent background messages both trying to initialize
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.debug('✅ [FCM] Firebase initialized in background handler');
    }
  } catch (e) {
    // Another handler may have initialized concurrently — safe to continue
    if (Firebase.apps.isNotEmpty) {
      Logger.debug('⚠️ [FCM] Firebase already initialized by concurrent handler');
    } else {
      Logger.debug('❌ [FCM] Firebase initialization failed: $e');
      return;
    }
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
    
    // Increment badge immediately (guaranteed correct), then try to sync with DB
    // Do NOT sync-first: the new notification row may not be committed yet (race condition)
    await BadgeService.incrementBadge();
    final badgeCount = await BadgeService.getBadgeCount();
    // Best-effort DB sync after a short delay to let the row commit
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await BadgeService.syncBadgeWithDatabase(null);
      } catch (_) {}
    });
    
    // CRITICAL RULE: Check if message has notification payload
    if (message.notification != null) {
      // Message has notification payload → OS shows it automatically
      // DO NOT show local notification (would cause duplicate)
      Logger.debug('📱 [FCM] Message has notification payload → OS handles display');
      Logger.debug('📱 [FCM] System will show notification automatically');
      Logger.debug('📱 [FCM] NOT showing local notification (prevents duplicate)');
      Logger.debug('📱 [FCM] Only updating badge: $badgeCount');
    } else if (message.data.isNotEmpty) {
      // Data-only message → We must show local notification
      Logger.debug('📱 [FCM] Data-only message → Showing local notification');
      
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
        
        Logger.debug('✅ [FCM] Background notification displayed with badge: $badgeCount');
      } else {
        Logger.debug('⚠️ [FCM] No title/body found in data payload - skipping local notification');
      }
    } else {
      Logger.debug('⚠️ [FCM] Message has no notification payload and no data - skipping');
    }
    
    Logger.debug('📱 [FCM] ====================================================');
  } catch (e, stackTrace) {
    Logger.debug('❌ [FCM] Error handling background message: $e');
    Logger.debug('❌ [FCM] Stack trace: $stackTrace');
  }
}
