import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';

class SupabaseTechnicianProvider with ChangeNotifier {
  List<Technician> _technicians = [];
  bool _isLoading = false;

  List<Technician> get technicians => _technicians;
  bool get isLoading => _isLoading;

  Future<void> loadTechnicians() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('technicians')
          .select()
          .order('name');

      final techniciansList = (response as List)
          .map((data) {
            final tech = Technician.fromMap(data);
            // Debug: Log profile picture status
            if (tech.profilePictureUrl != null && tech.profilePictureUrl!.isNotEmpty) {
              debugPrint('✅ ${tech.name}: profile_picture_url = ${tech.profilePictureUrl}');
            } else {
              debugPrint('⚠️ ${tech.name}: No profile_picture_url in database');
            }
            return tech;
          })
          .toList();

      _technicians = techniciansList;
      debugPrint('✅ Loaded ${_technicians.length} technicians');
    } catch (e) {
      debugPrint('❌ Error loading technicians: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTechnician(Technician technician) async {
    try {
      final response = await SupabaseService.client
          .from('technicians')
          .insert(technician.toMap())
          .select()
          .single();

      _technicians.add(Technician.fromMap(response));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding technician: $e');
      rethrow;
    }
  }

  Future<void> updateTechnician(Technician technician) async {
    try {
      await SupabaseService.client
          .from('technicians')
          .update(technician.toMap())
          .eq('id', technician.id!);

      final index = _technicians.indexWhere((t) => t.id == technician.id);
      if (index != -1) {
        _technicians[index] = technician;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating technician: $e');
      rethrow;
    }
  }

  Future<void> deleteTechnician(String technicianId) async {
    try {
      await SupabaseService.client
          .from('technicians')
          .delete()
          .eq('id', technicianId);

      _technicians.removeWhere((technician) => technician.id == technicianId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting technician: $e');
      rethrow;
    }
  }

  Future<List<Technician>> getActiveTechnicians() async {
    try {
      final response = await SupabaseService.client
          .from('technicians')
          .select()
          .eq('status', 'Active')
          .order('name');

      return (response as List)
          .map((data) => Technician.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading active technicians: $e');
      return [];
    }
  }

  // Synchronous version for UI use
  List<Technician> getActiveTechniciansSync() {
    return _technicians.where((technician) => technician.status == 'Active').toList();
  }

  // Get technician name by ID (returns UUID if not found, for backwards compatibility)
  String? getTechnicianNameById(String? technicianId) {
    if (technicianId == null) return null;
    try {
      final technician = _technicians.firstWhere(
        (tech) => tech.id == technicianId,
        orElse: () => Technician(id: null, name: technicianId), // Fallback to ID if not found
      );
      return technician.id == null ? technicianId : technician.name;
    } catch (e) {
      // If not found, return the ID (might be a name from old data)
      return technicianId;
    }
  }
}
