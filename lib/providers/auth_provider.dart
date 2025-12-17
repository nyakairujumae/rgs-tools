import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import '../services/supabase_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/push_notification_service.dart';
import '../services/first_launch_service.dart';
import '../models/user_role.dart';
import '../config/supabase_config.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserRole _userRole = UserRole.pending; // Default to pending (unknown) instead of technician
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoggingOut = false;

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
  
  /// Check if user's email is confirmed
  bool get isEmailConfirmed {
    return _user?.emailConfirmedAt != null;
  }

  /// Check if the current user has been approved
  /// Returns null if check is in progress, true if approved, false if pending/rejected
  Future<bool?> checkApprovalStatus() async {
    if (_user == null) return null;
    
    try {
      // First check pending approvals table - this is the source of truth for technicians
      // Get the most recent approval record (in case of duplicates)
      final approval = await SupabaseService.client
          .from('pending_user_approvals')
          .select('status')
          .eq('user_id', _user!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (approval != null) {
        final status = approval['status'] as String?;
        if (status == 'approved') {
          // If approved, also check if user record exists (should exist after approval)
          final userRecord = await SupabaseService.client
              .from('users')
              .select('role')
              .eq('id', _user!.id)
              .maybeSingle();
          return userRecord != null; // Approved and user record exists
        } else {
          // Status is pending or rejected
          return false;
        }
      }
      
      // No pending approval record found - check if user exists in users table
      // If user exists but no pending approval record, they might be an existing approved user
      final userRecord = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', _user!.id)
          .maybeSingle();
      
      if (userRecord != null && userRecord['role'] != null) {
        // User exists in users table - check if they're admin or approved technician
        final role = userRecord['role'] as String;
        if (role == 'admin') {
          return true; // Admins are always approved
        }
        // For technicians, if they have a user record, they were approved
        return true;
      }
      
      // No record found anywhere - treat as not approved (pending registration)
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

    // Set a maximum timeout for initialization (8 seconds)
    // After this, we'll proceed even if not fully initialized
    Timer(const Duration(seconds: 8), () {
      if (_isLoading || !_isInitialized) {
        print('⚠️ Initialization timeout - forcing completion');
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    });

    try {
      print('🔍 Getting current session...');
      // Minimal delay to ensure Supabase has restored any persisted session
      // Reduced to milliseconds for faster startup
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Get current session (this is local, no network call)
      var session = SupabaseService.client.auth.currentSession;
      print('🔍 Current session: ${session != null ? "Found (user: ${session.user.email})" : "None"}');
      
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
          // If refresh fails, clear the expired session
          session = null;
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
            
            // CRITICAL: Check if email is confirmed before allowing access
            if (_user!.emailConfirmedAt == null) {
              print('❌ Email not confirmed - cannot restore session');
              _user = null;
              return; // Don't proceed if email is not confirmed
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
            }
          }
        } catch (e) {
          print('⚠️ Error checking currentUser: $e');
        }
      }
      
      print('🔍 Current user: ${_user?.email ?? "None"}');

      // Listen to auth state changes
      print('🔍 Setting up auth state listener...');
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        print('🔍 Auth state changed: ${data.session?.user?.email ?? "None"}');
        _user = data.session?.user;
        _loadUserRole();
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
        
        // Send FCM token to server after initialization if available (non-blocking)
        try {
          final fcmToken = await _getFCMTokenIfAvailable().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ FCM token fetch timed out');
              return null;
            },
          );
          if (fcmToken != null) {
            _sendFCMTokenToServer(fcmToken, _user!.id).timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('⚠️ FCM token send timed out');
              },
            ).catchError((e) {
              debugPrint('⚠️ Could not send FCM token: $e');
            });
          }
        } catch (e) {
          debugPrint('⚠️ Could not send FCM token after initialization: $e');
        }
      } else {
        print('🔍 No user found, setting role to pending (unknown)');
        _userRole = UserRole.pending; // Unknown user - no default role
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
      // Set to pending on error - don't assume role
      _userRole = UserRole.pending;
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

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
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

      if (response.user != null) {
        _user = response.user;
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
              await SupabaseService.client
                  .from('pending_user_approvals')
                  .insert({
                    'user_id': _user!.id,
                    'email': email,
                    'full_name': fullName,
                    'status': 'pending',
                  })
                  .timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      throw TimeoutException('Failed to create pending approval. Please try again.');
                    },
                  );
              
              debugPrint('✅ Pending approval created for technician: $email');
              
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
    String position,
  ) async {
    // Validate email domain
    if (!email.endsWith('@royalgulf.ae') && 
        !email.endsWith('@mekar.ae') && 
        !email.endsWith('@gmail.com')) {
      throw Exception('Invalid email domain for admin registration. Use @royalgulf.ae, @mekar.ae, or @gmail.com');
    }

    debugPrint('🔍 Starting admin registration for: $email');
    final response = await signUp(
      email: email,
      password: password,
      fullName: name,
      role: UserRole.admin,
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
          await SupabaseService.client
              .from('users')
              .insert({
                'id': response.user!.id,
                'email': email,
                'full_name': name,
                'role': 'admin',
              })
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Failed to create user record. Please try again.');
                },
              );
          debugPrint('✅ User record created manually');
        } else {
          debugPrint('✅ User record exists in users table');
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

      // First, create the auth user with 'technician' role
      // Note: signUp will create a basic pending approval, but we need to update it with additional details
      debugPrint('🔍 Starting technician registration for: $email');
      final response = await signUp(
        email: email,
        password: password,
        fullName: name.toUpperCase(), // Force uppercase for technician names
        role: UserRole.technician, // Explicitly set as technician
      );
      
      // Verify that user was actually created
      if (response.user == null) {
        debugPrint('❌ Technician registration failed - no user returned');
        throw Exception('Registration failed: User was not created. Please try again.');
      }
      
      debugPrint('✅ signUp completed for: $email, user ID: ${response.user!.id}');

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
              'full_name': name.toUpperCase(), // Force uppercase for technician names
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
            
            // Send push notification to admins about new registration
            try {
              await PushNotificationService.sendToAdmins(
                title: 'New User Registration',
                body: '$name has registered and is waiting for approval',
                data: {
                  'type': 'new_registration',
                  'user_id': _user!.id,
                  'email': email,
                },
              );
              debugPrint('✅ Push notification sent to admins for new registration');
            } catch (pushError) {
              debugPrint('⚠️ Could not send push notification for new registration: $pushError');
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
              // User doesn't have a registered account - sign them out and show error
              debugPrint('❌ User logged in but account is not registered (no role found)');
              await signOut();
              throw Exception('Your account is not available. Please register first by creating a new account.');
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
                // No role found anywhere - account is not registered
                debugPrint('❌ No role found in saved role or metadata - account not registered');
                await signOut();
                throw Exception('Your account is not available. Please register first by creating a new account.');
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
        
        // Mark first launch as complete after successful login
        // This ensures splash screen only shows on first install
        try {
          await FirstLaunchService.markFirstLaunchComplete();
          debugPrint('✅ First launch marked as complete');
        } catch (e) {
          debugPrint('⚠️ Could not mark first launch complete (non-critical): $e');
        }
        
        // CRITICAL: Check if email is confirmed before allowing access
        if (_user!.emailConfirmedAt == null) {
          debugPrint('❌ Email not confirmed - blocking access');
          await signOut();
          throw Exception('Please confirm your email address before signing in. Check your inbox for the confirmation email.');
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
        
        // For technicians, check if they're approved before allowing access
        if (_userRole != UserRole.admin) {
          final isApproved = await checkApprovalStatus();
          if (isApproved == false) {
            // User is not approved - set role to pending to block access
            _userRole = UserRole.pending;
            await _saveUserRole(_userRole);
            debugPrint('⚠️ Technician login blocked - not approved yet');
            notifyListeners();
            // Don't throw error, just set role to pending so UI can handle it
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
    } finally {
_isLoading = false;
      _isLoggingOut = false;
      notifyListeners();
      debugPrint('✅ AuthProvider: signOut process completed');
    }
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    try {
      // Use the app's deep link URL for password reset
      final redirectUrl = redirectTo ?? 'com.rgs.app://reset-password';
      
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  String? get userEmail => _user?.email;
  String? get userId => _user?.id;
  String? get userFullName => _user?.userMetadata?['full_name'] as String?;

  /// Sign in with Google using Supabase OAuth
  Future<void> signInWithGoogle() async {
    await _signInWithOAuthProvider(OAuthProvider.google);
  }

  /// Sign in with Apple using Supabase OAuth
  Future<void> signInWithApple() async {
    await _signInWithOAuthProvider(OAuthProvider.apple);
  }

  Future<void> _signInWithOAuthProvider(OAuthProvider provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService.client;

      await client.auth.signInWithOAuth(
        provider,
        // The redirect URL should match the deep link configured in Supabase dashboard
        // For mobile, we rely on the app scheme; for web, Supabase handles redirects.
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error during OAuth sign-in ($provider): $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Simulate login for web ONLY (bypasses Supabase)
  /// Sets a mock user and role for testing/demo purposes
  /// NOTE: Desktop uses real Supabase authentication, not this method
  void simulateLogin(String email, UserRole role) {
    // Safety check: only allow on web
    if (!kIsWeb) {
      debugPrint('❌ ERROR: simulateLogin called on non-web platform!');
      debugPrint('❌ Desktop and Mobile must use real Supabase authentication');
      throw Exception('Simulated login is only available on web platform. Desktop and Mobile must use real authentication.');
    }
    
    debugPrint('🔍 Simulating login for WEB ONLY: $email with role: ${role.value}');
    
    // Clear any existing real session first to avoid conflicts
    _user = null;
    _userRole = UserRole.pending; // Reset to pending before setting explicit role
    
    // Create a mock user object with simulated ID
    _user = User(
      id: 'simulated-web-${email.hashCode}',
      appMetadata: {},
      userMetadata: {
        'email': email,
        'full_name': email.split('@').first,
        'role': role.value,
        'simulated': true, // Mark as simulated to distinguish from real users
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    _userRole = role;
    _isLoading = false;
    notifyListeners();
    
    debugPrint('✅ Simulated login complete (WEB ONLY): user=${_user!.email}, role=${_userRole.value}');
  }

  Future<void> _loadUserRole() async {
    if (_user == null) {
      _userRole = UserRole.pending; // No user - role is unknown (pending)
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
            return;
          }
        } catch (e) {
          debugPrint('❌ Failed to refresh session: $e');
          // Don't clear user data on refresh failure, maintain session
          debugPrint('🔄 Maintaining session despite refresh failure...');
          return;
        }
      }

      // Try to get role from database (online) - with timeout and better error handling
      int retryCount = 0;
      const maxRetries = 2; // Reduced retries for faster timeout
      
      while (retryCount < maxRetries) {
        try {
          final response = await SupabaseService.client
              .from('users')
              .select('role')
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
            
            // CRITICAL: If role is 'technician', check pending approvals FIRST
            // Technicians with pending approval should have UserRole.pending, not UserRole.technician
            if (roleFromDb == 'technician') {
              debugPrint('🔍 User has technician role, checking pending approval status...');
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
          
          // If user record doesn't exist, check if this is a new registration
          if (e.toString().contains('0 rows') || e.toString().contains('not found')) {
            debugPrint('🔄 User record not found, checking if this is a new registration...');
            
            // Check if user has pending approval (new technician registration)
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
                  // User is approved, role should be set in users table
                  // Continue to check users table
                  debugPrint('✅ User approval was approved - checking users table');
                }
              }
            } catch (pendingError) {
              debugPrint('🔍 No pending approval found: $pendingError');
            }
            
            // Check if user has pending approval - if so, don't create user record yet
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
              if (status == 'pending' || status == 'rejected') {
                debugPrint('⚠️ User has pending/rejected approval - not creating user record');
                _userRole = UserRole.pending;
                await _saveUserRole(_userRole);
                notifyListeners();
                return;
              }
            }
            
            // Only create admin users for specific domains, technicians must be approved first
            try {
              // Get role from metadata - must be explicitly set, no default
              String? role = _user!.userMetadata?['role'] as String?;
              
              // If no role in metadata, try to get from database
              if (role == null || role.isEmpty) {
                try {
                  final userRecord = await SupabaseService.client
                      .from('users')
                      .select('role')
                      .eq('id', _user!.id)
                      .maybeSingle();
                  role = userRecord?['role'] as String?;
                } catch (e) {
                  debugPrint('⚠️ Could not get role from database: $e');
                }
              }
              
              // Only create user record if role is explicitly set
              // No automatic role assignment - role must be provided during registration
              if (role == null || role.isEmpty) {
                debugPrint('⚠️ No role in user metadata - cannot create user record');
                debugPrint('⚠️ User must register with explicit role (admin or technician)');
                return; // Don't create user record without explicit role
              }
              
              debugPrint('🔍 Creating user record with explicit role: $role');
              
              // Determine if admin based on email domain (only if role is already admin)
              // Don't auto-assign admin based on domain - role must be explicit
              if (role == 'admin' && _user!.email != null &&
                  (_user!.email!.endsWith('@royalgulf.ae') ||
                   _user!.email!.endsWith('@mekar.ae') ||
                   _user!.email!.endsWith('@gmail.com'))) {
                debugPrint('🔍 Admin domain detected, creating admin user');
              
                // Create user record for admins immediately
                await SupabaseService.client
                    .from('users')
                    .insert({
                      'id': _user!.id,
                      'email': _user!.email ?? 'user@example.com',
                      'full_name': _user!.userMetadata?['full_name'] ?? 'User',
                      'role': role, // Use explicit role from metadata - no default
                      'created_at': DateTime.now().toIso8601String(),
                    });
              
                _userRole = UserRoleExtension.fromString(role);
                await _saveUserRole(_userRole);
                debugPrint('✅ Created admin user with role: $role');
                notifyListeners();
                return;
              } else if (role == 'technician') {
                // For technicians, check if they're approved
                if (pendingApproval != null && pendingApproval['status'] == 'approved') {
                  // Technician was approved, user record should exist from approval function
                  debugPrint('🔍 Technician approved, checking for user record');
                } else {
                  // Technician not approved yet - don't create user record
                  debugPrint('⚠️ Technician not approved - setting role to pending');
                  _userRole = UserRole.pending;
                  await _saveUserRole(_userRole);
                  notifyListeners();
                  return;
                }
              }
            } catch (insertError) {
              debugPrint('❌ Failed to create user record: $insertError');
            }
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
      debugPrint('🔧 Updating user name to: $newName');
      
      // Update user metadata in Supabase Auth
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            ..._user!.userMetadata ?? {},
            'full_name': newName,
          },
        ),
      );

      // Update in Supabase users table
      await SupabaseService.client
          .from('users')
          .upsert({
            'id': _user!.id,
            'email': _user!.email,
            'full_name': newName,
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

  /// Get FCM token if available
  Future<String?> _getFCMTokenIfAvailable() async {
    try {
      return FirebaseMessagingService.fcmToken;
    } catch (e) {
      debugPrint('⚠️ Could not get FCM token: $e');
      return null;
    }
  }

  /// Send FCM token to server
  Future<void> _sendFCMTokenToServer(String token, String userId) async {
    try {
      await FirebaseMessagingService.sendTokenToServer(token, userId);
    } catch (e) {
      debugPrint('⚠️ Could not send FCM token to server: $e');
    }
  }

  /// Send FCM token after login with retry logic
  /// This handles cases where Firebase might not be initialized yet
  Future<void> _sendFCMTokenAfterLogin() async {
    if (_user == null) return;
    
    // Try immediately
    try {
      final fcmToken = await _getFCMTokenIfAvailable();
      if (fcmToken != null) {
        await _sendFCMTokenToServer(fcmToken, _user!.id);
        debugPrint('✅ FCM token sent to server after login');
        return; // Success, no need to retry
      }
    } catch (e) {
      debugPrint('⚠️ Could not get FCM token immediately after login: $e');
    }
    
    // If token not available, retry after delays (Firebase might still be initializing)
    debugPrint('🔄 FCM token not available immediately, will retry...');
    
    // Retry after 2 seconds
    Future.delayed(const Duration(seconds: 2), () async {
      if (_user == null) return;
      try {
        final fcmToken = await _getFCMTokenIfAvailable();
        if (fcmToken != null) {
          await _sendFCMTokenToServer(fcmToken, _user!.id);
          debugPrint('✅ FCM token sent to server after retry (2s)');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ FCM token retry (2s) failed: $e');
      }
      
      // Retry after 5 seconds
      Future.delayed(const Duration(seconds: 3), () async {
        if (_user == null) return;
        try {
          final fcmToken = await _getFCMTokenIfAvailable();
          if (fcmToken != null) {
            await _sendFCMTokenToServer(fcmToken, _user!.id);
            debugPrint('✅ FCM token sent to server after retry (5s)');
          } else {
            debugPrint('⚠️ FCM token still not available after 5 seconds - Firebase may not be initialized');
          }
        } catch (e) {
          debugPrint('⚠️ FCM token retry (5s) failed: $e');
        }
      });
    });
  }
}
