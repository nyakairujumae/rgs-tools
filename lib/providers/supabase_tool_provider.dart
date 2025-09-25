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
      final response = await SupabaseService.client
          .from('tools')
          .select()
          .order('name');

      _tools = (response as List)
          .map((data) => Tool.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading tools: $e');
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
      // Add timeout to prevent hanging
      await Future.any([
        _performDeletion(toolId),
        Future.delayed(Duration(seconds: 3), () => throw Exception('Deletion timeout - please try again')),
      ]);
    } catch (e) {
      debugPrint('Error deleting tool: $e');
      rethrow;
    }
  }

  Future<void> _performDeletion(String toolId) async {
    // Simple deletion - just delete the tool directly
    // Let the database handle foreign key constraints
    await SupabaseService.client
        .from('tools')
        .delete()
        .eq('id', toolId);

    // Update local state
    _tools.removeWhere((tool) => tool.id == toolId);
    notifyListeners();
    
    debugPrint('Tool deleted successfully: $toolId');
  }


  Future<void> assignTool(String toolId, String technicianId, String assignmentType) async {
    try {
      // Update tool status and assigned_to field
      await SupabaseService.client
          .from('tools')
          .update({
            'status': 'Assigned',
            'assigned_to': technicianId
          })
          .eq('id', toolId);

      // Create assignment record
      await SupabaseService.client
          .from('assignments')
          .insert({
            'tool_id': toolId,
            'technician_id': technicianId,
            'assignment_type': assignmentType,
            'status': 'Active'
          });

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
      await SupabaseService.client
          .from('tools')
          .update({
            'status': 'Available',
            'assigned_to': null
          })
          .eq('id', toolId);

      // Update assignment status
      await SupabaseService.client
          .from('assignments')
          .update({
            'status': 'Returned',
            'actual_return_date': DateTime.now().toIso8601String()
          })
          .eq('tool_id', toolId)
          .eq('status', 'Active');

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
    return _tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0.0));
  }

  List<Tool> getToolsNeedingMaintenance() {
    return _tools.where((tool) => tool.condition == 'Maintenance Required').toList();
  }

  List<Tool> getAvailableTools() {
    return _tools.where((tool) => tool.status == 'Available').toList();
  }

  List<Tool> getAssignedTools() {
    return _tools.where((tool) => tool.status == 'Assigned').toList();
  }
}
