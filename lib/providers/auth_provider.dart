import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../services/firebase_messaging_service.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserRole _userRole = UserRole.technician;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoggingOut = false;

  User? get user => _user;
  UserRole get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isTechnician => _userRole == UserRole.technician;
  bool get isPendingApproval => _userRole == UserRole.pending;
  bool get isLoggingOut => _isLoggingOut;
  
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

    try {
      print('🔍 Getting current session...');
      // Get current session
      final session = SupabaseService.client.auth.currentSession;
      _user = session?.user;
      print('🔍 Current user: ${_user?.email ?? "None"}');

      // Listen to auth state changes
      print('🔍 Setting up auth state listener...');
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        print('🔍 Auth state changed: ${data.session?.user?.email ?? "None"}');
        _user = data.session?.user;
        _loadUserRole();
        notifyListeners();
      });

      // Load user role if user exists
      if (_user != null) {
        print('🔍 Loading user role...');
        await _loadUserRole();
        
        // Send FCM token to server after initialization if available
        try {
          final fcmToken = await _getFCMTokenIfAvailable();
          if (fcmToken != null) {
            await _sendFCMTokenToServer(fcmToken, _user!.id);
          }
        } catch (e) {
          debugPrint('⚠️ Could not send FCM token after initialization: $e');
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

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role?.value ?? 'technician', // Default to 'technician' for new registrations
        },
      );

      if (response.user != null) {
        _user = response.user;
        
        // For technicians, create pending approval instead of user record
        if (role == UserRole.technician || role == null) {
          try {
            // Create pending approval record
            await SupabaseService.client
                .from('pending_user_approvals')
                .insert({
                  'user_id': _user!.id,
                  'email': email,
                  'full_name': fullName,
                  'status': 'pending',
                });
            
            debugPrint('✅ Pending approval created for technician: $email');
            
            // Delete any user record created by trigger (technicians shouldn't have one until approved)
            try {
              await SupabaseService.client
                  .from('users')
                  .delete()
                  .eq('id', _user!.id);
              debugPrint('✅ Removed user record for pending technician');
            } catch (deleteError) {
              debugPrint('⚠️ Could not delete user record: $deleteError');
            }
            
            // Set role to pending IMMEDIATELY (before notifyListeners)
            _userRole = UserRole.pending;
            await _saveUserRole(_userRole);
            debugPrint('✅ User role set to pending: ${_userRole.value}');
            notifyListeners(); // Notify immediately so UI can check isPendingApproval
          } catch (e) {
            debugPrint('❌ Error creating pending approval: $e');
            // Continue anyway - user is created
          }
        } else {
          // For admins, load role normally
          await _loadUserRole();
        }
      }

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin registration method
  Future<void> registerAdmin(
    String name,
    String email,
    String password,
    String position,
  ) async {
    // Validate email domain
    if (!email.endsWith('@royalgulf.ae') && !email.endsWith('@mekar.ae')) {
      throw Exception('Invalid email domain for admin registration');
    }

    await signUp(
      email: email,
      password: password,
      fullName: name,
      role: UserRole.admin,
    );
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
    // First, create the auth user with 'technician' role
    // Note: signUp will create a basic pending approval, but we need to update it with additional details
    await signUp(
      email: email,
      password: password,
      fullName: name,
      role: UserRole.technician, // Explicitly set as technician
    );
    
    // Then update the pending approval with additional details if it exists
    // OR create it if signUp didn't create one (shouldn't happen, but just in case)
    if (_user != null) {
      try {
        // Check if a pending approval already exists (created by signUp)
        final existingApproval = await SupabaseService.client
            .from('pending_user_approvals')
            .select('id')
            .eq('user_id', _user!.id)
            .eq('status', 'pending')
            .maybeSingle();
        
        if (existingApproval != null) {
          // Update existing approval with additional details
          await SupabaseService.client
              .from('pending_user_approvals')
              .update({
                'employee_id': employeeId,
                'phone': phone,
                'department': department,
                'hire_date': hireDate,
              })
              .eq('id', existingApproval['id']);
          
          debugPrint('✅ Updated existing pending approval with additional details: $email');
        } else {
          // Create new pending approval if it doesn't exist (shouldn't happen normally)
          await SupabaseService.client
              .from('pending_user_approvals')
              .insert({
                'user_id': _user!.id,
                'email': email,
                'full_name': name,
                'employee_id': employeeId,
                'phone': phone,
                'department': department,
                'hire_date': hireDate,
                'status': 'pending',
              });
          
          debugPrint('✅ Created pending approval for technician: $email');
        }
        
        // IMPORTANT: Delete any user record that might have been created by the trigger
        // Technicians should NOT have a user record until approved
        try {
          await SupabaseService.client
              .from('users')
              .delete()
              .eq('id', _user!.id);
          debugPrint('✅ Removed user record for pending technician (will be created on approval)');
        } catch (deleteError) {
          debugPrint('⚠️ Could not delete user record (might not exist): $deleteError');
        }
        
        // Set role to pending
        _userRole = UserRole.pending;
        await _saveUserRole(_userRole);
        notifyListeners();
      } catch (e) {
        debugPrint('❌ Error updating pending approval: $e');
        // Don't throw error here, user is already created
      }
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserRole();
        
        // Send FCM token to server after successful login
        try {
          final fcmToken = await _getFCMTokenIfAvailable();
          if (fcmToken != null && _user != null) {
            await _sendFCMTokenToServer(fcmToken, _user!.id);
          }
        } catch (e) {
          debugPrint('⚠️ Could not send FCM token after login: $e');
        }
        
        // Validate admin domain restrictions
        if (_userRole == UserRole.admin) {
          if (!email.endsWith('@royalgulf.ae') && !email.endsWith('@mekar.ae')) {
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
      }

      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
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
      _userRole = UserRole.technician;
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
      _userRole = UserRole.technician;
    } finally {
_isLoading = false;
      _isLoggingOut = false;
      notifyListeners();
      debugPrint('✅ AuthProvider: signOut process completed');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  String? get userEmail => _user?.email;
  String? get userId => _user?.id;
  String? get userFullName => _user?.userMetadata?['full_name'] as String?;

  Future<void> _loadUserRole() async {
    if (_user == null) {
      _userRole = UserRole.technician;
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
          final refreshResponse = await SupabaseService.client.auth.refreshSession();
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

      // Try to get role from database (online)
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          final response = await SupabaseService.client
              .from('users')
              .select('role')
              .eq('id', _user!.id)
              .single();

          if (response['role'] != null) {
            final newRole = UserRoleExtension.fromString(response['role']);
            _userRole = newRole;
            // Save role to local storage for future offline use
            await _saveUserRole(newRole);
            debugPrint('✅ User role loaded from database: ${_userRole.value}');
            notifyListeners();
            return;
          } else {
            debugPrint('⚠️ No role found in database, keeping current role: ${_userRole.value}');
            return;
          }
        } catch (e) {
          // If user record doesn't exist, check if this is a new registration
          if (e.toString().contains('0 rows')) {
            debugPrint('🔄 User record not found, checking if this is a new registration...');
            
            // Check if user has pending approval (new technician registration)
            try {
              final pendingApproval = await SupabaseService.client
                  .from('pending_user_approvals')
                  .select('status')
                  .eq('user_id', _user!.id)
                  .maybeSingle();
              
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
                .maybeSingle();
            
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
              String role = 'technician'; // Default to technician
              if (_user!.email != null && 
                  (_user!.email!.endsWith('@royalgulf.ae') || _user!.email!.endsWith('@mekar.ae'))) {
                role = 'admin';
                debugPrint('🔍 Admin domain detected, creating admin user');
              
                // Create user record for admins immediately
              await SupabaseService.client
                  .from('users')
                  .insert({
                    'id': _user!.id,
                    'email': _user!.email ?? 'user@example.com',
                    'full_name': _user!.userMetadata?['full_name'] ?? 'User',
                    'role': role,
                    'created_at': DateTime.now().toIso8601String(),
                  });
              
              _userRole = UserRoleExtension.fromString(role);
              await _saveUserRole(_userRole);
                debugPrint('✅ Created admin user with role: $role');
                notifyListeners();
                return;
              } else {
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
            // Conservative approach: only assign admin role if explicitly confirmed
            // For now, default to technician for all failed cases to prevent role mixing
            if (_userRole == UserRole.technician) {
              debugPrint('🔄 Keeping technician role as safe default');
              _userRole = UserRole.technician;
              notifyListeners();
            }
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
    _userRole = UserRole.technician;
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
}
