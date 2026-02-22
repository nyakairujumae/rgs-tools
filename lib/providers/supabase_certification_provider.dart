import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../models/maintenance_schedule.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';

class SupabaseCertificationProvider with ChangeNotifier {
  List<Certification> _certifications = [];
  List<MaintenanceSchedule> _calibrationSchedules = [];
  List<Tool> _tools = [];
  bool _isLoading = false;
  String? _error;

  List<Certification> get certifications => _certifications;
  List<MaintenanceSchedule> get calibrationSchedules => _calibrationSchedules;
  List<Tool> get tools => _tools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calibration certs only
  List<Certification> get calibrationCerts =>
      _certifications.where((c) => c.certificationType == 'Calibration Certificate').toList();

  // Compliance certs (all types)
  List<Certification> get complianceCerts => _certifications;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseService.client;
      final results = await Future.wait([
        supabase.from('tools').select().order('name'),
        supabase.from('certifications').select().order('expiry_date', ascending: false),
        supabase.from('maintenance_schedules').select().eq('maintenance_type', 'Calibration').order('scheduled_date'),
      ]);

      _tools = (results[0] as List).map((d) => Tool.fromMap(d)).toList();
      _certifications = (results[1] as List).map((d) => Certification.fromMap(d)).toList();
      _calibrationSchedules = (results[2] as List).map((d) => MaintenanceSchedule.fromMap(d)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading certifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CERTIFICATIONS CRUD ──

  Future<Certification?> addCertification(Certification cert) async {
    try {
      final map = cert.toMap()..remove('id');
      final response = await SupabaseService.client
          .from('certifications')
          .insert(map)
          .select()
          .single();
      final created = Certification.fromMap(response);
      _certifications.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('❌ Error adding certification: $e');
      return null;
    }
  }

  Future<Certification?> updateCertification(String id, Map<String, dynamic> updates) async {
    try {
      final response = await SupabaseService.client
          .from('certifications')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      final updated = Certification.fromMap(response);
      final idx = _certifications.indexWhere((c) => c.id == id);
      if (idx >= 0) _certifications[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      debugPrint('❌ Error updating certification: $e');
      return null;
    }
  }

  Future<bool> deleteCertification(String id) async {
    try {
      await SupabaseService.client.from('certifications').delete().eq('id', id);
      _certifications.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting certification: $e');
      return false;
    }
  }

  // ── CALIBRATION SCHEDULES CRUD ──

  Future<MaintenanceSchedule?> addCalibrationSchedule(MaintenanceSchedule schedule) async {
    try {
      final map = schedule.toMap()..remove('id');
      final response = await SupabaseService.client
          .from('maintenance_schedules')
          .insert(map)
          .select()
          .single();
      final created = MaintenanceSchedule.fromMap(response);
      _calibrationSchedules.add(created);
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('❌ Error adding calibration schedule: $e');
      return null;
    }
  }

  Future<bool> deleteCalibrationSchedule(int id) async {
    try {
      await SupabaseService.client.from('maintenance_schedules').delete().eq('id', id);
      _calibrationSchedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting calibration schedule: $e');
      return false;
    }
  }
}
