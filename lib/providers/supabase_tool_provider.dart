import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_name_service.dart';

class SupabaseToolProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;

  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;

  Future<void> loadTools() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await SupabaseService.client.from('tools').select().order('name');

      _tools = (response as List).map((data) => Tool.fromMap(data)).toList();
      debugPrint('✅ Loaded ${_tools.length} tools from database');
    } catch (e) {
      debugPrint('❌ Error loading tools: $e');
      // Don't clear tools on error - keep existing data
      // This prevents showing empty state if there's a temporary network issue
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tool> addTool(Tool tool) async {
    try {
      final toolMap = tool.toMap();
      debugPrint('🔍 Attempting to add tool with data: $toolMap');
      
      final response = await SupabaseService.client
          .from('tools')
          .insert(toolMap)
          .select()
          .single();

      final createdTool = Tool.fromMap(response);
      _tools.add(createdTool);
      notifyListeners();
      debugPrint('✅ Tool added successfully: ${createdTool.id}');
      
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
    try {
      debugPrint('🗑️ Provider: Deleting tool from database: $toolId');

      // Delete from database
      await SupabaseService.client.from('tools').delete().eq('id', toolId);

      debugPrint('✅ Provider: Tool deleted from database');

      // Update local state
      _tools.removeWhere((tool) => tool.id == toolId);
      debugPrint(
          '✅ Provider: Removed tool from local list. Remaining tools: ${_tools.length}');

      // Reload tools to ensure sync with database and clear any stale references
      await loadTools();
      
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
    } catch (e) {
      debugPrint('Error assigning tool: $e');
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
