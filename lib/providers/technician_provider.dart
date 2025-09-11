import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/technician.dart';
import '../database/database_helper.dart';

class TechnicianProvider with ChangeNotifier {
  List<Technician> _technicians = [];
  bool _isLoading = false;

  List<Technician> get technicians => _technicians;
  bool get isLoading => _isLoading;

  Future<void> loadTechnicians() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'technicians',
        orderBy: 'name ASC',
      );

      _technicians = List.generate(maps.length, (i) {
        return Technician.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading technicians: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTechnician(Technician technician) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('technicians', technician.toMap());
      
      final newTechnician = technician.copyWith(id: id);
      _technicians.add(newTechnician);
      _technicians.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding technician: $e');
      rethrow;
    }
  }

  Future<void> updateTechnician(Technician technician) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'technicians',
        technician.toMap(),
        where: 'id = ?',
        whereArgs: [technician.id],
      );

      final index = _technicians.indexWhere((t) => t.id == technician.id);
      if (index != -1) {
        _technicians[index] = technician;
        _technicians.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating technician: $e');
      rethrow;
    }
  }

  Future<void> deleteTechnician(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'technicians',
        where: 'id = ?',
        whereArgs: [id],
      );

      _technicians.removeWhere((technician) => technician.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting technician: $e');
      rethrow;
    }
  }

  List<Technician> getActiveTechnicians() {
    return _technicians.where((tech) => tech.status == 'Active').toList();
  }

  List<String> getDepartments() {
    return _technicians
        .map((tech) => tech.department)
        .where((dept) => dept != null && dept.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }
}

