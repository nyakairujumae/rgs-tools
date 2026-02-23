import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

class UserProfileService {
  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      Logger.debug('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? department,
    String? position,
    String? employeeId,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? bio,
    List<String>? skills,
    List<String>? certifications,
  }) async {
    try {
      final profileData = <String, dynamic>{};
      
      if (fullName != null) profileData['full_name'] = fullName;
      if (phoneNumber != null) profileData['phone_number'] = phoneNumber;
      if (department != null) profileData['department'] = department;
      if (position != null) profileData['position'] = position;
      if (employeeId != null) profileData['employee_id'] = employeeId;
      if (emergencyContactName != null) profileData['emergency_contact_name'] = emergencyContactName;
      if (emergencyContactPhone != null) profileData['emergency_contact_phone'] = emergencyContactPhone;
      if (address != null) profileData['address'] = address;
      if (city != null) profileData['city'] = city;
      if (state != null) profileData['state'] = state;
      if (postalCode != null) profileData['postal_code'] = postalCode;
      if (country != null) profileData['country'] = country;
      if (bio != null) profileData['bio'] = bio;
      if (skills != null) profileData['skills'] = skills;
      if (certifications != null) profileData['certifications'] = certifications;

      final response = await SupabaseService.client
          .rpc('update_user_profile', params: {
        'p_user_id': userId,
        'p_profile_data': profileData,
      });

      return response == true;
    } catch (e) {
      Logger.debug('Error updating user profile: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.debug('Error getting all users: $e');
      return [];
    }
  }

  /// Get user statistics
  static Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final response = await SupabaseService.client
          .rpc('get_user_stats')
          .single();
      
      return response;
    } catch (e) {
      Logger.debug('Error getting user stats: $e');
      return null;
    }
  }

  /// Update user role
  static Future<bool> updateUserRole(String userId, String role) async {
    try {
      await SupabaseService.client
          .from('users')
          .update({'role': role, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      
      return true;
    } catch (e) {
      Logger.debug('Error updating user role: $e');
      return false;
    }
  }

  /// Deactivate user
  static Future<bool> deactivateUser(String userId) async {
    try {
      await SupabaseService.client
          .from('users')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      
      return true;
    } catch (e) {
      Logger.debug('Error deactivating user: $e');
      return false;
    }
  }

  /// Activate user
  static Future<bool> activateUser(String userId) async {
    try {
      await SupabaseService.client
          .from('users')
          .update({'is_active': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      
      return true;
    } catch (e) {
      Logger.debug('Error activating user: $e');
      return false;
    }
  }

  /// Search users
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Sanitize query to prevent PostgREST filter injection
      final sanitized = query
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll(',', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .or('full_name.ilike.%$sanitized%,email.ilike.%$sanitized%,employee_id.ilike.%$sanitized%')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.debug('Error searching users: $e');
      return [];
    }
  }

  /// Get users by department
  static Future<List<Map<String, dynamic>>> getUsersByDepartment(String department) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('department', department)
          .order('full_name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.debug('Error getting users by department: $e');
      return [];
    }
  }

  /// Get users by role
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('role', role)
          .order('full_name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.debug('Error getting users by role: $e');
      return [];
    }
  }
}

