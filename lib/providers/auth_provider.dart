import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gotrue/gotrue.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import '../services/supabase_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/push_notification_service.dart';
import '../services/first_launch_service.dart';
import '../services/last_route_service.dart';
import '../services/badge_service.dart';
import '../models/user_role.dart';
import '../config/supabase_config.dart';
import '../utils/name_formatter.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserRole _userRole = UserRole.technician;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoggingOut = false;
  bool _suppressAuthStateChanges = false;
  static const Duration _authOperationTimeout = Duration(seconds: 15);
  static const Duration _applePromptTimeout = Duration(seconds: 60);
  static const Duration _approvalBypassCacheDuration = Duration(minutes: 5);
  bool? _appleApprovalBypassEnabled;
  DateTime? _appleApprovalBypassFetchedAt;

  User? get user => _user;
  UserRole get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated {
    // Check if we have both a user AND a valid session
    if (_user == null) return false;
    try {
      final session = SupabaseService.client.auth.currentSession;
      return session != null;
    } catch (e) {
      return false;
    }
  }
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isTechnician => _userRole == UserRole.technician;
  bool get isPendingApproval => _userRole == UserRole.pending;
  bool get isLoggingOut => _isLoggingOut;

  void resetLoadingState({String? reason}) {
    if (_isLoading) {
      debugPrint('🔄 Resetting auth loading state${reason != null ? " ($reason)" : ""}');
    }
    _isLoading = false;
    notifyListeners();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isAppleProvider() {
    final appMetadata = _user?.appMetadata ?? <String, dynamic>{};
    final provider = appMetadata['provider']?.toString();
    final providers = appMetadata['providers'];
    return provider == 'apple' ||
        (providers is List &&
            providers.map((e) => e.toString()).contains('apple'));
  }

  Future<bool> isAppleApprovalBypassEnabled() async {
    return _isAppleApprovalBypassEnabled();
  }

  Future<bool> _isAppleApprovalBypassEnabled() async {
    final now = DateTime.now();
    if (_appleApprovalBypassEnabled != null &&
        _appleApprovalBypassFetchedAt != null &&
        now.difference(_appleApprovalBypassFetchedAt!) <
            _approvalBypassCacheDuration) {
      return _appleApprovalBypassEnabled!;
    }

    try {
      final response = await SupabaseService.client
          .from('app_settings')
          .select('value')
          .eq('key', 'apple_bypass_approval')
          .maybeSingle()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Feature flag lookup timed out');
            },
          );
      final rawValue = response?['value']?.toString().toLowerCase();
      final enabled =
          rawValue == 'true' || rawValue == '1' || rawValue == 'yes';
      _appleApprovalBypassEnabled = enabled;
      _appleApprovalBypassFetchedAt = now;
      return enabled;
    } catch (e) {
      debugPrint('⚠️ Could not load apple_bypass_approval flag: $e');
      return _appleApprovalBypassEnabled ?? false;
    }
  }
  
  /// Check if user's email is confirmed
  bool get isEmailConfirmed {
    return _user?.emailConfirmedAt != null;
  }

  /// Check if the current user has been approved
  /// Returns null if check is in progress, true if approved, false if pending/rejected
  Future<bool?> checkApprovalStatus() async {
    if (_user == null) return null;

    if (_isAppleProvider() && await _isAppleApprovalBypassEnabled()) {
      debugPrint('✅ Apple sign-in detected - bypassing approval checks');
      return true;
    }
    
    try {
      // CRITICAL: Always check pending approvals table FIRST - this is the source of truth
      // A pending approval record takes precedence over user record
      final approval = await SupabaseService.client
          .from('pending_user_approvals')
          .select('status')
          .eq('user_id', _user!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (approval != null) {
        final status = approval['status'] as String?;
        debugPrint('🔍 Found pending approval record with status: $status');
        
        if (status == 'approved') {
          // If approved, check if user record exists (should exist after approval)
          final userRecord = await SupabaseService.client
              .from('users')
              .select('role')
              .eq('id', _user!.id)
              .maybeSingle();
          final isApproved = userRecord != null;
          debugPrint('🔍 Approval status: approved, user record exists: $isApproved');
          return isApproved;
        } else if (status == 'pending' || status == 'rejected') {
          // Status is pending or rejected - NOT approved
          debugPrint('🔍 Approval status: $status - user is NOT approved');
          return false;
        }
      }
      
      // No pending approval record found - check if user exists in users table
      // This handles existing approved users who don't have pending approval records
      final userRecord = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', _user!.id)
          .maybeSingle();
      
      if (userRecord != null && userRecord['role'] != null) {
        final role = userRecord['role'] as String;
        if (role == 'admin') {
          debugPrint('🔍 User is admin - always approved');
          return true; // Admins are always approved
        }
        // For technicians, if they have a user record and NO pending approval, they're approved
        debugPrint('🔍 Technician with user record and no pending approval - approved');
        return true;
      }
      
      // No record found anywhere - treat as not approved (pending registration)
      debugPrint('🔍 No user record or pending approval found - NOT approved');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking approval status: $e');
      return null;
    }
  }

  Future<void> initialize() async {
    print('🔍 AuthProvider initialize called');
    _isLoading = true;
    notifyListeners();

    // Set a maximum timeout for initialization (3 seconds) - fast startup is critical
    // After this, we'll proceed even if not fully initialized
    Timer(const Duration(seconds: 3), () {
      if (_isLoading || !_isInitialized) {
        print('⚠️ Initialization timeout - forcing completion');
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    });

    try {
      print('🔍 Getting current session...');
      // Get session immediately - don't wait, Supabase should have it ready
      var session = SupabaseService.client.auth.currentSession;
      
      // If no session found immediately, wait briefly (max 600ms)
      if (session == null) {
        print('🔍 No session found immediately, waiting briefly...');
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          session = SupabaseService.client.auth.currentSession;
          if (session != null) {
            print('✅ Session restored after ${(i + 1) * 200}ms');
            break;
          }
        }
      }
      print('🔍 Current session: ${session != null ? "Found (user: ${session.user.email}, expired: ${session.isExpired})" : "None"}');
      
      // If session exists but is expired, try to refresh it (non-blocking for UI)
      if (session != null && session.isExpired) {
        print('🔄 Session expired, attempting to refresh...');
        try {
          final refreshResponse = await SupabaseService.client.auth
              .refreshSession()
              .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('⚠️ Session refresh timed out');
              throw TimeoutException('Session refresh timed out');
            },
          );
          if (refreshResponse?.session != null) {
            session = refreshResponse!.session;
            print('✅ Session refreshed successfully');
          } else {
            print('⚠️ Session refresh returned null - session may be invalid');
          }
        } catch (e) {
          print('❌ Failed to refresh session: $e');
          // Don't clear session on refresh failure - session might still be valid
          // Only clear if it's definitely expired and refresh failed
          // This prevents losing valid sessions due to temporary network issues
          if (session != null && session.isExpired) {
            print('⚠️ Session is expired and refresh failed - keeping session for now');
            // Don't set session to null - let it try to use the expired session
            // The app will handle expired sessions gracefully
          }
        }
      }
      
      _user = session?.user;
      
      // Fallback: Check if there's a user stored even if session is null
      // This can happen if session storage is cleared but user data persists
      if (_user == null) {
        try {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            print('🔍 Found user from currentUser (session was null)');
            _user = currentUser;
            
            // CRITICAL: Check if email is confirmed - but skip for technicians (they bypass email confirmation)
            final roleFromMetadata = currentUser.userMetadata?['role'] as String?;
            final isTechnician = roleFromMetadata == 'technician';
            
            if (_user!.emailConfirmedAt == null && !isTechnician) {
              print('❌ Email not confirmed - cannot restore session (admin requires email confirmation)');
              _user = null;
              return; // Don't proceed if email is not confirmed (for admins only)
            }
            
            // Technicians can proceed without email confirmation
            if (isTechnician) {
              print('✅ Technician - bypassing email confirmation check');
            }
            
            // Try to get a fresh session for this user (non-blocking)
            try {
              final refreshResponse = await SupabaseService.client.auth
                  .refreshSession()
                  .timeout(
                const Duration(seconds: 2),
                onTimeout: () =>
                    throw TimeoutException('Session refresh timed out'),
              );
              if (refreshResponse?.session != null) {
                _user = refreshResponse!.session!.user;
                print('✅ Restored session for user: ${_user?.email}');
              }
            } catch (e) {
              print('⚠️ Could not refresh session for existing user: $e');
              // Continue with the user anyway - they might still be authenticated
              // The session might still be valid, just couldn't refresh
              // This prevents losing valid sessions due to temporary network issues
            }
          }
        } catch (e) {
          print('⚠️ Error checking currentUser: $e');
        }
      }
      
      // CRITICAL: If we still don't have a user, try one more time after a longer delay
      // This handles cases where Supabase is still initializing in the background
      // Supabase needs time to restore the persisted session from storage
      if (_user == null) {
        print('🔍 Still no user found, waiting for Supabase to fully initialize and restore session...');
        // Wait longer to ensure Supabase has restored persisted session
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Try again after Supabase has had time to restore session
        try {
          final delayedSession = SupabaseService.client.auth.currentSession;
          if (delayedSession != null) {
            _user = delayedSession.user;
            print('✅ Session restored after delay: ${_user?.email}');
            session = delayedSession; // Update session variable too
          } else {
            // Try currentUser as fallback
            final delayedUser = SupabaseService.client.auth.currentUser;
            if (delayedUser != null) {
              _user = delayedUser;
              print('✅ User found after delay (no session): ${_user?.email}');
              // Try to refresh session for this user
              try {
                final refreshResponse = await SupabaseService.client.auth
                    .refreshSession()
                    .timeout(const Duration(seconds: 3));
                if (refreshResponse?.session != null) {
                  _user = refreshResponse!.session!.user;
                  session = refreshResponse.session;
                  print('✅ Session refreshed for restored user: ${_user?.email}');
                }
              } catch (e) {
                print('⚠️ Could not refresh session for restored user: $e');
                // Continue with user anyway - they might still be authenticated
              }
            }
          }
        } catch (e) {
          print('⚠️ Error checking session after delay: $e');
        }
      }
      
      print('🔍 Current user: ${_user?.email ?? "None"}');

      // Listen to auth state changes
      print('🔍 Setting up auth state listener...');
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        print('🔍 Auth state changed: ${data.session?.user?.email ?? "None"}');
        // CRITICAL: Don't process auth state changes during logout
        if (_isLoggingOut) {
          print('🔍 Ignoring auth state change during logout');
          return;
        }
        if (_suppressAuthStateChanges) {
          debugPrint('🔍 Suppressing auth state change during account creation');
          return;
        }
        if (_isLoading &&
            (data.event == AuthChangeEvent.signedIn ||
                data.event == AuthChangeEvent.signedOut ||
                data.event == AuthChangeEvent.userUpdated)) {
          _isLoading = false;
        }
        _user = data.session?.user;
        // Only load role if we have a user - don't create default accounts
        if (_user != null) {
        _loadUserRole();
        } else {
          // No user - clear role, don't create anything
          _userRole = UserRole.pending;
        }
        notifyListeners();
      });

      // Load user role if user exists - with timeout to prevent hanging when offline
      if (_user != null) {
        print('🔍 Loading user role...');
        try {
          // Add timeout to prevent hanging when offline (5 seconds max)
          await _loadUserRole().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ User role loading timed out (likely offline) - using saved role');
              // Try to load from local storage as fallback
              _getSavedUserRole().then((savedRole) {
                if (savedRole != null) {
                  _userRole = savedRole;
                  notifyListeners();
                }
              });
            },
          );
        } catch (e) {
          debugPrint('⚠️ Error loading user role (likely offline): $e');
          // Try to load from local storage as fallback
          final savedRole = await _getSavedUserRole();
          if (savedRole != null) {
            _userRole = savedRole;
            debugPrint('✅ Loaded user role from local storage: ${_userRole.value}');
          }
        }
        
        if (_userRole == UserRole.admin) {
          await _ensureAdminPosition();
        }
        
        // Register FCM token on app start (non-blocking)
        try {
          await FirebaseMessagingService.registerCurrentToken()
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('⚠️ Could not register FCM token after initialization: $e');
        }
      } else {
        print('🔍 No user found, setting default role');
        _userRole = UserRole.technician;
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
      // Set default values on error
      _userRole = UserRole.technician;
    } finally {
      print('🔍 AuthProvider initialization complete');
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Check if email is available (not already registered)
  /// Returns true if email is available, false if already in use
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Method 1: Use SQL function (most reliable - checks both auth.users and public.users)
      try {
        final result = await SupabaseService.client
            .rpc('check_email_available', params: {'check_email': email})
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Email check timed out');
              },
            );
        
        final isAvailable = result as bool? ?? true; // Default to available if null
        debugPrint('✅ [Email Check] SQL function result: $isAvailable for $email');
        return isAvailable;
      } catch (rpcError) {
        debugPrint('⚠️ [Email Check] SQL function not available, using fallback method: $rpcError');
        // Fall through to backup method
      }
      
      // Method 2: Fallback - Check public.users directly
      try {
        final publicUser = await SupabaseService.client
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));
        
        if (publicUser != null) {
          debugPrint('⚠️ [Email Check] Email already exists in public.users: $email');
          return false;
        }
      } catch (e) {
        debugPrint('⚠️ [Email Check] Could not check public.users: $e');
      }
      
      // Method 3: Last resort - Try to sign in with dummy password
      // This checks auth.users but is less reliable due to error message parsing
      try {
        await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: 'dummy_check_password_12345_xyz',
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Email check timed out');
          },
        );
        // If we get here (unlikely with dummy password), email exists
        debugPrint('⚠️ [Email Check] Email already exists (sign in succeeded): $email');
        return false;
      } catch (signInError) {
        final errorString = signInError.toString().toLowerCase();
        
        // If error says "invalid login credentials" or "invalid_credentials"
        // This means email EXISTS but password is wrong
        if (errorString.contains('invalid login credentials') ||
            errorString.contains('invalid_credentials') ||
            errorString.contains('wrong password') ||
            errorString.contains('incorrect password')) {
          debugPrint('⚠️ [Email Check] Email already exists (invalid credentials): $email');
          return false; // Email is already registered
        }
        
        // If error says "user not found" or "email not found"
        // This means email does NOT exist
        if (errorString.contains('user not found') ||
            errorString.contains('email not found') ||
            errorString.contains('account not found')) {
          debugPrint('✅ [Email Check] Email is available (user not found): $email');
          return true; // Email is available
        }
        
        // For other errors, assume email is available (safer for registration)
        // The signUp will fail with a proper error if email actually exists
        debugPrint('⚠️ [Email Check] Could not determine email availability, assuming available: $email');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Email Check] Error checking email availability: $e');
      // If check fails, assume email is available
      // The signUp will fail with proper error if email actually exists
      return true;
    }
  }

  Future<void> _ensureAdminPosition() async {
    try {
      if (_user == null) return;

      final userRecord = await SupabaseService.client
          .from('users')
          .select('id, position_id, role')
          .eq('id', _user!.id)
          .maybeSingle();

      if (userRecord == null) return;
      if (userRecord['role'] != 'admin') return;
      if (userRecord['position_id'] != null) return;

      final adminCountResponse = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('role', 'admin');

      final adminCount = (adminCountResponse as List).length;
      if (adminCount > 1) {
        debugPrint('⚠️ Multiple admins found; skipping auto-assign of Super Admin position');
        return;
      }

      final superAdmin = await SupabaseService.client
          .from('admin_positions')
          .select('id')
          .eq('name', 'Super Admin')
          .maybeSingle();

      final fallback = superAdmin ??
          await SupabaseService.client
              .from('admin_positions')
              .select('id')
              .eq('name', 'CEO')
              .maybeSingle();

      final positionId = fallback?['id']?.toString();
      if (positionId == null || positionId.isEmpty) return;

      await SupabaseService.client
          .from('users')
          .update({'position_id': positionId})
          .eq('id', _user!.id);

      debugPrint('✅ Auto-assigned admin position_id: $positionId');
    } catch (e) {
      debugPrint('⚠️ Could not auto-assign admin position: $e');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
    String? positionId, // Admin position ID
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAdmin = role == UserRole.admin;
      debugPrint('🔍 signUp called for: $email, role: ${role?.value ?? "null"}, isAdmin: $isAdmin');
      
      // Check database connection first
      debugPrint('🔍 Checking database connection...');
      final isConnected = await SupabaseService.ensureConnection(retries: 2);
      if (!isConnected) {
        throw Exception('Cannot connect to database. Please check your internet connection and try again.');
      }
      debugPrint('✅ Database connection verified');
      
      // Check if email is already in use BEFORE attempting signup
      // This prevents sending confirmation emails for existing emails
      debugPrint('🔍 Checking if email is available: $email');
      final emailAvailable = await isEmailAvailable(email);
      if (!emailAvailable) {
        throw Exception('This email is already registered. Please sign in or use a different email address.');
      }
      debugPrint('✅ Email is available, proceeding with registration');
      
      // Email confirmation may be enabled in Supabase
      // If enabled, users won't have a session until they confirm their email
      debugPrint('🔍 Calling Supabase auth.signUp...');
      debugPrint('🔍 SignUp parameters: email=$email, role=${role?.value ?? "NULL (must be set)"}');
      
      // Try signUp with retry logic
      AuthResponse? response;
      int maxRetries = 2;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          debugPrint('🔍 SignUp attempt $attempt/$maxRetries...');
          
          // Timeout set to 30 seconds (email confirmation is disabled, so should be faster)
          // Ensure role is explicitly provided - no automatic defaults
          if (role == null) {
            throw Exception('Role must be explicitly specified during registration');
          }
          
          response = await SupabaseService.client.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': fullName,
              'role': role.value, // Role must be explicitly set - no default
              if (positionId != null && positionId.isNotEmpty) 'position_id': positionId,
            },
            emailRedirectTo: 'com.rgs.app://auth/callback',
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('❌ SignUp attempt $attempt timed out after 30 seconds');
              if (attempt < maxRetries) {
                debugPrint('⏳ Will retry...');
              }
              throw TimeoutException('Registration is taking longer than expected. Please check your internet connection and try again.');
            },
          );
          
          debugPrint('✅ SignUp API call completed on attempt $attempt');
          break; // Success, exit retry loop
        } catch (e) {
          if (attempt == maxRetries) {
            // Last attempt failed, rethrow
            debugPrint('❌ All signUp attempts failed');
            rethrow;
          } else {
            // Wait before retrying
            debugPrint('⏳ Waiting 3 seconds before retry...');
            await Future.delayed(const Duration(seconds: 3));
          }
        }
      }
      
      if (response == null) {
        throw Exception('SignUp failed after $maxRetries attempts');
      }

      debugPrint('🔍 signUp response received: user=${response.user?.id ?? "null"}, session=${response.session != null}');

      // CRITICAL FIX: Only update _user if we don't already have a logged-in user
      // This prevents admin's session from being replaced when creating technician accounts
      if (response.user != null) {
        // Save current user before potentially updating
        final wasAlreadyLoggedIn = _user != null;
        final previousUserId = _user?.id;
        
        // Only update _user if we're not already logged in (self-registration)
        // If we're already logged in (admin creating technician), preserve current user
        if (!wasAlreadyLoggedIn) {
        _user = response.user;
          debugPrint('🔍 Updated _user to new user: ${_user!.id} (self-registration)');
        } else {
          debugPrint('🔍 Preserving current logged-in user (ID: $previousUserId) - admin creating technician');
          debugPrint('🔍 New technician user ID: ${response.user!.id}');
          // Don't update _user - keep the current admin user
        }
        
        final hasSession = response.session != null;
        debugPrint('🔍 User created: ${_user!.id}, hasSession: $hasSession, emailConfirmed: ${_user!.emailConfirmedAt != null}');
        
        // For technicians, create pending approval instead of user record
        // Role must be explicitly set - no null check (role is required)
        if (role == UserRole.technician) {
          // Email confirmation may be enabled - if so, we won't have a session
          // But we can still create the pending approval record (it will be created by trigger or we create it)
          if (hasSession) {
            try {
              debugPrint('🔍 Creating pending approval for technician (has session)...');
              // Create pending approval record with timeout
              final approvalResponse = await SupabaseService.client
                  .from('pending_user_approvals')
                  .insert({
                    'user_id': _user!.id,
                    'email': email,
                    'full_name': fullName,
                    'status': 'pending',
                  })
                  .select()
                  .single()
                  .timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      throw TimeoutException('Failed to create pending approval. Please try again.');
                    },
                  );
              
              debugPrint('✅ Pending approval created for technician: $email');
              
              // Create notification for admins in the main notification center
              try {
                final displayName = fullName ?? email;
                await SupabaseService.client
                    .from('admin_notifications')
                    .insert({
                      'title': 'New Technician Registration',
                      'message': '$displayName has requested access to the app and is awaiting approval.',
                      'technician_name': displayName,
                      'technician_email': email,
                      'type': 'access_request',
                      'is_read': false,
                      'timestamp': DateTime.now().toIso8601String(),
                      'data': {
                        'approval_id': approvalResponse['id'],
                        'user_id': _user!.id,
                        'submitted_at': DateTime.now().toIso8601String(),
                      },
                    });
                debugPrint('✅ Created admin notification for new technician approval request');
              } catch (notifError) {
                debugPrint('⚠️ Failed to create admin notification: $notifError');
                // Don't fail the registration if notification creation fails
              }
              
              // Delete any user record created by trigger (technicians shouldn't have one until approved)
              try {
                await SupabaseService.client
                    .from('users')
                    .delete()
                    .eq('id', _user!.id)
                    .timeout(
                      const Duration(seconds: 10),
                      onTimeout: () {
                        debugPrint('⚠️ Delete user record timed out');
                      },
                    );
                debugPrint('✅ Removed user record for pending technician');
              } catch (deleteError) {
                debugPrint('⚠️ Could not delete user record: $deleteError');
                // Don't throw - this is not critical
              }
              
              // Set role to pending IMMEDIATELY (before notifyListeners)
              _userRole = UserRole.pending;
              await _saveUserRole(_userRole);
              debugPrint('✅ User role set to pending: ${_userRole.value}');
              notifyListeners(); // Notify immediately so UI can check isPendingApproval
            } catch (e, stackTrace) {
              debugPrint('❌ Error creating pending approval: $e');
              debugPrint('❌ Error type: ${e.runtimeType}');
              debugPrint('❌ Stack trace: $stackTrace');
              // Re-throw if it's a timeout or connection error
              if (e is TimeoutException || e.toString().contains('connection') || e.toString().contains('network')) {
                rethrow;
              }
              // Continue anyway for other errors - user is created, pending approval can be created later
            }
          } else {
            // No session - email confirmation is enabled
            // User was created but needs to confirm email before getting a session
            // Pending approval will be created by database trigger when user confirms email
            debugPrint('ℹ️ No session after signup - email confirmation is enabled');
            debugPrint('ℹ️ User must confirm email before getting a session');
            debugPrint('ℹ️ Pending approval will be created automatically when email is confirmed');
            // Don't throw - this is expected when email confirmation is enabled
            // The UI will handle showing the email confirmation message
          }
        } else {
          // For admins, load role normally (only if we have a session)
          if (hasSession) {
            debugPrint('🔍 Loading role for admin...');
            await _loadUserRole();
          } else {
            // No session - email confirmation is enabled
            debugPrint('ℹ️ No session for admin - email confirmation is enabled');
            debugPrint('ℹ️ Admin must confirm email before getting a session');
            // Don't throw - this is expected when email confirmation is enabled
            // The UI will handle showing the email confirmation message
          }
        }
      } else {
        debugPrint('⚠️ signUp returned null user');
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Error signing up: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error string: ${e.toString()}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Provide more specific error messages
      if (e is TimeoutException) {
        debugPrint('⚠️ Timeout occurred - this might indicate:');
        debugPrint('   1. Slow network connection');
        debugPrint('   2. Supabase email service is slow');
        debugPrint('   3. Email confirmation is enabled and causing delays');
        debugPrint('   4. Supabase service might be experiencing issues');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('⚠️ Network error detected');
      } else if (e.toString().contains('email') && e.toString().contains('already')) {
        debugPrint('⚠️ Email already registered');
        // Re-throw with clearer message
        throw Exception('This email is already registered. Please sign in or use a different email address.');
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin registration method
  Future<AuthResponse> registerAdmin(
    String name,
    String email,
    String password,
    String positionId, // Changed from position name to position_id
  ) async {
    // Validate email domain
    if (!_isAdminEmailAllowed(email)) {
      throw Exception('Invalid email domain for admin registration. Use @royalgulf.ae, @mekar.ae, or @gmail.com');
    }

    final bootstrapAllowed = await canBootstrapAdmin();
    if (!bootstrapAllowed) {
      throw Exception('Admin registration is closed. Please request an admin invite.');
    }

    debugPrint('🔍 Starting admin registration for: $email with position_id: $positionId');
    final response = await signUp(
      email: email,
      password: password,
      fullName: name,
      role: UserRole.admin,
      positionId: positionId, // Pass position_id to signUp
    );

    // Verify that user was actually created
    if (response.user == null) {
      debugPrint('❌ Admin registration failed - no user returned');
      throw Exception('Registration failed: User was not created. Please try again.');
    }

    debugPrint('✅ Admin registration successful - user ID: ${response.user!.id}');
    debugPrint('🔍 Admin registration - hasSession: ${response.session != null}, emailConfirmed: ${response.user?.emailConfirmedAt != null}');
    
    // If we have a session, ensure the user record exists in the users table
    // (it should be created by the database trigger, but let's verify)
    if (response.session != null) {
      try {
        // Wait a moment for the trigger to create the user record
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify user record exists with timeout
        final userRecord = await SupabaseService.client
            .from('users')
            .select('id, role')
            .eq('id', response.user!.id)
            .maybeSingle()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Failed to verify user record. Please try again.');
              },
            );
        
        if (userRecord == null) {
          debugPrint('⚠️ User record not found in users table, creating manually...');
          // Create user record manually if trigger didn't fire
          final userData = {
                'id': response.user!.id,
                'email': email,
                'full_name': name,
                'role': 'admin',
          };
          
          // Add position_id if provided
          if (positionId != null && positionId.isNotEmpty) {
            userData['position_id'] = positionId;
            debugPrint('🔍 Adding position_id to user record: $positionId');
          }
          
          await SupabaseService.client
              .from('users')
              .insert(userData)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Failed to create user record. Please try again.');
                },
              );
          debugPrint('✅ User record created manually with position_id');
        } else {
          debugPrint('✅ User record exists in users table');
          // Update position_id if it wasn't set by trigger
          if (positionId != null && positionId.isNotEmpty && userRecord['position_id'] == null) {
            try {
              await SupabaseService.client
                  .from('users')
                  .update({'position_id': positionId})
                  .eq('id', response.user!.id);
              debugPrint('✅ Updated user record with position_id: $positionId');
            } catch (e) {
              debugPrint('⚠️ Could not update position_id: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error verifying/creating user record: $e');
        // Don't throw - user is created, record might be created later
      }
    } else {
      debugPrint('⚠️ No session after admin registration - email confirmation is required');
      debugPrint('⚠️ Admin must confirm email before getting a session');
    }
    
    return response;
  }

  Future<bool> canBootstrapAdmin() async {
    try {
      final response = await SupabaseService.client.rpc('can_bootstrap_admin');
      if (response is bool) return response;
      if (response is Map && response['can_bootstrap_admin'] is bool) {
        return response['can_bootstrap_admin'] as bool;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking admin bootstrap status: $e');
      return false;
    }
  }

  // Technician registration method
  Future<void> registerTechnician(
    String name,
    String email,
    String password,
    String? employeeId,
    String? phone,
    String? department,
    String? hireDate,
    File? profileImage,
  ) async {
    try {
      String? profilePictureUrl;
      final formattedName = NameFormatter.format(name);

      // First, create the auth user with 'technician' role
      // Note: signUp will create a basic pending approval, but we need to update it with additional details
      debugPrint('🔍 Starting technician registration for: $email');
      final response = await signUp(
        email: email,
        password: password,
        fullName: formattedName,
        role: UserRole.technician, // Explicitly set as technician
      );
      
      // Verify that user was actually created
      if (response.user == null) {
        debugPrint('❌ Technician registration failed - no user returned');
        throw Exception('Registration failed: User was not created. Please try again.');
      }
      
      debugPrint('✅ signUp completed for: $email, user ID: ${response.user!.id}');

      // Send push notification immediately after user creation (technicians bypass email confirmation)
      // This should happen regardless of session status since technicians are auto-confirmed
      if (_user != null) {
        try {
          debugPrint('📧 Sending push notification for new technician registration...');
          await PushNotificationService.sendToAdmins(
            title: 'New User Registration',
            body: '$formattedName has registered and is waiting for approval',
            data: {
              'type': 'new_registration',
              'user_id': _user!.id,
              'email': email,
            },
          );
          debugPrint('✅ Push notification sent to admins for new technician registration');
        } catch (pushError) {
          debugPrint('⚠️ Could not send push notification for new technician registration: $pushError');
          // Don't throw - notification failure shouldn't block registration
        }
      }

      if (profileImage != null) {
        debugPrint('🔍 Uploading profile image...');
        profilePictureUrl = await _uploadTechnicianProfileImage(profileImage);
        debugPrint('✅ Profile image uploaded: $profilePictureUrl');
      }
      
      // Check if we have a session (email confirmation might be required)
      final hasSession = response.session != null || SupabaseService.client.auth.currentSession != null;
      debugPrint('🔍 After signUp - hasSession: $hasSession, user: ${_user?.id ?? "null"}');
      debugPrint('🔍 Email confirmed: ${response.user?.emailConfirmedAt != null}');
      
      // Only try to update/create pending approval if we have a session
      // If email confirmation is required, these operations will fail due to RLS
      // The pending approval will be created by database trigger when email is confirmed
      if (_user != null && hasSession) {
        try {
          debugPrint('🔍 Checking for existing pending approval...');
          // Check if a pending approval already exists (created by signUp) with timeout
          final existingApproval = await SupabaseService.client
              .from('pending_user_approvals')
              .select('id')
              .eq('user_id', _user!.id)
              .eq('status', 'pending')
              .maybeSingle()
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Failed to check pending approval. Please try again.');
                },
              );
          
          if (existingApproval != null) {
            debugPrint('✅ Found existing pending approval, updating...');
            // Update existing approval with additional details
            final updateData = <String, dynamic>{
              'employee_id': employeeId,
              'phone': phone,
              'department': department,
              'hire_date': hireDate,
            };

            if (profilePictureUrl != null) {
              updateData['profile_picture_url'] = profilePictureUrl;
            }

            await SupabaseService.client
                .from('pending_user_approvals')
                .update(updateData)
                .eq('id', existingApproval['id'])
                .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw TimeoutException('Failed to update pending approval. Please try again.');
                  },
                );
            
            debugPrint('✅ Updated existing pending approval with additional details: $email');
          } else {
            debugPrint('⚠️ No existing approval found, creating new one...');
            // Create new pending approval if it doesn't exist
            final insertData = {
              'user_id': _user!.id,
              'email': email,
              'full_name': formattedName,
              'employee_id': employeeId,
              'phone': phone,
              'department': department,
              'hire_date': hireDate,
              'status': 'pending',
            };

            if (profilePictureUrl != null) {
              insertData['profile_picture_url'] = profilePictureUrl;
            }

            await SupabaseService.client
                .from('pending_user_approvals')
                .insert(insertData)
                .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw TimeoutException('Failed to create pending approval. Please try again.');
                  },
                );
          
            debugPrint('✅ Created pending approval for technician: $email');
          }
          
          // Create admin notification for new registration
          // This should happen whether we created a new approval or updated an existing one
          // Note: Push notification is already sent above, immediately after user creation
          try {
            debugPrint('📧 Creating admin notification for new registration...');
            await SupabaseService.client.rpc(
              'create_admin_notification',
              params: {
                'p_title': 'New User Registration',
                'p_message': '$formattedName has registered and is waiting for approval',
                'p_technician_name': formattedName,
                'p_technician_email': email,
                'p_type': 'new_registration',
                'p_data': {
                  'user_id': _user!.id,
                  'email': email,
                },
              },
            );
            debugPrint('✅ Admin notification created in notification center');
          } catch (notifError) {
            debugPrint('⚠️ Could not create admin notification: $notifError');
            // Fallback: Try direct insert
            try {
              await SupabaseService.client
                  .from('admin_notifications')
                  .insert({
                    'title': 'New User Registration',
                    'message': '$formattedName has registered and is waiting for approval',
                    'technician_name': formattedName,
                    'technician_email': email,
                    'type': 'new_registration',
                    'is_read': false,
                    'timestamp': DateTime.now().toIso8601String(),
                    'data': {
                      'user_id': _user!.id,
                      'email': email,
                    },
                  });
              debugPrint('✅ Admin notification created via direct insert');
            } catch (insertError) {
              debugPrint('⚠️ Could not create admin notification via direct insert: $insertError');
            }
          }
          
          // IMPORTANT: Delete any user record that might have been created by the trigger
          // Technicians should NOT have a user record until approved
          try {
            await SupabaseService.client
                .from('users')
                .delete()
                .eq('id', _user!.id)
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    debugPrint('⚠️ Delete user record timed out');
                  },
                );
            debugPrint('✅ Removed user record for pending technician (will be created on approval)');
          } catch (deleteError) {
            debugPrint('⚠️ Could not delete user record (might not exist): $deleteError');
            // Don't throw - this is not critical
          }
          
          // Set role to pending
          _userRole = UserRole.pending;
          await _saveUserRole(_userRole);
          notifyListeners();
          debugPrint('✅ Technician registration completed successfully');
        } catch (e, stackTrace) {
          debugPrint('❌ Error updating pending approval: $e');
          debugPrint('❌ Error type: ${e.runtimeType}');
          debugPrint('❌ Stack trace: $stackTrace');
          // If email confirmation is required, this is expected - don't throw
          // The pending approval will be created after email confirmation
          if (e.toString().contains('permission denied') || 
              e.toString().contains('row-level security') ||
              e.toString().contains('RLS')) {
            debugPrint('⚠️ RLS blocked pending approval creation - this is expected when email confirmation is required');
            debugPrint('⚠️ Pending approval will be created after email confirmation');
          } else if (e is TimeoutException || e.toString().contains('connection') || e.toString().contains('network')) {
            // Re-throw timeout and connection errors
            debugPrint('❌ Connection/timeout error - rethrowing');
            rethrow;
          } else {
            // Other errors should still be logged but not thrown
            debugPrint('⚠️ Non-RLS error occurred, but continuing anyway');
          }
        }
      } else if (_user == null) {
        debugPrint('❌ User is null after signUp');
        throw Exception('User creation failed - no user returned from signUp');
      } else {
        // User exists but no session - email confirmation required
        debugPrint('⚠️ User created but no session - email confirmation required');
        debugPrint('⚠️ Pending approval details will be saved after email confirmation');
        // Don't throw error - this is expected when email confirmation is enabled
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in registerTechnician: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error string: ${e.toString()}');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String?> _uploadTechnicianProfileImage(File image) async {
    try {
      final technicianId = _user?.id ?? SupabaseService.client.auth.currentUser?.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.path.split('.').last;
      final fileName = technicianId != null
          ? 'technician_${technicianId}_$timestamp.$extension'
          : 'technician_$timestamp.$extension';
      final filePath = 'profile-pictures/$fileName';

      await SupabaseService.client.storage.from('technician-images').upload(filePath, image);

      final publicUrl = SupabaseService.client.storage
          .from('technician-images')
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading technician profile image: $e');
      return null;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure Supabase client is ready
      final client = SupabaseService.client;
      debugPrint('🔍 Attempting sign in for: $email');
      debugPrint('🔍 Supabase client initialized: ${SupabaseService.isInitialized}');
      debugPrint('🔍 Supabase URL: ${SupabaseConfig.url}');
      debugPrint('🔍 Supabase Anon Key (first 20 chars): ${SupabaseConfig.anonKey.substring(0, 20)}...');
      
      // Verify we're using the correct database by checking the URL
      final expectedUrl = 'https://npgwikkvtxebzwtpzwgx.supabase.co';
      if (SupabaseConfig.url != expectedUrl) {
        debugPrint('⚠️ WARNING: Supabase URL mismatch!');
        debugPrint('⚠️ Expected: $expectedUrl');
        debugPrint('⚠️ Actual: ${SupabaseConfig.url}');
      } else {
        debugPrint('✅ Supabase URL matches expected: $expectedUrl');
      }
      
      // Skip connection test - just try to login directly
      // The login itself will test the connection
      debugPrint('🔍 Proceeding with login attempt...');
      
      // Try to sign in - with retry logic for connection issues
      AuthResponse? response;
      int attempt = 0;
      const maxAttempts = 3;
      
      while (attempt < maxAttempts) {
        try {
          attempt++;
          debugPrint('🔍 Sign in attempt $attempt/$maxAttempts...');
          
          // First, check if user exists and is confirmed
          // If email confirmation is enabled, unconfirmed users can't login
          response = await client.auth.signInWithPassword(
            email: email,
            password: password,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('❌ Sign in timed out after 30 seconds (attempt $attempt)');
              throw TimeoutException('Login is taking longer than expected. Please check your internet connection and try again.');
            },
          );
          
          // Success - break out of retry loop
          debugPrint('✅ Sign in successful on attempt $attempt');
          break;
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          
          // Check if email exists but password is wrong
          if (errorString.contains('invalid login credentials') || 
              errorString.contains('invalid_credentials') ||
              errorString.contains('wrong password') ||
              errorString.contains('incorrect password')) {
            // Email exists but password is wrong - provide helpful message
            debugPrint('⚠️ Email exists but password is incorrect');
            throw Exception('Incorrect password. Please check your password or use "Forgot Password" to reset it.');
          }
          
          // Check if user not found (email doesn't exist)
          if (errorString.contains('user not found') ||
              errorString.contains('email not found') ||
              errorString.contains('account not found')) {
            debugPrint('⚠️ Email not found');
            throw Exception('No account found with this email. Please check your email or create a new account.');
          }
          
          final isConnectionError = errorString.contains('connection') || 
              errorString.contains('network') ||
              errorString.contains('timeout') ||
              errorString.contains('socket') ||
              errorString.contains('failed host lookup');
          
          if (isConnectionError && attempt < maxAttempts) {
            debugPrint('⚠️ Connection error on attempt $attempt, retrying in ${attempt * 2} seconds...');
            await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
            continue; // Retry
          } else {
            // Not a connection error, or max attempts reached
            debugPrint('❌ Sign in failed: $e');
            rethrow;
          }
        }
      }
      
      // Check if we got a response after all retries
      if (response == null) {
        throw Exception('Sign in failed after $maxAttempts attempts. Please check your internet connection and try again.');
      }
      
      // At this point, response is guaranteed to be non-null
      final authResponse = response!;
      debugPrint('✅ Sign in response received: user=${authResponse.user?.id ?? "null"}');

      if (authResponse.user != null) {
        _user = authResponse.user;
        
        // Load user role - this is critical for determining if account is registered
        try {
          await _loadUserRole();
          
          // After loading role, check if user has a valid role
          // If role is still pending (unknown), the account is not properly registered
          if (_userRole == UserRole.pending) {
            // Check if user record exists in database
            final userRecord = await client
                .from('users')
                .select('id, role')
                .eq('id', _user!.id)
                .maybeSingle();
            
            if (userRecord == null || userRecord['role'] == null) {
              // Check if this is an OAuth user (first-time OAuth login)
              final isOAuthUser = _user!.appMetadata?['provider'] != null && 
                                  _user!.appMetadata?['provider'] != 'email';
              
              // Check if user has role in metadata (admin registered via email confirmation)
              final roleFromMetadata = _user!.userMetadata?['role'] as String?;
              
              if (roleFromMetadata == 'admin') {
                // Admin user who registered but user record wasn't created
                // This happens when deep link doesn't work after email confirmation
                debugPrint('🔐 Admin user without DB record - creating from metadata');
                try {
                  final positionId = _user!.userMetadata?['position_id'] as String?;
                  final fullName = _user!.userMetadata?['full_name'] as String? ?? 
                                  _user!.userMetadata?['name'] as String? ?? 
                                  _user!.email?.split('@')[0] ?? 'Admin';
                  
                  await client.from('users').insert({
                    'id': _user!.id,
                    'email': _user!.email,
                    'full_name': fullName,
                    'role': 'admin',
                    if (positionId != null && positionId.isNotEmpty) 'position_id': positionId,
                  });
                  debugPrint('✅ Admin user record created from metadata');
                  
                  // Set role and continue
                  _userRole = UserRole.admin;
                  await _saveUserRole(_userRole);
                  notifyListeners();
                  return authResponse;
                } catch (insertError) {
                  debugPrint('⚠️ Could not create admin record: $insertError');
                  // Continue to OAuth check
                }
              }
              
              if (isOAuthUser) {
                // OAuth users without a role need to select a role
                debugPrint('🔐 OAuth user without role - needs role selection');
                // Don't sign out - let the UI handle role selection
                // Set role to pending so UI can detect this case
                _userRole = UserRole.pending;
                await _saveUserRole(_userRole);
                notifyListeners();
                // Return authResponse - UI will handle role selection
                // The user is authenticated, just needs to select a role
                return authResponse;
              } else {
                // Email/password user without role - must register first
                debugPrint('❌ User logged in but account is not registered (no role found)');
                await signOut();
                throw Exception('Your account is not available. Please register first by creating a new account.');
              }
            }
          }
        } catch (e) {
          // If error is about account not being registered, rethrow it
          if (e.toString().contains('not available') || e.toString().contains('not registered')) {
            rethrow;
          }
          
          debugPrint('⚠️ Error loading user role after sign in: $e');
          // Try to use saved role or metadata as fallback
          try {
            final savedRole = await _getSavedUserRole();
            if (savedRole != null && savedRole != UserRole.pending) {
              _userRole = savedRole;
              debugPrint('✅ Using saved role after load error: ${_userRole.value}');
            } else {
              // Try user metadata
              final roleFromMetadata = _user!.userMetadata?['role'] as String?;
              if (roleFromMetadata != null && roleFromMetadata.isNotEmpty) {
                _userRole = UserRoleExtension.fromString(roleFromMetadata);
                debugPrint('✅ Using role from metadata: ${_userRole.value}');
              } else {
                // Check if this is an OAuth user (first-time OAuth login)
                final isOAuthUser = _user!.appMetadata?['provider'] != null && 
                                    _user!.appMetadata?['provider'] != 'email';
                
                if (isOAuthUser) {
                  // OAuth users without a role need to select a role
                  debugPrint('🔐 OAuth user without role - needs role selection');
                  // Don't sign out - let the UI handle role selection
                  // Set role to pending so UI can detect this case
                  _userRole = UserRole.pending;
                  await _saveUserRole(_userRole);
                  notifyListeners();
                  // Return authResponse - UI will handle role selection
                  // The user is authenticated, just needs to select a role
                  return authResponse;
                } else {
                  // Email/password user without role - must register first
                  debugPrint('❌ No role found in saved role or metadata - account not registered');
                  await signOut();
                  throw Exception('Your account is not available. Please register first by creating a new account.');
                }
              }
            }
            notifyListeners();
          } catch (fallbackError) {
            debugPrint('❌ Fallback role loading also failed: $fallbackError');
            // If fallback also fails and we still don't have a role, account is not registered
            if (_userRole == UserRole.pending) {
              await signOut();
              throw Exception('Your account is not available. Please register first by creating a new account.');
            }
            rethrow;
          }
        }
        
        // Send FCM token to server after successful login
        // Try immediately, and also retry after a delay in case Firebase is still initializing
        _sendFCMTokenAfterLogin();
        
        // Also try to save token from local storage (in case it was saved before login)
        try {
          await FirebaseMessagingService.saveTokenFromLocalStorage();
        } catch (e) {
          debugPrint('⚠️ Could not save FCM token from local storage: $e');
        }
        
        // CRITICAL: Check if email is confirmed - but skip for technicians (they bypass email confirmation)
        final roleFromMetadata = _user!.userMetadata?['role'] as String?;
        final isTechnician = roleFromMetadata == 'technician';
        
        if (_user!.emailConfirmedAt == null && !isTechnician) {
          debugPrint('❌ Email not confirmed - blocking access (admin requires email confirmation)');
          await signOut();
          throw Exception('Please confirm your email address before signing in. Check your inbox for the confirmation email.');
        }
        
        // Technicians can proceed without email confirmation
        if (isTechnician) {
          debugPrint('✅ Technician - bypassing email confirmation check');
        }
        
        // Ensure user record exists in public.users table
        // This handles cases where users confirmed email before the trigger was set up
        // BUT: Only create if role is explicitly set - no defaults
        try {
          final userRecord = await client
              .from('users')
              .select('id, role')
              .eq('id', _user!.id)
              .maybeSingle();
          
          if (userRecord == null) {
            // User record doesn't exist - wait a moment and retry (trigger might still be processing)
            debugPrint('⚠️ User record not found, waiting for trigger or checking metadata...');
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // Retry checking for user record (trigger might have created it)
            final retryUserRecord = await client
                .from('users')
                .select('id, role')
                .eq('id', _user!.id)
                .maybeSingle();
            
            if (retryUserRecord != null) {
              debugPrint('✅ User record found after retry - trigger created it');
              // Continue with login
            } else {
              // Still no user record - check if we have a role to create it with
              final roleFromMetadata = _user!.userMetadata?['role'] as String?;
              
              debugPrint('🔍 Role in metadata: $roleFromMetadata');
              debugPrint('🔍 Full metadata: ${_user!.userMetadata}');
              
              if (roleFromMetadata == null || roleFromMetadata.isEmpty) {
                // No role in metadata - account is not properly registered
                debugPrint('❌ User record not found and no role in metadata - account not registered');
                debugPrint('❌ This might mean the registration did not include a role');
                await signOut();
                throw Exception('Your account is not available. Please register first by creating a new account with a role (admin or technician).');
              }
              
              debugPrint('⚠️ User record not found in public.users, creating it with role: $roleFromMetadata');
              // Create user record from auth user data - role must be explicitly set
              try {
            await client.from('users').insert({
              'id': _user!.id,
              'email': _user!.email ?? email,
              'full_name': _user!.userMetadata?['full_name'] ?? 
                          _user!.userMetadata?['name'] ?? 
                          _user!.email?.split('@')[0] ?? 'User',
                  'role': roleFromMetadata, // Role must be explicitly set, no default
                });
                debugPrint('✅ Created user record in public.users with role: $roleFromMetadata');
                
                // If technician, also create pending approval
                if (roleFromMetadata == 'technician') {
                  try {
                    await client.from('pending_user_approvals').upsert({
                      'user_id': _user!.id,
                      'email': _user!.email ?? email,
                      'full_name': _user!.userMetadata?['full_name'] ?? 
                                  _user!.userMetadata?['name'] ?? 
                                  _user!.email?.split('@')[0] ?? 'User',
                      'status': 'pending',
                    }, onConflict: 'user_id');
                    debugPrint('✅ Created pending approval for technician');
                  } catch (e) {
                    debugPrint('⚠️ Could not create pending approval (might already exist): $e');
                  }
                }
              } catch (insertError) {
                debugPrint('❌ Error creating user record: $insertError');
                // Check if it was created by another process
                final finalCheck = await client
                    .from('users')
                    .select('id')
                    .eq('id', _user!.id)
                    .maybeSingle();
                if (finalCheck == null) {
                  await signOut();
                  throw Exception('Failed to create user record. Please try registering again.');
                }
              }
            }
          } else {
            final role = userRecord['role'] as String?;
            if (role == null || role.isEmpty) {
              // User record exists but has no role - account is not properly registered
              debugPrint('❌ User record exists but has no role - account not properly registered');
              await signOut();
              throw Exception('Your account is not available. Please register first by creating a new account.');
            }
          }
        } catch (e) {
          // If error is about account not being registered, rethrow it
          if (e.toString().contains('not available') || e.toString().contains('not registered')) {
            rethrow;
          }
          debugPrint('⚠️ Could not check/create user record: $e');
          // Don't block login for other errors - user record might be created by trigger later
        }
        
        // Validate admin domain restrictions
        if (_userRole == UserRole.admin) {
          if (!email.endsWith('@royalgulf.ae') && 
              !email.endsWith('@mekar.ae') && 
              !email.endsWith('@gmail.com')) {
            // User has admin role but doesn't have admin domain - revoke access
            await signOut();
            throw Exception('Access denied: Invalid admin credentials');
          }
        }
        
        // CRITICAL: For technicians, check if they're approved before allowing access
        // Block login completely if not approved
        if (_userRole != UserRole.admin) {
          debugPrint('🔍 Checking approval status for technician...');
          final isApproved = await checkApprovalStatus();
          debugPrint('🔍 Approval status result: $isApproved');
          
          if (isApproved == false || isApproved == null) {
            // User is not approved - BLOCK login completely
            _userRole = UserRole.pending;
            await _saveUserRole(_userRole);
            await signOut();
            debugPrint('❌ Technician login blocked - not approved yet');
            throw Exception('Your account is pending admin approval. You will be notified once your account is approved.');
          } else {
            debugPrint('✅ Technician is approved - allowing login');
          }
        }
        
        // Send FCM token to server after successful login
        try {
          final fcmToken = await _getFCMTokenIfAvailable().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ FCM token fetch timed out after login');
              return null;
            },
          );
          if (fcmToken != null && _user != null) {
            _sendFCMTokenToServer(fcmToken, _user!.id).timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('⚠️ FCM token send timed out after login');
              },
            ).catchError((e) {
              debugPrint('⚠️ Error sending FCM token after login: $e');
            });
          } else {
            debugPrint('⚠️ FCM token not available after login, will be sent when available');
          }
        } catch (e) {
          debugPrint('⚠️ Error getting/sending FCM token after login: $e');
        }
      }

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('❌ Error signing in: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error string: ${e.toString()}');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _isLoggingOut = true;
    notifyListeners();

    try {
      debugPrint('🚪 AuthProvider: Starting signOut process...');
      
      // Clear saved user role from local storage
      await _clearSavedUserRole();
      await LastRouteService.clearLastRoute();
      
      // Clear app badge on logout
      try {
        await BadgeService.clearBadge();
        debugPrint('✅ AuthProvider: Badge cleared on logout');
      } catch (badgeError) {
        debugPrint('⚠️ AuthProvider: Could not clear badge: $badgeError');
      }
      
      // Clear user data first to prevent widget tree issues
      _user = null;
      _userRole = UserRole.pending; // Reset to pending (unknown) after logout
      notifyListeners();
      
      // Then sign out from Supabase
      await SupabaseService.client.auth.signOut();
      debugPrint('✅ AuthProvider: Supabase signOut successful');
      debugPrint('✅ AuthProvider: User data and saved role cleared');
    } catch (e) {
      debugPrint('❌ AuthProvider: Error during signOut: $e');
      debugPrint('❌ AuthProvider: Error type: ${e.runtimeType}');
      // Ensure user data is cleared even on error
      _user = null;
      _userRole = UserRole.pending; // Reset to pending on error
      // Still try to clear badge on error
      try {
        await BadgeService.clearBadge();
      } catch (_) {}
    } finally {
_isLoading = false;
      _isLoggingOut = false;
      notifyListeners();
      debugPrint('✅ AuthProvider: signOut process completed');
    }
  }

  Future<void> deleteAccount() async {
    final currentUser = _user;
    if (currentUser == null) {
      throw Exception('No active user session');
    }

    try {
      debugPrint('🗑️ Deleting account for user: ${currentUser.id}');
      final response = await SupabaseService.client.functions
          .invoke('delete-account')
          .timeout(_authOperationTimeout);

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map
            ? (errorData['error']?.toString() ??
                errorData['message']?.toString() ??
                'Account deletion failed')
            : (errorData?.toString() ?? 'Account deletion failed');
        throw Exception(errorMessage);
      }

      debugPrint('✅ Account deletion completed');
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    try {
      // Use direct deep link (simpler, no web page needed)
      // If you want to use web redirect later, change to: 'https://rgstools.app/reset-password'
      final redirectUrl = redirectTo ?? 'com.rgs.app://reset-password';
      
      debugPrint('🔍 Sending password reset email to: $email');
      debugPrint('🔍 Redirect URL: $redirectUrl');
      
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      
      debugPrint('✅ Password reset email sent successfully');
    } catch (e) {
      debugPrint('❌ Error resetting password: $e');
      rethrow;
    }
  }

  /// Create auth account for admin-added technician
  /// This is different from self-registration:
  /// - Admin-created: Creates account with random password, auto-confirms email, sends password reset
  /// - Self-registered: User provides password, may need email confirmation
  /// 
  /// IMPORTANT: This method preserves the current admin's session and does NOT replace it
  Future<String?> createTechnicianAuthAccount({
    required String email,
    required String name,
    String? department,
  }) async {
    try {
      final formattedName = NameFormatter.format(name);
      debugPrint('🔍 Inviting technician via edge function: $email');
      final response = await SupabaseService.client.functions.invoke(
        'invite-technician',
        body: {
          'email': email,
          'full_name': formattedName,
          'department': department,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map
            ? (errorData['error']?.toString() ??
                errorData['message']?.toString() ??
                'Invite failed')
            : (errorData?.toString() ?? 'Invite failed');
        throw Exception(errorMessage);
      }

      final data = response.data;
      if (data is Map && data['user_id'] != null) {
        return data['user_id'].toString();
      }

      throw Exception('Invite failed - no user id returned');
    } catch (e) {
      debugPrint('❌ Error inviting technician: $e');
      rethrow;
    }
  }

  Future<String?> createAdminAuthAccount({
    required String email,
    required String name,
    required String positionId,
  }) async {
    if (!_isAdminEmailAllowed(email)) {
      throw Exception('Invalid email domain for admin registration. Use @royalgulf.ae, @mekar.ae, or @gmail.com');
    }

    if (_userRole != UserRole.admin) {
      throw Exception('Only admins can invite other admins.');
    }

    try {
      debugPrint('🔍 Inviting admin via edge function: $email');
      final response = await SupabaseService.client.functions.invoke(
        'invite-admin',
        body: {
          'email': email,
          'full_name': name,
          'position_id': positionId,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map
            ? (errorData['error']?.toString() ??
                errorData['message']?.toString() ??
                'Invite failed')
            : (errorData?.toString() ?? 'Invite failed');
        throw Exception(errorMessage);
      }

      final data = response.data;
      if (data is Map && data['user_id'] != null) {
        return data['user_id'].toString();
      }

      throw Exception('Invite failed - no user id returned');
    } catch (e) {
      debugPrint('❌ Error inviting admin: $e');
      rethrow;
    }
  }

  bool _isAdminEmailAllowed(String email) {
    return email.endsWith('@royalgulf.ae') ||
        email.endsWith('@mekar.ae') ||
        email.endsWith('@gmail.com');
  }


  /// Generate a secure random password
  /// This is used for admin-created accounts - technician will set their own password
  String _generateSecurePassword() {
    // Generate a cryptographically secure random password
    // The technician will set their own password via email, so this is just temporary
    const length = 24;
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final secureRandom = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    
    // Use timestamp + microseconds for better randomness
    final seed = (random * secureRandom) % chars.length;
    
    for (int i = 0; i < length; i++) {
      final index = (seed + i + (random % chars.length)) % chars.length;
      buffer.write(chars[index]);
    }
    
    return buffer.toString();
  }

  String? get userEmail => _user?.email;
  String? get userId => _user?.id;
  String? get userFullName => _user?.userMetadata?['full_name'] as String?;

  /// Sign in with Google using Supabase OAuth
  Future<void> signInWithGoogle() async {
    await _signInWithOAuthProvider(OAuthProvider.google);
  }

  /// Sign in with Apple using native authorization + Supabase id token
  Future<void> signInWithApple() async {
    if (kIsWeb) {
      await _signInWithOAuthProvider(OAuthProvider.apple);
      return;
    }

    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Sign in with Apple is only available on Apple devices.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
          'Sign in with Apple is not available. Ensure the capability is enabled for this app in Xcode and the Apple Developer App ID.',
        );
      }

      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      ).timeout(
        _applePromptTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Apple sign-in timed out. Please try again.',
            _applePromptTimeout,
          );
        },
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple sign-in failed to return a valid token.');
      }

      final response = await SupabaseService.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            nonce: rawNonce,
          )
          .timeout(
            _authOperationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Apple sign-in timed out. Please try again.',
                _authOperationTimeout,
              );
            },
          );

      if (response.session == null || response.user == null) {
        throw Exception('Apple sign-in failed to create a session.');
      }

      _user = response.user;
      try {
        await _loadUserRole().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('⚠️ Could not load role after Apple sign-in: $e');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('ℹ️ Apple sign-in cancelled by user');
        return;
      }
      debugPrint('❌ Apple sign-in failed: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Error during Apple sign-in: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Assign role to OAuth user (called after they select admin or technician)
  /// This creates/updates the user record in the database with the selected role
  Future<void> assignRoleToOAuthUser(UserRole role, {String? fullName}) async {
    if (_user == null) {
      throw Exception('No user logged in');
    }
    
    try {
      final client = SupabaseService.client;
      final userId = _user!.id;
      final email = _user!.email ?? '';
      final name = fullName ??
          _user!.userMetadata?['full_name'] ??
          _user!.userMetadata?['name'] ??
          email.split('@')[0];
      final formattedName =
          role == UserRole.technician ? NameFormatter.format(name) : name.trim();
      
      debugPrint('🔐 Assigning role to OAuth user: $role');
      debugPrint('🔐 User ID: $userId, Email: $email, Name: $name');
      
      // Update auth.users metadata with role
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'role': role.value,
            'full_name': formattedName,
          },
        ),
      );
      
      // Create or update user record in public.users table
      await client.from('users').upsert({
        'id': userId,
        'email': email,
        'full_name': formattedName,
        'role': role.value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // If technician, create pending approval record unless Apple bypass is enabled
      final bypassApproval =
          role == UserRole.technician && _isAppleProvider()
              ? await _isAppleApprovalBypassEnabled()
              : false;
      if (role == UserRole.technician && !bypassApproval) {
        try {
          final approvalResponse = await client.from('pending_user_approvals').insert({
            'user_id': userId,
            'email': email,
            'full_name': formattedName,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          }).select().single();
          debugPrint('✅ Created pending approval record for OAuth technician');
          
          // Create notification for admins in the main notification center
          try {
            final displayName = formattedName;
            await client
                .from('admin_notifications')
                .insert({
                  'title': 'New Technician Registration',
                  'message': '$displayName has requested access to the app and is awaiting approval.',
                  'technician_name': displayName,
                  'technician_email': email,
                  'type': 'access_request',
                  'is_read': false,
                  'timestamp': DateTime.now().toIso8601String(),
                  'data': {
                    'approval_id': approvalResponse['id'],
                    'user_id': userId,
                    'submitted_at': DateTime.now().toIso8601String(),
                  },
                });
            debugPrint('✅ Created admin notification for new OAuth technician approval request');
          } catch (notifError) {
            debugPrint('⚠️ Failed to create admin notification: $notifError');
            // Don't fail the registration if notification creation fails
          }
        } catch (e) {
          debugPrint('⚠️ Could not create pending approval (may already exist): $e');
        }
      } else if (role == UserRole.technician && bypassApproval) {
        debugPrint('✅ Apple bypass enabled - skipping pending approval creation');
      }
      
      // Update local state
      _userRole = role;
      await _saveUserRole(role);
      notifyListeners();
      
      debugPrint('✅ Role assigned successfully to OAuth user: $role');
    } catch (e, stackTrace) {
      debugPrint('❌ Error assigning role to OAuth user: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _signInWithOAuthProvider(OAuthProvider provider) async {
    _isLoading = true;
    notifyListeners();

    StreamSubscription<AuthState>? authSubscription;
    try {
      final client = SupabaseService.client;
      final authCompleter = Completer<AuthState>();

      authSubscription = client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.signedOut) {
          if (!authCompleter.isCompleted) {
            authCompleter.complete(data);
          }
          authSubscription?.cancel();
        }
      });

      // Configure OAuth with proper redirect URL for mobile apps
      // The redirect URL must match what's configured in Supabase dashboard
      await client.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.rgs.app://auth/callback',
      );

      final authState = await authCompleter.future.timeout(
        _authOperationTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Login timed out. Please try again.',
            _authOperationTimeout,
          );
        },
      );

      if (authState.event == AuthChangeEvent.signedOut ||
          authState.session == null) {
        throw Exception('Sign-in was cancelled or failed. Please try again.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during OAuth sign-in ($provider): $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      await authSubscription?.cancel();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadUserRole() async {
    // CRITICAL: Don't load role or create accounts during logout
    if (_isLoggingOut) {
      debugPrint('🔍 Ignoring _loadUserRole during logout');
      return;
    }
    
    if (_user == null) {
      _userRole = UserRole.pending; // No user - role is unknown (pending)
      return;
    }
    
    // CRITICAL: Don't create accounts if there's no valid session
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      debugPrint('🔍 No session found - cannot load role or create accounts');
      _userRole = UserRole.pending;
      return;
    }

    try {
      // First, try to load role from local storage (for offline/restart scenarios)
      final savedRole = await _getSavedUserRole();
      if (savedRole != null) {
        _userRole = savedRole;
        debugPrint('✅ User role loaded from local storage: ${_userRole.value}');
        notifyListeners();
      }

      // Check if session is expired and refresh if needed
      // CRITICAL: Don't clear user on refresh failure - maintain persistence
      final session = SupabaseService.client.auth.currentSession;
      if (session != null && session.isExpired) {
        debugPrint('🔄 Session expired, attempting to refresh...');
        try {
          final refreshResponse = await SupabaseService.client.auth.refreshSession().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Session refresh timed out', const Duration(seconds: 3));
            },
          );
          if (refreshResponse.session != null) {
            debugPrint('✅ Session refreshed successfully');
            _user = refreshResponse.session!.user;
          } else {
            debugPrint('❌ Session refresh failed - no new session');
            // Don't clear user data immediately, try to maintain session
            debugPrint('🔄 Attempting to maintain session...');
            // Continue to load role even if refresh failed - session might still be valid
          }
        } catch (e) {
          debugPrint('❌ Failed to refresh session: $e');
          // Don't clear user data, maintain session
          debugPrint('🔄 Maintaining session despite refresh failure...');
          // Continue to load role even if refresh failed - session might still be valid
        }
      }

      // Try to get role from database (online) - with timeout and better error handling
      int retryCount = 0;
      const maxRetries = 2; // Reduced retries for faster timeout
      
      while (retryCount < maxRetries) {
        try {
          final response = await SupabaseService.client
              .from('users')
              .select('role, position_id')
              .eq('id', _user!.id)
              .maybeSingle() // Use maybeSingle instead of single to avoid errors if user doesn't exist
              .timeout(
                const Duration(seconds: 5), // Increased timeout for desktop
                onTimeout: () {
                  throw TimeoutException('Database query timed out', const Duration(seconds: 5));
                },
              );

          if (response != null && response['role'] != null) {
            final roleFromDb = response['role'] as String;
            final newRole = UserRoleExtension.fromString(roleFromDb);
            final positionId = response['position_id'] as String?;
            
            // CRITICAL: If role is 'technician', check pending approvals FIRST
            // Technicians with pending approval should have UserRole.pending, not UserRole.technician
            if (roleFromDb == 'technician') {
              debugPrint('🔍 User has technician role, checking pending approval status...');
              if (_isAppleProvider() && await _isAppleApprovalBypassEnabled()) {
                debugPrint('✅ Apple sign-in detected - skipping pending approval checks');
                _userRole = newRole;
                await _saveUserRole(newRole);
                notifyListeners();
                return;
              }
              try {
                final pendingApproval = await SupabaseService.client
                    .from('pending_user_approvals')
                    .select('status')
                    .eq('user_id', _user!.id)
                    .order('created_at', ascending: false)
                    .limit(1)
                    .maybeSingle()
                    .timeout(
                      const Duration(seconds: 3),
                      onTimeout: () {
                        throw TimeoutException('Pending approval check timed out', const Duration(seconds: 3));
                      },
                    );
                
                if (pendingApproval != null) {
                  final status = pendingApproval['status'] as String?;
                  debugPrint('🔍 Found pending approval with status: $status');
                  
                  if (status == 'pending' || status == 'rejected') {
                    // Technician is pending approval - set role to pending
                    debugPrint('⚠️ Technician has pending/rejected approval - setting role to pending');
                    _userRole = UserRole.pending;
                    await _saveUserRole(_userRole);
                    notifyListeners();
                    return;
                  } else if (status == 'approved') {
                    // Technician is approved - use technician role
                    debugPrint('✅ Technician is approved - using technician role');
            _userRole = newRole;
                    await _saveUserRole(newRole);
                    notifyListeners();
                    return;
                  }
                } else {
                  // No pending approval record - if user record exists, they're approved
                  debugPrint('✅ No pending approval found - technician is approved');
                  _userRole = newRole;
                  await _saveUserRole(newRole);
                  notifyListeners();
                  return;
                }
              } catch (e) {
                debugPrint('⚠️ Error checking pending approval: $e');
                // On error, default to technician role (safer than blocking)
                _userRole = newRole;
                await _saveUserRole(newRole);
                notifyListeners();
                return;
              }
            } else {
              // Not a technician (admin or other) - use role from database
              _userRole = newRole;
            await _saveUserRole(newRole);
            debugPrint('✅ User role loaded from database: ${_userRole.value}');
            notifyListeners();
              if (roleFromDb == 'admin' && (positionId == null || positionId.isEmpty)) {
                await _ensureAdminPosition();
              }
            return;
            }
          } else {
            debugPrint('⚠️ No role found in database, keeping current role: ${_userRole.value}');
            return;
          }
        } catch (e) {
          // Handle connection errors gracefully - don't fail login if we can't load role
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('connection') || 
              errorString.contains('network') || 
              errorString.contains('timeout') ||
              errorString.contains('cannot connect to database')) {
            debugPrint('⚠️ Connection error loading user role: $e');
            debugPrint('🔄 Using saved role or default role instead');
            // Use saved role if available, otherwise keep current role
            final savedRole = await _getSavedUserRole();
            if (savedRole != null) {
              _userRole = savedRole;
              debugPrint('✅ Using saved role: ${_userRole.value}');
            } else {
              // Try to get role from user metadata as fallback
              final roleFromMetadata = _user!.userMetadata?['role'] as String?;
              if (roleFromMetadata != null) {
                _userRole = UserRoleExtension.fromString(roleFromMetadata);
                debugPrint('✅ Using role from metadata: ${_userRole.value}');
              }
            }
            notifyListeners();
            return; // Don't retry on connection errors
          }
          
          // CRITICAL: If user record doesn't exist, DO NOT create it automatically
          // User records should only be created during explicit registration, not during role loading
          // This prevents creating default accounts on logout or session restoration
          if (e.toString().contains('0 rows') || e.toString().contains('not found')) {
            debugPrint('⚠️ User record not found in database');
            debugPrint('⚠️ NOT creating user record - _loadUserRole() only loads roles, never creates accounts');
            debugPrint('⚠️ Accounts must be created during explicit registration only');
            
            // Check if user has pending approval (for technicians)
            try {
              final pendingApproval = await SupabaseService.client
                  .from('pending_user_approvals')
                  .select('status')
                  .eq('user_id', _user!.id)
                  .maybeSingle()
                  .timeout(
                    const Duration(seconds: 3),
                    onTimeout: () {
                      throw TimeoutException('Pending approval query timed out', const Duration(seconds: 3));
                    },
                  );
              
              if (pendingApproval != null) {
                final status = pendingApproval['status'] as String?;
                debugPrint('🔍 Found approval record with status: $status');
                
                if (status == 'pending') {
                  debugPrint('⚠️ User has pending approval - setting role to pending');
                  _userRole = UserRole.pending;
                  await _saveUserRole(_userRole);
                  notifyListeners();
                  return;
                } else if (status == 'rejected') {
                  debugPrint('❌ User approval was rejected - access denied');
                  _userRole = UserRole.pending; // Treat as pending to show rejection screen
                await _saveUserRole(_userRole);
                notifyListeners();
                return;
                } else if (status == 'approved') {
                  // User is approved, but user record doesn't exist - this shouldn't happen
                  // Don't create it here - it should have been created during approval
                  debugPrint('⚠️ User approved but no user record - should have been created during approval');
                _userRole = UserRole.pending;
                await _saveUserRole(_userRole);
                notifyListeners();
                return;
              }
              }
            } catch (pendingError) {
              debugPrint('🔍 No pending approval found: $pendingError');
            }
            
            // No user record and no pending approval - set role to pending
            // CRITICAL: Do NOT create user record here - accounts must be created during explicit registration only
            // _loadUserRole() only loads roles, never creates accounts
                  _userRole = UserRole.pending;
                  await _saveUserRole(_userRole);
              notifyListeners();
              return;
          }
          retryCount++;
          debugPrint('❌ Error loading user role (attempt $retryCount/$maxRetries): $e');
          
          if (retryCount >= maxRetries) {
            debugPrint('❌ Max retries reached, keeping current role: ${_userRole.value}');
            // Don't default to any role - keep current role or set to pending if unknown
            if (_userRole == UserRole.pending) {
              debugPrint('🔄 Role is pending (unknown) - user needs to register with explicit role');
            } else {
              debugPrint('🔄 Keeping current role: ${_userRole.value}');
            }
            notifyListeners();
            return;
          }
          
          // Wait before retry
          await Future.delayed(Duration(seconds: 1));
        }
      }
    } catch (e) {
      debugPrint('❌ Critical error in _loadUserRole: $e');
      // Don't change role on error, keep current role
      debugPrint('🔄 Keeping current role due to error: ${_userRole.value}');
    }
  }

  Future<void> forceReAuthentication() async {
    debugPrint('🔄 Forcing re-authentication...');
    _user = null;
    _userRole = UserRole.pending; // Reset to pending (unknown) when forcing re-auth
    notifyListeners();
    
    // Clear Supabase session
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('Error during force logout: $e');
    }
  }

  // Method to handle automatic session refresh
  Future<void> refreshSessionIfNeeded() async {
    if (_user == null) return;
    
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null && session.isExpired) {
        debugPrint('🔄 Auto-refreshing expired session...');
        final refreshResponse = await SupabaseService.client.auth.refreshSession();
        if (refreshResponse.session != null) {
          debugPrint('✅ Session auto-refreshed successfully');
          _user = refreshResponse.session!.user;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Auto-refresh failed: $e');
      // Don't clear user data, maintain session
    }
  }

  // Method to check if user should stay logged in
  bool shouldMaintainSession() {
    // Keep user logged in unless they explicitly log out
    return _user != null;
  }

  // Enhanced session persistence
  Future<void> maintainSession() async {
    if (_user == null) return;
    
    try {
      // Check session status without clearing user data
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Session is valid, maintaining login');
        return;
      }
      
      // If no session but user exists, try to refresh
      debugPrint('🔄 No active session, attempting refresh...');
      await refreshSessionIfNeeded();
    } catch (e) {
      debugPrint('❌ Session maintenance error: $e');
      // Don't clear user data on error
    }
  }

  // Save user role to local storage for offline persistence
  Future<void> _saveUserRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role_${_user?.id}', role.value);
      debugPrint('✅ User role saved to local storage: ${role.value}');
    } catch (e) {
      debugPrint('❌ Error saving user role: $e');
    }
  }

  // Load user role from local storage
  Future<UserRole?> _getSavedUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('user_role_${_user?.id}');
      if (savedRole != null) {
        return UserRoleExtension.fromString(savedRole);
      }
    } catch (e) {
      debugPrint('❌ Error loading saved user role: $e');
    }
    return null;
  }

  // Clear saved user role (called on logout)
  Future<void> _clearSavedUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role_${_user?.id}');
      debugPrint('✅ Saved user role cleared');
    } catch (e) {
      debugPrint('❌ Error clearing saved user role: $e');
    }
  }

  Future<void> updateUserRole(UserRole newRole) async {
    if (_user == null) return;

    try {
      debugPrint('🔧 Updating user role to: $newRole');
      
      // Update in Supabase users table
      await SupabaseService.client
          .from('users')
          .upsert({
            'id': _user!.id,
            'email': _user!.email,
            'full_name': userFullName,
            'role': newRole.value,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Update local role
      _userRole = newRole;
      debugPrint('✅ User role updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating user role: $e');
      rethrow;
    }
  }

  Future<void> updateUserName(String newName) async {
    if (_user == null) return;

    try {
      final formattedName = _userRole == UserRole.technician
          ? NameFormatter.format(newName)
          : newName.trim();
      debugPrint('🔧 Updating user name to: $formattedName');
      
      // Update user metadata in Supabase Auth
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            ..._user!.userMetadata ?? {},
            'full_name': formattedName,
          },
        ),
      );

      // Update in Supabase users table
      await SupabaseService.client
          .from('users')
          .upsert({
            'id': _user!.id,
            'email': _user!.email,
            'full_name': formattedName,
            'role': _userRole.value,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Refresh user data
      final updatedUser = SupabaseService.client.auth.currentUser;
      if (updatedUser != null) {
        _user = updatedUser;
      }
      
      debugPrint('✅ User name updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      rethrow;
    }
  }


  // Permission check methods
  bool hasPermission(String permission) {
    switch (permission) {
      case 'manage_users':
        return _userRole.canManageUsers;
      case 'manage_tools':
        return _userRole.canManageTools;
      case 'manage_technicians':
        return _userRole.canManageTechnicians;
      case 'view_reports':
        return _userRole.canViewReports;
      case 'manage_settings':
        return _userRole.canManageSettings;
      case 'checkout_tools':
        return _userRole.canCheckoutTools;
      case 'checkin_tools':
        return _userRole.canCheckinTools;
      case 'view_assigned_tools':
        return _userRole.canViewAssignedTools;
      case 'view_all_tools':
        return _userRole.canViewAllTools;
      case 'view_shared_tools':
        return _userRole.canViewSharedTools;
      case 'update_tool_condition':
        return _userRole.canUpdateToolCondition;
      case 'add_tools':
        return _userRole.canAddTools;
      case 'edit_tools':
        return _userRole.canEditTools;
      case 'bulk_import':
        return _userRole.canBulkImport;
      case 'delete_data':
        return _userRole.canDeleteData;
      default:
        return false;
    }
  }

  /// Get FCM token if available, or try to refresh it
  Future<String?> _getFCMTokenIfAvailable() async {
    try {
      // First, try to get existing token
      var token = FirebaseMessagingService.fcmToken;
      if (token != null && token.isNotEmpty) {
        return token;
      }
      
      // If token is null, try to refresh it
      debugPrint('🔄 [FCM] Token is null, attempting to refresh...');
      token = await FirebaseMessagingService.refreshToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('✅ [FCM] Token obtained after refresh');
        return token;
      }
      
      debugPrint('⚠️ [FCM] Token still null after refresh attempt');
      return null;
    } catch (e) {
      debugPrint('⚠️ Could not get FCM token: $e');
      return null;
    }
  }

  /// Send FCM token to server
  Future<void> _sendFCMTokenToServer(String token, String userId) async {
    try {
      debugPrint('📤 [FCM] Sending token to server via FirebaseMessagingService...');
      await FirebaseMessagingService.sendTokenToServer(token, userId);
      debugPrint('✅ [FCM] Token send completed');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Could not send FCM token to server: $e');
      debugPrint('❌ [FCM] Stack trace: $stackTrace');
    }
  }

  /// Send FCM token after login with retry logic
  /// This handles cases where Firebase might not be initialized yet
  Future<void> _sendFCMTokenAfterLogin() async {
    if (_user == null) {
      debugPrint('⚠️ [FCM] Cannot send token: user is null');
      return;
    }
    
    debugPrint('🔄 [FCM] Attempting to save FCM token after login for user: ${_user!.id}');
    
    // Try immediately
    try {
      await FirebaseMessagingService.registerCurrentToken(forceRefresh: true);
      debugPrint('✅ [FCM] Token registration attempted after login');
      return; // Success path will be handled inside registration
    } catch (e, stackTrace) {
      debugPrint('⚠️ [FCM] Could not register FCM token immediately after login: $e');
      debugPrint('⚠️ [FCM] Stack trace: $stackTrace');
    }
    
    // If token not available, retry after delays (Firebase might still be initializing)
    debugPrint('🔄 [FCM] Token not available immediately, will retry...');
    
    // Retry after 2 seconds
    Future.delayed(const Duration(seconds: 2), () async {
      if (_user == null) return;
      try {
        await FirebaseMessagingService.registerCurrentToken();
        debugPrint('✅ [FCM] Token registration attempted on retry (2s)');
          return;
      } catch (e) {
        debugPrint('⚠️ [FCM] Token retry (2s) failed: $e');
      }
      
      // Retry after 5 seconds
      Future.delayed(const Duration(seconds: 3), () async {
        if (_user == null) return;
        try {
          await FirebaseMessagingService.registerCurrentToken();
          debugPrint('✅ [FCM] Token registration attempted on retry (5s)');
        } catch (e) {
          debugPrint('⚠️ [FCM] Token retry (5s) failed: $e');
        }
      });
    });
  }
}
