import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../utils/logger.dart';

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
        Logger.debug('✅ [UserName] Cache hit for $userId: ${_nameCache[userId]}');
        return _nameCache[userId]!;
      } else {
        // Cache expired, remove it
        _nameCache.remove(userId);
        _cacheTimestamps.remove(userId);
      }
    }

    try {
      // First try: technicians table by user_id (assignedTo stores auth user ID when badging)
      // Technicians table typically has permissive RLS for reading (needed for dropdowns, lists),
      // so other technicians can see who has a shared tool.
      try {
        final technicianResponse = await SupabaseService.client
            .from('technicians')
            .select('name, email, user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (technicianResponse != null) {
          final techName = technicianResponse['name'] as String?;
          if (techName != null && techName.trim().isNotEmpty) {
            _nameCache[userId] = techName;
            _cacheTimestamps[userId] = DateTime.now();
            Logger.debug('✅ [UserName] Found name in technicians table for $userId: $techName');
            return techName;
          }
          final email = technicianResponse['email'] as String?;
          if (email != null && email.isNotEmpty) {
            final fallback = email.split('@').first;
            _nameCache[userId] = fallback;
            _cacheTimestamps[userId] = DateTime.now();
            return fallback;
          }
        }
      } catch (techError) {
        Logger.debug('⚠️ [UserName] Error querying technicians table: $techError');
      }

      // Second try: users table (may be blocked by RLS for other users on some setups)
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
          final email = userResponse['email'] as String?;
          if (email != null && email.isNotEmpty) {
            name = email.split('@').first;
          }
        }
        if (name != 'Unknown') {
          _nameCache[userId] = name;
          _cacheTimestamps[userId] = DateTime.now();
          Logger.debug('✅ [UserName] Fetched and cached name for $userId: $name');
          return name;
        }
      }

      // Third try: technicians by id (in case assignedTo sometimes stores technician.id)
      try {
        final techByIdResponse = await SupabaseService.client
            .from('technicians')
            .select('name')
            .eq('id', userId)
            .maybeSingle();
        if (techByIdResponse != null) {
          final techName = techByIdResponse['name'] as String?;
          if (techName != null && techName.trim().isNotEmpty) {
            _nameCache[userId] = techName;
            _cacheTimestamps[userId] = DateTime.now();
            Logger.debug('✅ [UserName] Found name in technicians by id for $userId: $techName');
            return techName;
          }
        }
      } catch (_) {}

      // If all lookups failed
      Logger.debug('⚠️ [UserName] No user found for $userId in users or technicians table');
      // Don't cache "Unknown" - allow retries in case user is added later
      return 'Unknown';
    } catch (e) {
      Logger.debug('❌ [UserName] Error fetching user name for $userId: $e');
      return 'Unknown';
    }
  }

  /// Batch fetch user names for multiple IDs in a single query.
  /// Returns a map of userId → name. Uncached IDs are fetched in bulk.
  static Future<Map<String, String>> getUserNames(List<String> userIds) async {
    final result = <String, String>{};
    final uncached = <String>[];

    for (final id in userIds.toSet()) {
      if (_nameCache.containsKey(id)) {
        final ts = _cacheTimestamps[id];
        if (ts != null && DateTime.now().difference(ts) < _cacheExpiry) {
          result[id] = _nameCache[id]!;
          continue;
        }
      }
      uncached.add(id);
    }

    if (uncached.isEmpty) return result;

    try {
      // Batch query technicians by user_id
      final techRows = await SupabaseService.client
          .from('technicians')
          .select('user_id, name, email')
          .inFilter('user_id', uncached);

      final found = <String>{};
      for (final row in (techRows as List)) {
        final uid = row['user_id'] as String?;
        if (uid == null) continue;
        final name = row['name'] as String?;
        final email = row['email'] as String?;
        final resolved = (name != null && name.trim().isNotEmpty)
            ? name
            : (email != null && email.isNotEmpty ? email.split('@').first : null);
        if (resolved != null) {
          result[uid] = resolved;
          _nameCache[uid] = resolved;
          _cacheTimestamps[uid] = DateTime.now();
          found.add(uid);
        }
      }

      // Fetch remaining from users table
      final remaining = uncached.where((id) => !found.contains(id)).toList();
      if (remaining.isNotEmpty) {
        final userRows = await SupabaseService.client
            .from('users')
            .select('id, full_name, email')
            .inFilter('id', remaining);

        for (final row in (userRows as List)) {
          final uid = row['id'] as String?;
          if (uid == null) continue;
          final fullName = row['full_name'] as String?;
          final email = row['email'] as String?;
          final resolved = (fullName != null && fullName.trim().isNotEmpty)
              ? fullName
              : (email != null && email.isNotEmpty ? email.split('@').first : null);
          if (resolved != null) {
            result[uid] = resolved;
            _nameCache[uid] = resolved;
            _cacheTimestamps[uid] = DateTime.now();
          }
        }
      }
    } catch (e) {
      Logger.debug('❌ [UserName] Batch fetch error: $e');
    }

    // Fill in 'Unknown' for any still-missing IDs
    for (final id in userIds) {
      result.putIfAbsent(id, () => 'Unknown');
    }
    return result;
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
    Logger.debug('🗑️ [UserName] Cache cleared');
  }

  /// Clear cache for a specific user
  static void clearCacheForUser(String userId) {
    _nameCache.remove(userId);
    _cacheTimestamps.remove(userId);
    Logger.debug('🗑️ [UserName] Cache cleared for $userId');
  }
}




