import 'package:flutter/foundation.dart';
import '../models/admin_position.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

/// Service to manage admin positions and permissions
class AdminPositionService {
  /// Get all active positions
  static Future<List<AdminPosition>> getAllPositions() async {
    try {
      final response = await SupabaseService.client
          .from('admin_positions')
          .select('*, position_permissions(*)')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => AdminPosition.fromJson(json))
          .toList();
    } catch (e) {
      Logger.debug('❌ Error loading admin positions: $e');
      return [];
    }
  }

  /// Get position by ID
  static Future<AdminPosition?> getPositionById(String positionId) async {
    try {
      final response = await SupabaseService.client
          .from('admin_positions')
          .select('*, position_permissions(*)')
          .eq('id', positionId)
          .maybeSingle();

      if (response == null) return null;
      return AdminPosition.fromJson(response);
    } catch (e) {
      Logger.debug('❌ Error loading position by ID: $e');
      return null;
    }
  }

  /// Get position by name
  static Future<AdminPosition?> getPositionByName(String positionName) async {
    try {
      final response = await SupabaseService.client
          .from('admin_positions')
          .select('*, position_permissions(*)')
          .eq('name', positionName)
          .maybeSingle();

      if (response == null) return null;
      return AdminPosition.fromJson(response);
    } catch (e) {
      Logger.debug('❌ Error loading position by name: $e');
      return null;
    }
  }

  /// Get user's position
  static Future<AdminPosition?> getUserPosition(String userId) async {
    try {
      final userResponse = await SupabaseService.client
          .from('users')
          .select('position_id')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null || userResponse['position_id'] == null) {
        return null;
      }

      return getPositionById(userResponse['position_id'] as String);
    } catch (e) {
      Logger.debug('❌ Error loading user position: $e');
      return null;
    }
  }

  /// Check if user has permission
  static Future<bool> userHasPermission(
    String userId,
    String permissionName,
  ) async {
    try {
      final position = await getUserPosition(userId);
      if (position == null) return false;
      return position.hasPermission(permissionName);
    } catch (e) {
      Logger.debug('❌ Error checking user permission: $e');
      return false;
    }
  }

  /// Update user's position
  static Future<void> updateUserPosition(String userId, String positionId) async {
    try {
      await SupabaseService.client
          .from('users')
          .update({'position_id': positionId})
          .eq('id', userId);
      
      Logger.debug('✅ Updated user position: $userId -> $positionId');
    } catch (e) {
      Logger.debug('❌ Error updating user position: $e');
      rethrow;
    }
  }
}


