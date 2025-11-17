import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';

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
      final response = await SupabaseService.client
          .from('tools')
          .insert(tool.toMap())
          .select()
          .single();

      final createdTool = Tool.fromMap(response);
      _tools.add(createdTool);
      notifyListeners();
      return createdTool;
    } catch (e) {
      debugPrint('Error adding tool: $e');
      rethrow;
    }
  }

  Future<void> updateTool(Tool tool) async {
    try {
      await SupabaseService.client
          .from('tools')
          .update(tool.toMap())
          .eq('id', tool.id!);

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating tool: $e');
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
