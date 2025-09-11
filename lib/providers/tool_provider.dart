import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/tool.dart';
import '../database/database_helper.dart';

class ToolProvider with ChangeNotifier {
  List<Tool> _tools = [];
  bool _isLoading = false;

  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;

  Future<void> loadTools() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tools',
        orderBy: 'name ASC',
      );

      _tools = List.generate(maps.length, (i) {
        return Tool.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTool(Tool tool) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('tools', tool.toMap());
      
      final newTool = tool.copyWith(id: id);
      _tools.add(newTool);
      _tools.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding tool: $e');
      rethrow;
    }
  }

  Future<void> updateTool(Tool tool) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'tools',
        tool.toMap(),
        where: 'id = ?',
        whereArgs: [tool.id],
      );

      final index = _tools.indexWhere((t) => t.id == tool.id);
      if (index != -1) {
        _tools[index] = tool;
        _tools.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating tool: $e');
      rethrow;
    }
  }

  Future<void> deleteTool(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'tools',
        where: 'id = ?',
        whereArgs: [id],
      );

      _tools.removeWhere((tool) => tool.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting tool: $e');
      rethrow;
    }
  }

  List<Tool> getToolsByCategory(String category) {
    return _tools.where((tool) => tool.category == category).toList();
  }

  List<Tool> getToolsByStatus(String status) {
    return _tools.where((tool) => tool.status == status).toList();
  }

  List<Tool> getToolsByCondition(String condition) {
    return _tools.where((tool) => tool.condition == condition).toList();
  }

  List<String> getCategories() {
    return _tools.map((tool) => tool.category).toSet().toList()..sort();
  }

  double getTotalValue() {
    return _tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0));
  }

  int getToolsNeedingMaintenance() {
    return _tools.where((tool) => 
      tool.condition == 'Poor' || tool.condition == 'Needs Repair'
    ).length;
  }
}

