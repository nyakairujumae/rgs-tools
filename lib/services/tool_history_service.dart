import 'package:flutter/foundation.dart';
import '../models/tool_history.dart';
import 'supabase_service.dart';
import 'user_name_service.dart';

/// Service for recording and fetching tool movement history.
class ToolHistoryService {
  static final _client = SupabaseService.client;

  /// Record a history entry. Call after tool updates (badge, release, assign, etc.).
  static Future<void> record({
    required String toolId,
    required String toolName,
    required String action,
    required String description,
    String? oldValue,
    String? newValue,
    String? performedById,
    String? performedByName,
    String? performedByRole,
    String? location,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      String? performedBy = performedByName;
      if (performedBy == null && performedById != null) {
        performedBy = await UserNameService.getUserName(performedById);
      }

      await _client.from('tool_history').insert({
        'tool_id': toolId,
        'tool_name': toolName,
        'action': action,
        'description': description,
        'old_value': oldValue,
        'new_value': newValue,
        'performed_by': performedBy,
        'performed_by_id': performedById,
        'performed_by_role': performedByRole ?? 'Unknown',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'location': location,
        'notes': notes,
        'metadata': metadata,
      });
      debugPrint('✅ Tool history recorded: $action for $toolName');
    } catch (e, st) {
      debugPrint('⚠️ Failed to record tool history: $e\n$st');
      // Don't rethrow - history is non-critical; tool update already succeeded
    }
  }

  /// Fetch history for a single tool.
  static Future<List<ToolHistory>> getHistoryForTool(String toolId) async {
    try {
      final res = await _client
          .from('tool_history')
          .select()
          .eq('tool_id', toolId)
          .order('timestamp', ascending: false);
      return (res as List)
          .map((e) => ToolHistory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching tool history: $e');
      return [];
    }
  }

  /// Fetch all tool history (for All Tool History screen).
  static Future<List<ToolHistory>> getAllHistory({
    String? toolIdFilter,
    String? actionFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('tool_history').select();

      if (toolIdFilter != null && toolIdFilter.isNotEmpty) {
        query = query.eq('tool_id', toolIdFilter);
      }
      if (actionFilter != null && actionFilter.isNotEmpty) {
        query = query.eq('action', actionFilter);
      }
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final res = await query.order('timestamp', ascending: false).limit(limit);
      debugPrint('📋 tool_history rows returned: ${(res as List).length}');
      return (res as List)
          .map((e) => ToolHistory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      debugPrint('❌ Error fetching all tool history: $e\n$st');
      return [];
    }
  }

  /// Fetch history visible to a technician.
  ///
  /// Includes:
  /// - actions performed by this technician
  /// - actions where this technician appears in old/new value transitions
  /// - actions for tools currently assigned to this technician
  static Future<List<ToolHistory>> getHistoryForTechnician(
    String technicianUserId, {
    int limit = 200,
  }) async {
    try {
      final assignedToolsRes = await _client
          .from('tools')
          .select('id')
          .eq('assigned_to', technicianUserId);

      final assignedToolIds = (assignedToolsRes as List)
          .map((e) => (e as Map)['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      var query = _client
          .from('tool_history')
          .select()
          .or(
            'performed_by_id.eq.$technicianUserId,old_value.eq.$technicianUserId,new_value.eq.$technicianUserId',
          );

      if (assignedToolIds.isNotEmpty) {
        final escapedToolIds =
            assignedToolIds.map((id) => '"$id"').join(',');
        query = query.or('tool_id.in.($escapedToolIds)');
      }

      final res = await query.order('timestamp', ascending: false).limit(limit);

      return (res as List)
          .map((e) => ToolHistory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching technician-scoped tool history: $e');
      return [];
    }
  }
}
