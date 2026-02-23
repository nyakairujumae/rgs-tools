import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_name_service.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

class SupabaseToolProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;
  final LocalCacheService _cache = LocalCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;

  /// Subscribe to realtime changes on the tools table
  void subscribeToRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.client
        .channel('tools_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tools',
          callback: (payload) {
            Logger.debug('🔄 [Realtime] Tools table changed: ${payload.eventType}');
            loadTools();
          },
        )
        .subscribe();
    Logger.debug('✅ [Realtime] Subscribed to tools table');
  }

  /// Unsubscribe from realtime
  void unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  Future<void> loadTools() async {
    _isLoading = true;
    notifyListeners();

    final isOnline = _connectivity.isOnline;

    if (isOnline) {
      try {
        final response = await SupabaseService.client
            .from('tools')
            .select()
            .order('name')
            .limit(1000);

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
    final validationError = tool.validate();
    if (validationError != null) throw Exception(validationError);

    // Offline path: queue and optimistically update local state
    if (!_connectivity.isOnline && !kIsWeb) {
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final offlineTool = tool.copyWith(id: tempId);
      _tools.add(offlineTool);
      notifyListeners();
      await _cache.cacheSingleTool(offlineTool);
      await _cache.queueOperation('tools', 'insert', tool.toMap(), recordId: tempId);
      Logger.debug('📦 Tool queued for sync (offline): $tempId');
      return offlineTool;
    }

    try {
      final toolMap = tool.toMap();
      Logger.debug('🔍 Attempting to add tool with data: $toolMap');

      final response = await SupabaseService.client
          .from('tools')
          .insert(toolMap)
          .select()
          .single();

      final createdTool = Tool.fromMap(response);
      _tools.add(createdTool);
      notifyListeners();
      Logger.debug('✅ Tool added successfully: ${createdTool.id}');

      if (!kIsWeb) unawaited(_cache.cacheSingleTool(createdTool));

      // Fire-and-forget: send push notification (don't block add flow)
      unawaited(
        PushNotificationService.sendToAdmins(
          fromUserId: null, // System notification
          title: 'New Tool Added',
          body: '${tool.name} has been added to the inventory',
          data: {
            'type': 'tool_added',
            'tool_id': createdTool.id,
            'tool_name': tool.name,
          },
        ).then((_) => Logger.debug('✅ Push notification sent to admins for new tool'))
         .catchError((e) => Logger.debug('⚠️ Could not send push notification for new tool: $e')),
      );

      return createdTool;
    } catch (e, stackTrace) {
      Logger.debug('❌ Error adding tool: $e');
      Logger.debug('❌ Error type: ${e.runtimeType}');
      Logger.debug('❌ Stack trace: $stackTrace');

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
    final validationError = tool.validate();
    if (validationError != null) throw Exception(validationError);

    // Offline path
    if (!_connectivity.isOnline && !kIsWeb) {
      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        notifyListeners();
      }
      await _cache.cacheSingleTool(tool);
      await _cache.queueOperation('tools', 'update', tool.toMap(), recordId: tool.id);
      Logger.debug('📦 Tool update queued for sync (offline): ${tool.id}');
      return;
    }

    try {
      final updateMap = tool.toMap();
      Logger.debug('🔧 [UpdateTool] Updating tool ${tool.id} with data: $updateMap');
      Logger.debug('   - assignedTo: ${tool.assignedTo}');

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
      Logger.debug('✅ [UpdateTool] Tool updated. Database assignedTo: ${updatedTool.assignedTo}');

      if (updatedTool.assignedTo != null) {
        UserNameService.clearCacheForUser(updatedTool.assignedTo!);
      }

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = updatedTool;
        notifyListeners();
      }

      if (!kIsWeb) unawaited(_cache.cacheSingleTool(updatedTool));
    } catch (e) {
      Logger.debug('❌ [UpdateTool] Error updating tool: $e');
      rethrow;
    }
  }

  Future<void> deleteTool(String toolId) async {
    // Offline path
    if (!_connectivity.isOnline && !kIsWeb) {
      _tools.removeWhere((tool) => tool.id == toolId);
      notifyListeners();
      await _cache.removeCachedTool(toolId);
      await _cache.queueOperation('tools', 'delete', {}, recordId: toolId);
      Logger.debug('📦 Tool delete queued for sync (offline): $toolId');
      return;
    }

    try {
      Logger.debug('🗑️ Provider: Deleting tool from database: $toolId');
      await SupabaseService.client.from('tools').delete().eq('id', toolId);
      Logger.debug('✅ Provider: Tool deleted from database');

      _tools.removeWhere((tool) => tool.id == toolId);
      Logger.debug('✅ Provider: Removed tool from local list. Remaining tools: ${_tools.length}');
      notifyListeners();

      if (!kIsWeb) unawaited(_cache.removeCachedTool(toolId));
    } catch (e) {
      Logger.debug('❌ Provider: Error deleting tool: $e');
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
    try {
      // Set status to Pending Acceptance until the technician accepts
      await SupabaseService.client.from('tools').update(
          {'status': 'Pending Acceptance', 'assigned_to': technicianId}).eq('id', toolId);

      // Try to create assignment record (optional - table may not exist)
      try {
        await SupabaseService.client.from('assignments').insert({
          'tool_id': toolId,
          'technician_id': technicianId,
          'assignment_type': assignmentType,
          'status': 'Pending'
        });
      } catch (assignmentsError) {
        Logger.debug(
            'Assignments table not found, skipping assignment record: $assignmentsError');
      }

      // Update local tools list
      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Pending Acceptance',
          'assigned_to': technicianId
        });
        notifyListeners();
      }
    } catch (e) {
      Logger.debug('Error assigning tool: $e');
      rethrow;
    }
  }

  /// Technician accepts a pending tool assignment
  Future<void> acceptAssignment(String toolId) async {
    try {
      await SupabaseService.client
          .from('tools')
          .update({'status': 'Assigned'})
          .eq('id', toolId);

      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({..._tools[index].toMap(), 'status': 'Assigned'});
        notifyListeners();
      }
    } catch (e) {
      Logger.debug('Error accepting assignment: $e');
      rethrow;
    }
  }

  /// Technician declines a pending tool assignment
  Future<void> declineAssignment(String toolId) async {
    try {
      await SupabaseService.client
          .from('tools')
          .update({'status': 'Available', 'assigned_to': null})
          .eq('id', toolId);

      final index = _tools.indexWhere((t) => t.id == toolId);
      if (index != -1) {
        _tools[index] = Tool.fromMap({
          ..._tools[index].toMap(),
          'status': 'Available',
          'assigned_to': null,
        });
        notifyListeners();
      }
    } catch (e) {
      Logger.debug('Error declining assignment: $e');
      rethrow;
    }
  }

  Future<void> returnTool(String toolId) async {
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
        Logger.debug(
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
    } catch (e) {
      Logger.debug('Error returning tool: $e');
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
