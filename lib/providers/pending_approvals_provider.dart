import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class PendingApproval {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String? employeeId;
  final String? phone;
  final String? department;
  final DateTime? hireDate;
  final String status;
  final String? rejectionReason;
  final int rejectionCount;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  PendingApproval({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.employeeId,
    this.phone,
    this.department,
    this.hireDate,
    required this.status,
    this.rejectionReason,
    required this.rejectionCount,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory PendingApproval.fromMap(Map<String, dynamic> map) {
    return PendingApproval(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'],
      employeeId: map['employee_id'],
      phone: map['phone'],
      department: map['department'],
      hireDate: map['hire_date'] != null ? DateTime.parse(map['hire_date']) : null,
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      rejectionCount: map['rejection_count'] ?? 0,
      submittedAt: DateTime.parse(map['submitted_at']),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      reviewedBy: map['reviewed_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'employee_id': employeeId,
      'phone': phone,
      'department': department,
      'hire_date': hireDate?.toIso8601String(),
      'status': status,
      'rejection_reason': rejectionReason,
      'rejection_count': rejectionCount,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }
}

class PendingApprovalsProvider extends ChangeNotifier {
  List<PendingApproval> _pendingApprovals = [];
  bool _isLoading = false;
  String? _error;

  List<PendingApproval> get pendingApprovals => _pendingApprovals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _pendingApprovals.where((a) => a.status == 'pending').length;
  int get approvedCount => _pendingApprovals.where((a) => a.status == 'approved').length;
  int get rejectedCount => _pendingApprovals.where((a) => a.status == 'rejected').length;

  Future<void> loadPendingApprovals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('pending_user_approvals')
          .select('*')
          .order('submitted_at', ascending: false);

      _pendingApprovals = (response as List)
          .map((item) => PendingApproval.fromMap(item))
          .toList();

      debugPrint('✅ Loaded ${_pendingApprovals.length} pending approvals');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading pending approvals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveUser(String approvalId) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseService.client.rpc('approve_pending_user', params: {
        'approval_id': approvalId,
        'reviewer_id': currentUser.id,
      });

      // Reload the approvals
      await loadPendingApprovals();
      
      debugPrint('✅ User approved successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error approving user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectUser(String approvalId, String reason) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseService.client.rpc('reject_pending_user', params: {
        'approval_id': approvalId,
        'reviewer_id': currentUser.id,
        'reason': reason,
      });

      // Reload the approvals
      await loadPendingApprovals();
      
      debugPrint('✅ User rejected successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error rejecting user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitPendingApproval({
    required String userId,
    required String email,
    String? fullName,
    String? employeeId,
    String? phone,
    String? department,
    DateTime? hireDate,
  }) async {
    try {
      await SupabaseService.client
          .from('pending_user_approvals')
          .insert({
            'user_id': userId,
            'email': email,
            'full_name': fullName,
            'employee_id': employeeId,
            'phone': phone,
            'department': department,
            'hire_date': hireDate?.toIso8601String(),
            'status': 'pending',
          });

      debugPrint('✅ Pending approval submitted successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error submitting pending approval: $e');
      notifyListeners();
      return false;
    }
  }

  List<PendingApproval> getPendingApprovals() {
    return _pendingApprovals.where((a) => a.status == 'pending').toList();
  }

  List<PendingApproval> getApprovedApprovals() {
    return _pendingApprovals.where((a) => a.status == 'approved').toList();
  }

  List<PendingApproval> getRejectedApprovals() {
    return _pendingApprovals.where((a) => a.status == 'rejected').toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
