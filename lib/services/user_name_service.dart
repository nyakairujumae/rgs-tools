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
      } else {
        debugPrint('⚠️ [UserName] No user found for $userId');
        // Cache "Unknown" to avoid repeated failed lookups
        _nameCache[userId] = name;
        _cacheTimestamps[userId] = DateTime.now();
      }
      
      return name;
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




