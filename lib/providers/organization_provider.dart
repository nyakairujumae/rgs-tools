import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Holds the current tenant's org config: industry, worker labels,
/// departments, and tool categories. Loaded once after login.
/// Used to drive dynamic dropdowns and UI labels across the app.
class OrganizationProvider extends ChangeNotifier {
  String _orgId = '';
  String _orgName = '';
  String _industry = 'general';
  String _workerLabel = 'Technician';
  String _workerLabelPlural = 'Technicians';
  String? _logoUrl;
  List<_NamedItem> _departments = [];
  List<_NamedItem> _toolCategories = [];
  bool _isLoaded = false;

  String get orgId => _orgId;
  String get orgName => _orgName;
  String get industry => _industry;
  String get workerLabel => _workerLabel;
  String get workerLabelPlural => _workerLabelPlural;
  String? get logoUrl => _logoUrl;
  bool get isLoaded => _isLoaded;

  /// Dynamic icon based on the organisation's industry.
  IconData get toolsIcon => _toolsIconForIndustry(_industry);

  static IconData _toolsIconForIndustry(String industry) {
    switch (industry) {
      case 'hvac':
        return Icons.ac_unit;
      case 'electrical':
        return Icons.bolt;
      case 'plumbing':
        return Icons.water_drop;
      case 'construction':
        return Icons.construction;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.build;
    }
  }

  List<String> get departments => _departments.map((d) => d.name).toList();
  List<String> get toolCategories => _toolCategories.map((c) => c.name).toList();

  /// Fetch org config + departments + tool categories from Supabase.
  Future<void> loadOrganization(String orgId) async {
    if (orgId.isEmpty) return;
    _orgId = orgId;
    try {
      // Fetch org details
      final org = await SupabaseService.client
          .from('organizations')
          .select('name, industry, worker_label, worker_label_plural, logo_url')
          .eq('id', orgId)
          .maybeSingle();

      if (org != null) {
        _orgName = (org['name'] as String?) ?? '';
        _industry = (org['industry'] as String?) ?? 'general';
        _workerLabel = (org['worker_label'] as String?) ?? 'Technician';
        _workerLabelPlural = (org['worker_label_plural'] as String?) ?? 'Technicians';
        _logoUrl = org['logo_url'] as String?;
      }

      // Fetch departments
      final depts = await SupabaseService.client
          .from('organization_departments')
          .select('id, name')
          .eq('organization_id', orgId)
          .order('sort_order', ascending: true);

      _departments = (depts as List)
          .map((d) => _NamedItem(id: d['id'] as String, name: d['name'] as String))
          .toList();

      // Fetch tool categories
      final cats = await SupabaseService.client
          .from('organization_tool_categories')
          .select('id, name')
          .eq('organization_id', orgId)
          .order('sort_order', ascending: true);

      _toolCategories = (cats as List)
          .map((c) => _NamedItem(id: c['id'] as String, name: c['name'] as String))
          .toList();

      _isLoaded = true;
      Logger.debug('✅ OrganizationProvider: loaded org=$_industry, depts=${_departments.length}, cats=${_toolCategories.length}');
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: failed to load org config: $e');
      // Fall back to defaults — app still works
      _isLoaded = true;
    }
    notifyListeners();
  }

  /// Clear on logout.
  void clear() {
    _orgId = '';
    _orgName = '';
    _industry = 'general';
    _workerLabel = 'Technician';
    _workerLabelPlural = 'Technicians';
    _logoUrl = null;
    _departments = [];
    _toolCategories = [];
    _isLoaded = false;
    notifyListeners();
  }

  // ── Departments ────────────────────────────────────────────────────────────

  Future<void> addDepartment(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _orgId.isEmpty) return;
    try {
      final result = await SupabaseService.client
          .from('organization_departments')
          .insert({
            'organization_id': _orgId,
            'name': trimmed,
            'sort_order': _departments.length,
          })
          .select('id, name')
          .single();
      _departments.add(_NamedItem(id: result['id'] as String, name: result['name'] as String));
      notifyListeners();
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: addDepartment error: $e');
      rethrow;
    }
  }

  Future<void> deleteDepartment(String name) async {
    final item = _departments.where((d) => d.name == name).firstOrNull;
    if (item == null) return;
    try {
      await SupabaseService.client
          .from('organization_departments')
          .delete()
          .eq('id', item.id);
      _departments.removeWhere((d) => d.id == item.id);
      notifyListeners();
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: deleteDepartment error: $e');
      rethrow;
    }
  }

  // ── Tool Categories ────────────────────────────────────────────────────────

  Future<void> addToolCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _orgId.isEmpty) return;
    try {
      final result = await SupabaseService.client
          .from('organization_tool_categories')
          .insert({
            'organization_id': _orgId,
            'name': trimmed,
            'sort_order': _toolCategories.length,
          })
          .select('id, name')
          .single();
      _toolCategories.add(_NamedItem(id: result['id'] as String, name: result['name'] as String));
      notifyListeners();
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: addToolCategory error: $e');
      rethrow;
    }
  }

  Future<void> deleteToolCategory(String name) async {
    final item = _toolCategories.where((c) => c.name == name).firstOrNull;
    if (item == null) return;
    try {
      await SupabaseService.client
          .from('organization_tool_categories')
          .delete()
          .eq('id', item.id);
      _toolCategories.removeWhere((c) => c.id == item.id);
      notifyListeners();
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: deleteToolCategory error: $e');
      rethrow;
    }
  }

  // ── Worker Label ───────────────────────────────────────────────────────────

  Future<void> updateWorkerLabel(String label, String plural) async {
    if (_orgId.isEmpty) return;
    try {
      await SupabaseService.client.rpc(
        'update_organization_worker_label',
        params: {
          'p_org_id': _orgId,
          'p_worker_label': label.trim(),
          'p_worker_label_plural': plural.trim(),
        },
      );
      _workerLabel = label.trim();
      _workerLabelPlural = plural.trim();
      notifyListeners();
    } catch (e) {
      Logger.debug('⚠️ OrganizationProvider: updateWorkerLabel error: $e');
      rethrow;
    }
  }
}

class _NamedItem {
  final String id;
  final String name;
  const _NamedItem({required this.id, required this.name});
}
