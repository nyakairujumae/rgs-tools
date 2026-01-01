import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Service to fetch and cache user names from the users table
class UserNameService {
  static final Map<String, String> _nameCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Fetch user name from users table by user ID
  /// Uses caching to avoid repeated database calls
  static Future<String> getUserName(String userId) async {
    // Check cache first
    if (_nameCache.containsKey(userId)) {
      final timestamp = _cacheTimestamps[userId];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        debugPrint('✅ [UserName] Cache hit for $userId: ${_nameCache[userId]}');
        return _nameCache[userId]!;
      } else {
        // Cache expired, remove it
        _nameCache.remove(userId);
        _cacheTimestamps.remove(userId);
      }
    }

    try {
      // First try: Query users table
      final userResponse = await SupabaseService.client
          .from('users')
          .select('full_name, email')
          .eq('id', userId)
          .maybeSingle();
      
      String name = 'Unknown';
      
      if (userResponse != null) {
        final fullName = userResponse['full_name'] as String?;
        if (fullName != null && fullName.trim().isNotEmpty) {
          name = fullName;
        } else {
          // Fallback to email if no full_name
          final email = userResponse['email'] as String?;
          if (email != null && email.isNotEmpty) {
            name = email.split('@').first;
          }
        }
        
        // Cache the result
        _nameCache[userId] = name;
        _cacheTimestamps[userId] = DateTime.now();
        debugPrint('✅ [UserName] Fetched and cached name for $userId: $name');
        return name;
      }
      
      // Second try: Query technicians table by user_id (if user_id column exists)
      debugPrint('⚠️ [UserName] User not found in users table, trying technicians table by user_id...');
      try {
        final technicianResponse = await SupabaseService.client
            .from('technicians')
            .select('name, email, user_id')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (technicianResponse != null) {
          final techName = technicianResponse['name'] as String?;
          if (techName != null && techName.trim().isNotEmpty) {
            name = techName;
            _nameCache[userId] = name;
            _cacheTimestamps[userId] = DateTime.now();
            debugPrint('✅ [UserName] Found name in technicians table for $userId: $name');
            return name;
          }
        }
      } catch (techError) {
        debugPrint('⚠️ [UserName] Error querying technicians table: $techError');
        // If user_id column doesn't exist, that's okay - continue
      }
      
      // If all lookups failed
      debugPrint('⚠️ [UserName] No user found for $userId in users or technicians table');
      // Don't cache "Unknown" - allow retries in case user is added later
      return 'Unknown';
    } catch (e) {
      debugPrint('❌ [UserName] Error fetching user name for $userId: $e');
      return 'Unknown';
    }
  }

  /// Get first name from full name
  static String getFirstName(String fullName) {
    if (fullName.trim().isEmpty) return fullName;
    final parts = fullName.trim().split(RegExp(r"\s+"));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  /// Clear the cache (useful when user data is updated)
  static void clearCache() {
    _nameCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ [UserName] Cache cleared');
  }

  /// Clear cache for a specific user
  static void clearCacheForUser(String userId) {
    _nameCache.remove(userId);
    _cacheTimestamps.remove(userId);
    debugPrint('🗑️ [UserName] Cache cleared for $userId');
  }
}




