import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_name_service.dart';
import '../services/tool_history_service.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

class SupabaseToolProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  RealtimeChannel? _toolsChannel;
  final LocalCacheService _cache = LocalCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;

  void subscribeToRealtime() {
    if (_toolsChannel != null) return;
    _toolsChannel = SupabaseService.client.channel('tools').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tools',
      callback: (_) => loadTools(),
    ).subscribe();
  }

  void unsubscribeFromRealtime() {
    _toolsChannel?.unsubscribe();
    _toolsChannel = null;
  }

  Future<void> declineAssignment(String toolId) async {
    await SupabaseService.client.from('tools').update({
      'status': 'Available',
      'assigned_to': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', toolId);
    final index = _tools.indexWhere((t) => t.id == toolId);
    if (index != -1) {
      _tools[index] = Tool.fromMap({
        ..._tools[index].toMap(),
        'status': 'Available',
        'assigned_to': null,
      });
      notifyListeners();
    }
  }

  Future<void> loadTools() async {
    _isLoading = true;
    notifyListeners();

    final isOnline = _connectivity.isOnline;

    if (isOnline) {
      try {
        final response =
            await SupabaseService.client.from('tools').select().order('name');

        _tools = (response as List).map((data) => Tool.fromMap(data)).toList();
        Logger.debug('✅ Loaded ${_tools.length} tools from Supabase');

        // Cache to SQLite in the background (mobile only)
        if (!kIsWeb) {
          unawaited(_cache.cacheTools(_tools));
        }
      } catch (e) {
        Logger.debug('❌ Error loading tools from Supabase: $e');
        // Network error — fall back to cache
        if (!kIsWeb) {
          _tools = await _cache.getCachedTools();
          Logger.debug('📦 Loaded ${_tools.length} tools from SQLite cache (network error fallback)');
        }
      }
    } else {
      // Offline — load from cache
      if (!kIsWeb) {
        _tools = await _cache.getCachedTools();
        Logger.debug('📦 Loaded ${_tools.length} tools from SQLite cache (offline)');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Tool> addTool(Tool tool) async {
    // ── Offline: queue and optimistically add to local list ──
    if (!_connectivity.isOnline && !kIsWeb) {
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final offlineTool = Tool.fromMap({...tool.toMap(), 'id': tempId});
      _tools.add(offlineTool);
      unawaited(_cache.cacheSingleTool(offlineTool));
      unawaited(_cache.queueOperation('tools', 'insert', tool.toMap()));
      notifyListeners();
      debugPrint('📦 Tool queued for sync (offline)');
      return offlineTool;
    }

    try {
      final toolMap = tool.toMap();
      debugPrint('🔍 Attempting to add tool. organization_id in map: ${toolMap['organization_id']}');
      debugPrint('🔍 Full tool map: $toolMap');

      final response = await SupabaseService.client
          .from('tools')
          .insert(toolMap)
          .select()
          .single();

      final createdTool = Tool.fromMap(response);
      _tools.add(createdTool);
      if (!kIsWeb) unawaited(_cache.cacheSingleTool(createdTool));
      notifyListeners();
      debugPrint('✅ Tool added successfully: ${createdTool.id}');

      // Record in audit trail (tool_history) so it shows in Recent Activity
      final userId = SupabaseService.client.auth.currentUser?.id;
      await ToolHistoryService.record(
        toolId: createdTool.id!,
        toolName: createdTool.name,
        action: 'Created',
        description: 'Tool added to inventory',
        performedById: userId,
        performedByRole: 'admin',
      );

      // Send push notification to admins about new tool (non-blocking)
      try {
        await PushNotificationService.sendToAdmins(
          fromUserId: null, // System notification
          title: 'New Tool Added',
          body: '${tool.name} has been added to the inventory',
          data: {
            'type': 'tool_added',
            'tool_id': createdTool.id,
            'tool_name': tool.name,
          },
        );
        debugPrint('✅ Push notification sent to admins for new tool');
      } catch (pushError) {
        debugPrint('⚠️ Could not send push notification for new tool: $pushError');
      }

      return createdTool;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding tool: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');

      // Provide more detailed error information
      String errorMessage = 'Failed to add tool';
      if (e.toString().contains('permission denied') || e.toString().contains('PGRST301')) {
        errorMessage = 'Permission denied. Please check your database policies.';
      } else if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        errorMessage = 'A tool with this serial number already exists.';
      } else if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        errorMessage = 'Database schema mismatch. Please check if all required columns exist.';
      } else if (e.toString().contains('null value') && e.toString().contains('violates not-null constraint')) {
        errorMessage = 'Required fields are missing. Please fill all required fields.';
      } else {
        errorMessage = 'Error adding tool: ${e.toString()}';
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> updateTool(Tool tool) async {
    // ── Offline: queue and update local cache ──
    if (!_connectivity.isOnline && !kIsWeb) {
      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        unawaited(_cache.cacheSingleTool(tool));
      }
      unawaited(_cache.queueOperation('tools', 'update', tool.toMap(), recordId: tool.id));
      notifyListeners();
      debugPrint('📦 Tool update queued for sync (offline)');
      return;
    }

    try {
      final updateMap = tool.toMap();
      debugPrint('🔧 [UpdateTool] Updating tool ${tool.id} with data: $updateMap');
      debugPrint('   - assignedTo: ${tool.assignedTo}');

      await SupabaseService.client
          .from('tools')
          .update(updateMap)
          .eq('id', tool.id!);

      // Reload the tool from database to ensure we have the actual saved value
      final updatedResponse = await SupabaseService.client
          .from('tools')
          .select()
          .eq('id', tool.id!)
          .single();

      final updatedTool = Tool.fromMap(updatedResponse);
      debugPrint('✅ [UpdateTool] Tool updated. Database assignedTo: ${updatedTool.assignedTo}');

      // Clear name cache for the assigned user so fresh data is fetched when other users view the tool
      if (updatedTool.assignedTo != null) {
        UserNameService.clearCacheForUser(updatedTool.assignedTo!);
      }

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = updatedTool;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [UpdateTool] Error updating tool: $e');
      rethrow;
    }
  }

  Future<void> deleteTool(String toolId) async {
    // ── Offline: queue and remove from local list ──
    if (!_connectivity.isOnline && !kIsWeb) {
      _tools.removeWhere((t) => t.id == toolId);
      unawaited(_cache.removeCachedTool(toolId));
      unawaited(_cache.queueOperation('tools', 'delete', {}, recordId: toolId));
      notifyListeners();
      debugPrint('📦 Tool delete queued for sync (offline)');
      return;
    }

    try {
      debugPrint('🗑️ Provider: Deleting tool from database: $toolId');

      final tool = getToolById(toolId);
      final toolName = tool?.name ?? toolId;

      // Delete from database
      await SupabaseService.client.from('tools').delete().eq('id', toolId);

      debugPrint('✅ Provider: Tool deleted from database');

      // Record in audit trail before we remove from local list
      final userId = SupabaseService.client.auth.currentUser?.id;
      await ToolHistoryService.record(
        toolId: toolId,
        toolName: toolName,
        action: 'Deleted',
        description: 'Tool removed from inventory',
        performedById: userId,
        performedByRole: 'admin',
      );

      // Update local state
      _tools.removeWhere((tool) => tool.id == toolId);
      if (!kIsWeb) unawaited(_cache.removeCachedTool(toolId));
      debugPrint(
          '✅ Provider: Removed tool from local list. Remaining tools: ${_tools.length}');

      // Do NOT call loadTools() - it can trigger session refresh on marginal JWT
      // and log the user out. Local state is already correct.
      notifyListeners();
      debugPrint('✅ Provider: Notified listeners after reload');
    } catch (e) {
      debugPrint('❌ Provider: Error deleting tool: $e');
      rethrow;
    }
  }

  /// Check if a tool exists in the current tools list
  bool toolExists(String toolId) {
    return _tools.any((tool) => tool.id == toolId);
  }

  /// Get a tool by ID, returns null if not found
  Tool? getToolById(String toolId) {
    try {
      return _tools.firstWhere((tool) => tool.id == toolId);
    } catch (e) {
      return null;
    }
  }

  /// Remove a tool from local list (used for immediate UI update before reload)
  void removeToolFromList(String toolId) {
    _tools.removeWhere((tool) => tool.id == toolId);
    notifyListeners();
  }

  Future<void> assignTool(
      String toolId, String technicianId, String assignmentType) async {
    // ── Offline: queue and update local state immediately ──
    if (!_connectivity.isOnline && !kIsWeb) {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Assigned',
          'assigned_to': technicianId,
        });
        unawaited(_cache.cacheSingleTool(_tools[index]));
      }
      unawaited(_cache.queueOperation(
        'tools', 'update',
        {'status': 'Assigned', 'assigned_to': technicianId, 'updated_at': DateTime.now().toIso8601String()},
        recordId: toolId,
      ));
      notifyListeners();
      debugPrint('📦 Tool assignment queued for sync (offline)');
      return;
    }

    try {
      // Update tool status and assigned_to field
      await SupabaseService.client.from('tools').update(
          {'status': 'Assigned', 'assigned_to': technicianId}).eq('id', toolId);

      // Try to create assignment record (optional - table may not exist)
      try {
        await SupabaseService.client.from('assignments').insert({
          'tool_id': toolId,
          'technician_id': technicianId,
          'assignment_type': assignmentType,
          'status': 'Active'
        });
      } catch (assignmentsError) {
        // Assignments table doesn't exist, but that's okay
        // The tool assignment is already done via the tools table
        debugPrint(
            'Assignments table not found, skipping assignment record: $assignmentsError');
      }

      // Update local tools list
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Assigned',
          'assigned_to': technicianId
        });
        notifyListeners();
      }

      // Record in audit trail
      final tool = getToolById(toolId);
      final userId = SupabaseService.client.auth.currentUser?.id;
      await ToolHistoryService.record(
        toolId: toolId,
        toolName: tool?.name ?? toolId,
        action: 'Assigned',
        description: 'Tool assigned to technician',
        newValue: technicianId,
        performedById: userId,
        performedByRole: 'admin',
      );

      // Notify the technician
      PushNotificationService.sendToUser(
        userId: technicianId,
        title: 'Tool Assigned',
        body: '${tool?.name ?? 'A tool'} has been assigned to you.',
        data: {'type': 'tool_assignment', 'tool_id': toolId},
      ).catchError((e) => debugPrint('Push to technician failed: $e'));
    } catch (e) {
      debugPrint('Error assigning tool: $e');
      rethrow;
    }
  }

  Future<void> returnTool(String toolId) async {
    // ── Offline: queue and update local state immediately ──
    if (!_connectivity.isOnline && !kIsWeb) {
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Available',
          'assigned_to': null,
        });
        unawaited(_cache.cacheSingleTool(_tools[index]));
      }
      unawaited(_cache.queueOperation(
        'tools', 'update',
        {'status': 'Available', 'assigned_to': null, 'updated_at': DateTime.now().toIso8601String()},
        recordId: toolId,
      ));
      notifyListeners();
      debugPrint('📦 Tool return queued for sync (offline)');
      return;
    }

    try {
      // Update tool status and clear assigned_to field
      await SupabaseService.client.from('tools').update(
          {'status': 'Available', 'assigned_to': null}).eq('id', toolId);

      // Try to update assignment status (optional - table may not exist)
      try {
        await SupabaseService.client
            .from('assignments')
            .update({
              'status': 'Returned',
              'actual_return_date': DateTime.now().toIso8601String()
            })
            .eq('tool_id', toolId)
            .eq('status', 'Active');
      } catch (assignmentsError) {
        // Assignments table doesn't exist, but that's okay
        // The tool return is already done via the tools table
        debugPrint(
            'Assignments table not found, skipping assignment update: $assignmentsError');
      }

      // Update local tools list
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Available',
          'assigned_to': null
        });
        notifyListeners();
      }

      // Record in audit trail
      final tool = getToolById(toolId);
      final previousTechnicianId = tool?.assignedTo;
      final userId = SupabaseService.client.auth.currentUser?.id;
      await ToolHistoryService.record(
        toolId: toolId,
        toolName: tool?.name ?? toolId,
        action: 'Returned',
        description: 'Tool returned to inventory',
        performedById: userId,
        performedByRole: 'admin',
      );

      // Notify the technician if the admin initiated the return
      if (previousTechnicianId != null && previousTechnicianId != userId) {
        PushNotificationService.sendToUser(
          userId: previousTechnicianId,
          title: 'Tool Returned',
          body: '${tool?.name ?? 'A tool'} has been returned to inventory.',
          data: {'type': 'tool_returned', 'tool_id': toolId},
        ).catchError((e) => debugPrint('Push to technician failed: $e'));
      }
    } catch (e) {
      debugPrint('Error returning tool: $e');
      rethrow;
    }
  }

  // Helper methods for UI
  List<String> getCategories() {
    final categories = _tools.map((tool) => tool.category).toSet().toList();
    categories.sort();
    return categories;
  }

  double getTotalValue() {
    return _tools.fold(0.0, (sum, tool) {
      final monetaryValue = tool.purchasePrice ?? tool.currentValue ?? 0.0;
      return sum + monetaryValue;
    });
  }

  List<Tool> getToolsNeedingMaintenance() {
    return _tools
        .where((tool) => tool.condition == 'Maintenance Required')
        .toList();
  }

  List<Tool> getAvailableTools() {
    return _tools.where((tool) => tool.status == 'Available').toList();
  }

  List<Tool> getAssignedTools() {
    return _tools.where((tool) => tool.status == 'Assigned').toList();
  }
}
