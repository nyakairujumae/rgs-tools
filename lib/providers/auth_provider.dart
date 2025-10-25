import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
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
  bool get isLoggingOut => _isLoggingOut;

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
          'role': role?.value ?? 'technician',
        },
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserRole();
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
          retryCount++;
          debugPrint('❌ Error loading user role (attempt $retryCount/$maxRetries): $e');
          
          if (retryCount >= maxRetries) {
            debugPrint('❌ Max retries reached, keeping current role: ${_userRole.value}');
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
}
