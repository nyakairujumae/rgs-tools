import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

class SupabaseTechnicianProvider with ChangeNotifier {
  List<Technician> _technicians = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;
  final LocalCacheService _cache = LocalCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<Technician> get technicians => _technicians;
  bool get isLoading => _isLoading;

  /// Subscribe to realtime changes on the technicians table
  void subscribeToRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.client
        .channel('technicians_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'technicians',
          callback: (payload) {
            Logger.debug('🔄 [Realtime] Technicians table changed: ${payload.eventType}');
            loadTechnicians();
          },
        )
        .subscribe();
    Logger.debug('✅ [Realtime] Subscribed to technicians table');
  }

  /// Unsubscribe from realtime
  void unsubscribeFromRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  Future<void> loadTechnicians() async {
    _isLoading = true;
    notifyListeners();

    final isOnline = _connectivity.isOnline;

    if (isOnline) {
      try {
        final response = await SupabaseService.client
            .from('technicians')
            .select()
            .order('name')
            .limit(1000);

        final techniciansList = (response as List)
            .map((data) => Technician.fromMap(data))
            .toList();

        _technicians = techniciansList;
        Logger.debug('✅ Loaded ${_technicians.length} technicians from Supabase');

        // Cache to SQLite in the background (mobile only)
        if (!kIsWeb) {
          unawaited(_cache.cacheTechnicians(_technicians));
        }
      } catch (e) {
        Logger.debug('❌ Error loading technicians from Supabase: $e');
        // Network error — fall back to cache
        if (!kIsWeb) {
          _technicians = await _cache.getCachedTechnicians();
          Logger.debug('📦 Loaded ${_technicians.length} technicians from SQLite cache (network error fallback)');
        }
      }
    } else {
      // Offline — load from cache
      if (!kIsWeb) {
        _technicians = await _cache.getCachedTechnicians();
        Logger.debug('📦 Loaded ${_technicians.length} technicians from SQLite cache (offline)');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTechnician(Technician technician, {String? userId}) async {
    try {
      final technicianMap = technician.toMap();

      // Add user_id if provided (links technician to auth account)
      if (userId != null) {
        technicianMap['user_id'] = userId;
      }

      final response = await SupabaseService.client
          .from('technicians')
          .insert(technicianMap)
          .select()
          .single();

      _technicians.add(Technician.fromMap(response));
      notifyListeners();
    } catch (e) {
      Logger.debug('Error adding technician: $e');
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
      Logger.debug('Error updating technician: $e');
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
      Logger.debug('Error deleting technician: $e');
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
      Logger.debug('Error loading active technicians: $e');
      return [];
    }
  }

  // Synchronous version for UI use
  List<Technician> getActiveTechniciansSync() {
    return _technicians.where((technician) => technician.status == 'Active').toList();
  }

  /// Get technician name by id or user_id.
  /// assignedTo stores auth user ID when technicians badge shared tools,
  /// so we match both tech.id and tech.userId.
  String? getTechnicianNameById(String? idOrUserId) {
    if (idOrUserId == null || idOrUserId.isEmpty) return null;
    for (final tech in _technicians) {
      if (tech.id == idOrUserId || tech.userId == idOrUserId) {
        return tech.name;
      }
    }
    return null;
  }
}
