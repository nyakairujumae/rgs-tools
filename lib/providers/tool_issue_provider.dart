import 'package:flutter/material.dart';
import '../models/tool_issue.dart';
import '../services/supabase_service.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../services/push_notification_service.dart';

class ToolIssueProvider with ChangeNotifier {
  List<ToolIssue> _issues = [];
  bool _isLoading = false;
  String? _error;

  List<ToolIssue> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<ToolIssue> get openIssues => _issues.where((issue) => issue.isOpen).toList();
  List<ToolIssue> get inProgressIssues => _issues.where((issue) => issue.isInProgress).toList();
  List<ToolIssue> get resolvedIssues => _issues.where((issue) => issue.isResolved).toList();
  List<ToolIssue> get closedIssues => _issues.where((issue) => issue.isClosed).toList();
  
  List<ToolIssue> get criticalIssues => _issues.where((issue) => issue.isCritical).toList();
  List<ToolIssue> get highPriorityIssues => _issues.where((issue) => issue.isHighPriority).toList();
  
  List<ToolIssue> get faultyTools => _issues.where((issue) => issue.issueType == 'Faulty').toList();
  List<ToolIssue> get lostTools => _issues.where((issue) => issue.issueType == 'Lost').toList();
  List<ToolIssue> get damagedTools => _issues.where((issue) => issue.issueType == 'Damaged').toList();

  int get totalIssues => _issues.length;
  int get openIssuesCount => openIssues.length;
  int get criticalIssuesCount => criticalIssues.length;

  Future<void> loadIssues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user is authenticated
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        _error = 'Please log in to view tool issues';
        return;
      }

      // Check if session is expired
      if (session.isExpired) {
        _error = 'Session expired. Please log in again';
        return;
      }

      final response = await SupabaseService.client
          .from('tool_issues')
          .select()
          .order('reported_at', ascending: false);

      _issues = (response as List)
          .map((json) => ToolIssue.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('JWT expired') || e.toString().contains('PGRST303')) {
        _error = 'Session expired. Please log in again';
      } else if (e.toString().contains('PGRST204')) {
        _error = 'Tool issues table not found. Please contact administrator';
      } else {
        _error = 'Failed to load issues: $e';
      }
      debugPrint('Error loading tool issues: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIssue(ToolIssue issue) async {
    try {
      final response = await SupabaseService.client
          .from('tool_issues')
          .insert(issue.toJson())
          .select()
          .single();

      final newIssue = ToolIssue.fromJson(response);
      _issues.insert(0, newIssue);
      notifyListeners();

      // Create notification for admins about the new issue
      try {
        // Get technician info from the reported_by field
        final reportedByParts = issue.reportedBy.split('(');
        final technicianName = reportedByParts.isNotEmpty 
            ? reportedByParts[0].trim() 
            : issue.reportedBy;
        
        // Try to get technician email from users table
        String technicianEmail = 'Unknown';
        if (issue.reportedByUserId != null) {
          try {
            final userResponse = await SupabaseService.client
                .from('users')
                .select('email')
                .eq('id', issue.reportedByUserId!)
                .maybeSingle();
            
            if (userResponse != null && userResponse['email'] != null) {
              technicianEmail = userResponse['email'] as String;
            }
          } catch (e) {
            debugPrint('Could not fetch technician email: $e');
          }
        }

        // Create notification in Supabase using function
        await SupabaseService.client.rpc(
          'create_admin_notification',
          params: {
            'p_title': 'Issue Report',
            'p_message': '${technicianName} reported a ${issue.issueType.toLowerCase()} issue for ${issue.toolName}',
            'p_technician_name': technicianName,
            'p_technician_email': technicianEmail,
            'p_type': NotificationType.issueReport.value,
            'p_data': {
              'issue_id': newIssue.id,
              'tool_id': issue.toolId,
              'tool_name': issue.toolName,
              'issue_type': issue.issueType,
              'priority': issue.priority,
            },
          },
        );
        
        debugPrint('✅ Created notification for tool issue: ${newIssue.id}');
        
        // Send push notification to admins
        try {
          await PushNotificationService.sendToAdmins(
            title: 'Issue Report',
            body: '${technicianName} reported a ${issue.issueType.toLowerCase()} issue for ${issue.toolName}',
            data: {
              'type': 'issue_report',
              'issue_id': newIssue.id,
              'tool_id': issue.toolId,
            },
          );
          debugPrint('✅ Push notification sent to admins for tool issue');
        } catch (pushError) {
          debugPrint('⚠️ Could not send push notification for tool issue: $pushError');
        }
      } catch (notificationError) {
        // Don't fail the issue creation if notification fails
        debugPrint('⚠️ Failed to create notification for tool issue: $notificationError');
      }
    } catch (e) {
      _error = 'Failed to add issue: $e';
      debugPrint('Error adding tool issue: $e');
      rethrow;
    }
  }

  Future<void> updateIssue(ToolIssue issue) async {
    try {
      final response = await SupabaseService.client
          .from('tool_issues')
          .update(issue.toJson())
          .eq('id', issue.id!)
          .select()
          .single();

      final updatedIssue = ToolIssue.fromJson(response);
      final index = _issues.indexWhere((i) => i.id == issue.id);
      if (index != -1) {
        _issues[index] = updatedIssue;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update issue: $e';
      debugPrint('Error updating tool issue: $e');
      rethrow;
    }
  }

  Future<void> deleteIssue(String issueId) async {
    try {
      await SupabaseService.client
          .from('tool_issues')
          .delete()
          .eq('id', issueId);

      _issues.removeWhere((issue) => issue.id == issueId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete issue: $e';
      debugPrint('Error deleting tool issue: $e');
      rethrow;
    }
  }

  Future<void> resolveIssue(String issueId, String resolution, String assignedTo) async {
    try {
      final issue = _issues.firstWhere((i) => i.id == issueId);
      final updatedIssue = issue.copyWith(
        status: 'Resolved',
        resolution: resolution,
        assignedTo: assignedTo,
        resolvedAt: DateTime.now(),
      );

      await updateIssue(updatedIssue);
    } catch (e) {
      _error = 'Failed to resolve issue: $e';
      debugPrint('Error resolving tool issue: $e');
      rethrow;
    }
  }

  Future<void> assignIssue(String issueId, String assignedTo) async {
    try {
      final issue = _issues.firstWhere((i) => i.id == issueId);
      final updatedIssue = issue.copyWith(
        status: 'In Progress',
        assignedTo: assignedTo,
      );

      await updateIssue(updatedIssue);
    } catch (e) {
      _error = 'Failed to assign issue: $e';
      debugPrint('Error assigning tool issue: $e');
      rethrow;
    }
  }

  // Statistics
  Map<String, int> get issueTypeStats {
    final stats = <String, int>{};
    for (final issue in _issues) {
      stats[issue.issueType] = (stats[issue.issueType] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> get priorityStats {
    final stats = <String, int>{};
    for (final issue in _issues) {
      stats[issue.priority] = (stats[issue.priority] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> get statusStats {
    final stats = <String, int>{};
    for (final issue in _issues) {
      stats[issue.status] = (stats[issue.status] ?? 0) + 1;
    }
    return stats;
  }

  double get resolutionRate {
    if (_issues.isEmpty) return 0.0;
    final resolved = _issues.where((issue) => issue.isResolved || issue.isClosed).length;
    return (resolved / _issues.length) * 100;
  }

  double get averageResolutionTime {
    final resolvedIssues = _issues.where((issue) => issue.resolvedAt != null).toList();
    if (resolvedIssues.isEmpty) return 0.0;
    
    final totalDays = resolvedIssues.fold(0.0, (sum, issue) {
      return sum + issue.resolvedAt!.difference(issue.reportedAt).inDays;
    });
    
    return totalDays / resolvedIssues.length;
  }
}

