import '../models/tool.dart';
import '../database/database_helper.dart';

/// Service layer for tool-related business logic
/// Separates business rules from UI and data access
class ToolService {
  static final ToolService _instance = ToolService._internal();
  factory ToolService() => _instance;
  ToolService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all tools with optional filtering
  Future<List<Tool>> getAllTools({
    String? category,
    String? status,
    String? condition,
    String? searchQuery,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      List<String> conditions = [];
      
      if (category != null) {
        conditions.add('category = ?');
        whereArgs.add(category);
      }
      
      if (status != null) {
        conditions.add('status = ?');
        whereArgs.add(status);
      }
      
      if (condition != null) {
        conditions.add('condition = ?');
        whereArgs.add(condition);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('(name LIKE ? OR brand LIKE ? OR model LIKE ? OR serial_number LIKE ?)');
        String searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
      }
      
      if (conditions.isNotEmpty) {
        whereClause = 'WHERE ${conditions.join(' AND ')}';
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'tools',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
      );

      return maps.map((map) => Tool.fromMap(map)).toList();
    } catch (e) {
      throw ToolServiceException('Failed to fetch tools: $e');
    }
  }

  /// Add a new tool with validation
  Future<Tool> addTool(Tool tool) async {
    await _validateTool(tool);
    
    try {
      final db = await _dbHelper.database;
      final id = await db.insert('tools', tool.toMap());
      return tool.copyWith(id: id);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw ToolServiceException('A tool with this serial number already exists');
      }
      throw ToolServiceException('Failed to add tool: $e');
    }
  }

  /// Update an existing tool
  Future<Tool> updateTool(Tool tool) async {
    if (tool.id == null) {
      throw ToolServiceException('Tool ID is required for updates');
    }
    
    await _validateTool(tool);
    
    try {
      final db = await _dbHelper.database;
      await db.update(
        'tools',
        tool.toMap(),
        where: 'id = ?',
        whereArgs: [tool.id],
      );
      return tool;
    } catch (e) {
      throw ToolServiceException('Failed to update tool: $e');
    }
  }

  /// Delete a tool
  Future<void> deleteTool(int id) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if tool is currently in use
      final usageCheck = await db.query(
        'tool_usage',
        where: 'tool_id = ? AND check_in_date IS NULL',
        whereArgs: [id],
      );
      
      if (usageCheck.isNotEmpty) {
        throw ToolServiceException('Cannot delete tool that is currently in use');
      }
      
      await db.delete(
        'tools',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw ToolServiceException('Failed to delete tool: $e');
    }
  }

  /// Get tool statistics
  Future<ToolStatistics> getToolStatistics() async {
    try {
      final db = await _dbHelper.database;
      
      // Get total count
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM tools');
      final total = totalResult.first['count'] as int;
      
      // Get status counts
      final statusResult = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM tools 
        GROUP BY status
      ''');
      
      Map<String, int> statusCounts = {};
      for (var row in statusResult) {
        statusCounts[row['status'] as String] = row['count'] as int;
      }
      
      // Get total value
      final valueResult = await db.rawQuery('SELECT SUM(current_value) as total FROM tools');
      final totalValue = (valueResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Get maintenance needed count
      final maintenanceResult = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM tools 
        WHERE condition IN ('Poor', 'Needs Repair')
      ''');
      final maintenanceNeeded = maintenanceResult.first['count'] as int;
      
      return ToolStatistics(
        totalTools: total,
        statusCounts: statusCounts,
        totalValue: totalValue,
        maintenanceNeeded: maintenanceNeeded,
      );
    } catch (e) {
      throw ToolServiceException('Failed to get tool statistics: $e');
    }
  }

  /// Validate tool data
  Future<void> _validateTool(Tool tool) async {
    if (tool.name.trim().isEmpty) {
      throw ToolServiceException('Tool name is required');
    }
    
    if (tool.category.trim().isEmpty) {
      throw ToolServiceException('Tool category is required');
    }
    
    if (tool.purchasePrice != null && tool.purchasePrice! < 0) {
      throw ToolServiceException('Purchase price cannot be negative');
    }
    
    if (tool.currentValue != null && tool.currentValue! < 0) {
      throw ToolServiceException('Current value cannot be negative');
    }
    
    // Check for duplicate serial number
    if (tool.serialNumber != null && tool.serialNumber!.isNotEmpty) {
      final existing = await getAllTools();
      final duplicate = existing.where((t) => 
        t.serialNumber == tool.serialNumber && t.id != tool.id
      ).isNotEmpty;
      
      if (duplicate) {
        throw ToolServiceException('A tool with this serial number already exists');
      }
    }
  }
}

/// Tool statistics data class
class ToolStatistics {
  final int totalTools;
  final Map<String, int> statusCounts;
  final double totalValue;
  final int maintenanceNeeded;

  ToolStatistics({
    required this.totalTools,
    required this.statusCounts,
    required this.totalValue,
    required this.maintenanceNeeded,
  });
}

/// Custom exception for tool service errors
class ToolServiceException implements Exception {
  final String message;
  ToolServiceException(this.message);
  
  @override
  String toString() => 'ToolServiceException: $message';
}

