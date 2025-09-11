import '../models/tool.dart';
import '../services/tool_service.dart';

/// Repository pattern for tool data access
/// Provides a clean abstraction layer between UI and data sources
abstract class ToolRepository {
  Future<List<Tool>> getAllTools({
    String? category,
    String? status,
    String? condition,
    String? searchQuery,
  });
  
  Future<Tool> addTool(Tool tool);
  Future<Tool> updateTool(Tool tool);
  Future<void> deleteTool(int id);
  Future<ToolStatistics> getToolStatistics();
}

/// Concrete implementation using ToolService
class ToolRepositoryImpl implements ToolRepository {
  final ToolService _toolService;

  ToolRepositoryImpl({ToolService? toolService}) 
      : _toolService = toolService ?? ToolService();

  @override
  Future<List<Tool>> getAllTools({
    String? category,
    String? status,
    String? condition,
    String? searchQuery,
  }) async {
    return await _toolService.getAllTools(
      category: category,
      status: status,
      condition: condition,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Tool> addTool(Tool tool) async {
    return await _toolService.addTool(tool);
  }

  @override
  Future<Tool> updateTool(Tool tool) async {
    return await _toolService.updateTool(tool);
  }

  @override
  Future<void> deleteTool(int id) async {
    return await _toolService.deleteTool(id);
  }

  @override
  Future<ToolStatistics> getToolStatistics() async {
    return await _toolService.getToolStatistics();
  }
}

/// Mock repository for testing
class MockToolRepository implements ToolRepository {
  final List<Tool> _tools = [];

  @override
  Future<List<Tool>> getAllTools({
    String? category,
    String? status,
    String? condition,
    String? searchQuery,
  }) async {
    var filteredTools = _tools.where((tool) {
      if (category != null && tool.category != category) return false;
      if (status != null && tool.status != status) return false;
      if (condition != null && tool.condition != condition) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return tool.name.toLowerCase().contains(query) ||
               (tool.brand?.toLowerCase().contains(query) ?? false) ||
               (tool.model?.toLowerCase().contains(query) ?? false) ||
               (tool.serialNumber?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();

    return filteredTools;
  }

  @override
  Future<Tool> addTool(Tool tool) async {
    final newTool = tool.copyWith(id: _tools.length + 1);
    _tools.add(newTool);
    return newTool;
  }

  @override
  Future<Tool> updateTool(Tool tool) async {
    final index = _tools.indexWhere((t) => t.id == tool.id);
    if (index != -1) {
      _tools[index] = tool;
      return tool;
    }
    throw Exception('Tool not found');
  }

  @override
  Future<void> deleteTool(int id) async {
    _tools.removeWhere((tool) => tool.id == id);
  }

  @override
  Future<ToolStatistics> getToolStatistics() async {
    final totalTools = _tools.length;
    final statusCounts = <String, int>{};
    double totalValue = 0.0;
    int maintenanceNeeded = 0;

    for (final tool in _tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
      totalValue += tool.currentValue ?? 0;
      if (tool.condition == 'Poor' || tool.condition == 'Needs Repair') {
        maintenanceNeeded++;
      }
    }

    return ToolStatistics(
      totalTools: totalTools,
      statusCounts: statusCounts,
      totalValue: totalValue,
      maintenanceNeeded: maintenanceNeeded,
    );
  }
}

