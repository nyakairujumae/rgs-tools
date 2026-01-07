import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import '../models/admin_notification.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'admin_notification_provider.dart';
import '../services/push_notification_service.dart';

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
  final String? profilePictureUrl;

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
    this.profilePictureUrl,
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
      profilePictureUrl: map['profile_picture_url'],
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
      'profile_picture_url': profilePictureUrl,
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
      final response = await _retryOperation(
        () => SupabaseService.client
            .from('pending_user_approvals')
            .select('*')
            .order('submitted_at', ascending: false),
        maxRetries: 3,
        operationName: 'loadPendingApprovals',
      );

      _pendingApprovals = (response as List)
          .map((item) => PendingApproval.fromMap(item))
          .toList();

      debugPrint('[OK] Loaded ${_pendingApprovals.length} pending approvals');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading pending approvals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry operation with exponential backoff for network errors
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    String operationName = 'operation',
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final errorString = e.toString().toLowerCase();
        
        // Check if it's a retryable error (network/connection issues)
        final isRetryable = errorString.contains('connection') ||
            errorString.contains('closed') ||
            errorString.contains('timeout') ||
            errorString.contains('network') ||
            errorString.contains('socket');
        
        if (!isRetryable || attempt >= maxRetries) {
          // Not retryable or max retries reached, throw the error
          rethrow;
        }
        
        // Calculate exponential backoff delay (1s, 2s, 4s)
        final delayMs = 1000 * (1 << (attempt - 1));
        debugPrint('⚠️ $operationName failed (attempt $attempt/$maxRetries). Retrying in ${delayMs}ms...');
        
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Failed after $maxRetries attempts');
  }

  Future<bool> approveUser(PendingApproval approval, {BuildContext? buildContext}) async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _retryOperation(
        () => SupabaseService.client.rpc('approve_pending_user', params: {
          'approval_id': approval.id,
          'reviewer_id': currentUser.id,
        }),
        maxRetries: 3,
        operationName: 'approveUser',
      );

      if (approval.profilePictureUrl != null && approval.profilePictureUrl!.isNotEmpty) {
        try {
          await SupabaseService.client
              .from('technicians')
              .update({'profile_picture_url': approval.profilePictureUrl})
              .eq('id', approval.userId);
        } catch (e) {
          debugPrint('⚠️ Failed to sync technician profile picture after approval: $e');
        }
      }

      // Create notification for admin (confirmation) - save directly to Supabase
      // This will appear in the admin notification center
      try {
        final notificationResponse = await SupabaseService.client
            .from('admin_notifications')
            .insert({
              'title': 'User Approved',
              'message': '${approval.fullName ?? approval.email} has been approved and can now access the app',
              'technician_name': approval.fullName ?? approval.email,
              'technician_email': approval.email,
              'type': NotificationType.userApproved.value,
              'is_read': false,
              'timestamp': DateTime.now().toIso8601String(),
              'data': {
                'approval_id': approval.id,
                'user_id': approval.userId,
                'approved_at': DateTime.now().toIso8601String(),
              },
            })
            .select()
            .single();
        debugPrint('✅ Created admin notification for user approval in notification center');
        debugPrint('✅ Notification ID: ${notificationResponse['id']}');
        
        // If buildContext is provided, immediately add notification to provider's list
        // This ensures it appears in the notification center without needing a reload
        if (buildContext != null) {
          try {
            final adminNotificationProvider = Provider.of<AdminNotificationProvider>(buildContext, listen: false);
            final notification = AdminNotification.fromJson(notificationResponse);
            adminNotificationProvider.addNotification(notification);
            debugPrint('✅ Added notification to AdminNotificationProvider');
          } catch (e) {
            debugPrint('⚠️ Could not add notification to provider: $e');
            // This is not critical - the notification is in the database and will appear on next reload
          }
        }
      } catch (e) {
        debugPrint('❌ Failed to create admin notification: $e');
        debugPrint('❌ Error details: ${e.toString()}');
        // Don't fail the approval if notification creation fails
      }

      // Create notification for the approved technician in notification center
      try {
        // Insert notification for the technician in technician_notifications table
        // This will appear in the notification center
        await SupabaseService.client
            .from('technician_notifications')
            .insert({
              'user_id': approval.userId,
              'title': 'Account Approved',
              'message': 'Your account has been approved! You can now access all features of the RGS app.',
              'type': 'account_approved',
              'is_read': false,
              'timestamp': DateTime.now().toIso8601String(),
              'data': {
                'approval_id': approval.id,
                'approved_at': DateTime.now().toIso8601String(),
              },
            });
        debugPrint('✅ Created technician notification for approval in notification center');
        
        // Send push notification to the approved user
        // Note: fromUserId is null here because this is a system notification (admin approved)
        try {
          await PushNotificationService.sendToUser(
            userId: approval.userId,
            title: 'Account Approved',
            body: 'Your account has been approved! You can now access all features of the RGS app.',
            data: {
              'type': 'account_approved',
              'approval_id': approval.id,
            },
          );
          debugPrint('✅ Push notification sent to approved user');
        } catch (pushError) {
          debugPrint('⚠️ Could not send push notification to approved user: $pushError');
        }
      } catch (e) {
        debugPrint('❌ Failed to create technician notification: $e');
        debugPrint('❌ Error details: ${e.toString()}');
        // Don't fail the approval if notification creation fails, but log the error
      }

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

      await _retryOperation(
        () => SupabaseService.client.rpc('reject_pending_user', params: {
          'approval_id': approvalId,
          'reviewer_id': currentUser.id,
          'reason': reason,
        }),
        maxRetries: 3,
        operationName: 'rejectUser',
      );

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
      final insertResponse = await SupabaseService.client
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
          })
          .select()
          .single();

      debugPrint('✅ Pending approval submitted successfully');
      
      // Create notification for admins in the main notification center
      try {
        final displayName = fullName ?? email;
        await SupabaseService.client
            .from('admin_notifications')
            .insert({
              'title': 'New Technician Registration',
              'message': '$displayName has requested access to the app and is awaiting approval.',
              'technician_name': displayName,
              'technician_email': email,
              'type': NotificationType.accessRequest.value,
              'is_read': false,
              'timestamp': DateTime.now().toIso8601String(),
              'data': {
                'approval_id': insertResponse['id'],
                'user_id': userId,
                'submitted_at': DateTime.now().toIso8601String(),
              },
            });
        debugPrint('✅ Created admin notification for new technician approval request');
      } catch (e) {
        debugPrint('⚠️ Failed to create admin notification for approval request: $e');
        // Don't fail the submission if notification creation fails
      }
      
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
