import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserRole _userRole = UserRole.technician;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  UserRole get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _userRole == UserRole.admin;
  bool get isTechnician => _userRole == UserRole.technician;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current session
      final session = SupabaseService.client.auth.currentSession;
      _user = session?.user;

      // Listen to auth state changes
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        _loadUserRole();
        notifyListeners();
      });

      // Load user role if user exists
      if (_user != null) {
        await _loadUserRole();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
        emailRedirectTo: null, // Disable email confirmation redirect
      );

      // If user is immediately confirmed (email confirmation disabled), set as current user
      if (response.user != null && response.session != null) {
        _user = response.user;
        await _loadUserRole();
      } else if (response.user != null) {
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
    notifyListeners();

    try {
      await SupabaseService.client.auth.signOut();
      _user = null;
      _userRole = UserRole.technician; // Reset to default role
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    if (_user == null) return;

    try {
      // First try to get role from user metadata
      final roleFromMetadata = _user?.userMetadata?['role'] as String?;
      if (roleFromMetadata != null) {
        _userRole = UserRoleExtension.fromString(roleFromMetadata);
        return;
      }

      // If not in metadata, try to get from users table in Supabase
      final response = await SupabaseService.client
          .from('users')
          .select('role')
          .eq('id', _user!.id)
          .single();

      if (response['role'] != null) {
        _userRole = UserRoleExtension.fromString(response['role']);
      } else {
        // Default to technician for security
        _userRole = UserRole.technician;
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
      // Default to technician for security
      _userRole = UserRole.technician;
    }
  }

  Future<void> updateUserRole(UserRole newRole) async {
    if (_user == null) return;

    try {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user role: $e');
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
