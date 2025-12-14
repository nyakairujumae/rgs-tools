import 'package:flutter/material.dart';
import '../models/approval_workflow.dart';
import '../services/supabase_service.dart';

class ApprovalWorkflowsProvider with ChangeNotifier {
  List<ApprovalWorkflow> _workflows = [];
  bool _isLoading = false;
  String? _error;

  List<ApprovalWorkflow> get workflows => _workflows;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _workflows.where((w) => w.isPending).length;
  int get approvedCount => _workflows.where((w) => w.isApproved).length;
  int get rejectedCount => _workflows.where((w) => w.isRejected).length;

  Future<void> loadWorkflows() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('approval_workflows')
          .select()
          .order('request_date', ascending: false);

      _workflows = (response as List)
          .map((data) => ApprovalWorkflow.fromMap(data))
          .toList();

      debugPrint('✅ Loaded ${_workflows.length} approval workflows from database');
      debugPrint('📊 Workflow types: ${_workflows.map((w) => w.requestType).toSet().join(", ")}');
      debugPrint('📊 Workflow statuses: ${_workflows.map((w) => w.status).toSet().join(", ")}');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading approval workflows: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      // Keep existing workflows on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWorkflow(ApprovalWorkflow workflow) async {
    try {
      final response = await SupabaseService.client
          .from('approval_workflows')
          .insert(workflow.toMap())
          .select()
          .single();

      final newWorkflow = ApprovalWorkflow.fromMap(response);
      _workflows.insert(0, newWorkflow);
      notifyListeners();
      debugPrint('✅ Created approval workflow: ${workflow.title}');
    } catch (e) {
      debugPrint('❌ Error creating approval workflow: $e');
      rethrow;
    }
  }

  Future<void> approveWorkflow(String workflowId, {String? comments}) async {
    try {
      // Use the database function to approve
      await SupabaseService.client.rpc('approve_workflow', params: {
        'workflow_id': workflowId,
        'approver_comments': comments ?? '',
      });

      // Reload workflows to get updated data
      await loadWorkflows();
      debugPrint('✅ Approved workflow: $workflowId');
    } catch (e) {
      debugPrint('❌ Error approving workflow: $e');
      rethrow;
    }
  }

  Future<void> rejectWorkflow(String workflowId, String rejectionReason) async {
    try {
      // Use the database function to reject
      await SupabaseService.client.rpc('reject_workflow', params: {
        'workflow_id': workflowId,
        'rejection_reason': rejectionReason,
      });

      // Reload workflows to get updated data
      await loadWorkflows();
      debugPrint('✅ Rejected workflow: $workflowId');
    } catch (e) {
      debugPrint('❌ Error rejecting workflow: $e');
      rethrow;
    }
  }

  Future<void> updateWorkflow(ApprovalWorkflow workflow) async {
    try {
      if (workflow.id == null) {
        throw Exception('Workflow ID is null');
      }
      await SupabaseService.client
          .from('approval_workflows')
          .update(workflow.toMap())
          .eq('id', workflow.id.toString());

      final index = _workflows.indexWhere((w) => w.id == workflow.id);
      if (index != -1) {
        _workflows[index] = workflow;
        notifyListeners();
      }
      debugPrint('✅ Updated approval workflow: ${workflow.title}');
    } catch (e) {
      debugPrint('❌ Error updating approval workflow: $e');
      rethrow;
    }
  }
}

