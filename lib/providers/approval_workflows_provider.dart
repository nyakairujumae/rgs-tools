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
      debugPrint('🔍 Loading approval workflows from database...');
      final response = await SupabaseService.client
          .from('approval_workflows')
          .select()
          .order('request_date', ascending: false);

      debugPrint('🔍 Raw response from database: ${response.length} items');
      
      _workflows = (response as List)
          .map((data) {
            try {
              return ApprovalWorkflow.fromMap(data);
            } catch (e) {
              debugPrint('❌ Error parsing workflow: $e');
              debugPrint('❌ Problematic data: $data');
              rethrow;
            }
          })
          .toList();

      debugPrint('✅ Loaded ${_workflows.length} approval workflows from database');
      if (_workflows.isNotEmpty) {
        debugPrint('📊 Workflow types: ${_workflows.map((w) => w.requestType).toSet().join(", ")}');
        debugPrint('📊 Workflow statuses: ${_workflows.map((w) => w.status).toSet().join(", ")}');
        debugPrint('📊 Sample workflow IDs: ${_workflows.take(3).map((w) => w.id).join(", ")}');
      } else {
        debugPrint('⚠️ No workflows found in database');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading approval workflows: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      // Keep existing workflows on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWorkflow(ApprovalWorkflow workflow) async {
    try {
      final workflowMap = workflow.toMap(includeId: false);
      debugPrint('🔍 Creating approval workflow with data: $workflowMap');
      
      final response = await SupabaseService.client
          .from('approval_workflows')
          .insert(workflowMap)
          .select()
          .single();

      final newWorkflow = ApprovalWorkflow.fromMap(response);
      _workflows.insert(0, newWorkflow);
      notifyListeners();
      debugPrint('✅ Created approval workflow: ${workflow.title} (ID: ${newWorkflow.id})');
    } catch (e) {
      debugPrint('❌ Error creating approval workflow: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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
      final workflowMap = workflow.toMap(includeId: false);
      await SupabaseService.client
          .from('approval_workflows')
          .update(workflowMap)
          .eq('id', workflow.id!);

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

