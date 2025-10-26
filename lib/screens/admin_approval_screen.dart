import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/rgs_logo.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendingApprovalsProvider>().loadPendingApprovals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const RGSLogo(),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending, size: 18),
                  SizedBox(width: 8),
                  Consumer<PendingApprovalsProvider>(
                    builder: (context, provider, child) {
                      final count = provider.pendingCount;
                      return Text('Pending${count > 0 ? ' ($count)' : ''}');
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 18),
                  SizedBox(width: 8),
                  Consumer<PendingApprovalsProvider>(
                    builder: (context, provider, child) {
                      final count = provider.approvedCount;
                      return Text('Authorized${count > 0 ? ' ($count)' : ''}');
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 18),
                  SizedBox(width: 8),
                  Consumer<PendingApprovalsProvider>(
                    builder: (context, provider, child) {
                      final count = provider.rejectedCount;
                      return Text('Rejected${count > 0 ? ' ($count)' : ''}');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<PendingApprovalsProvider>().loadPendingApprovals();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildApprovedTab(),
          _buildRejectedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return Consumer<PendingApprovalsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          );
        }

        final pendingApprovals = provider.getPendingApprovals();

        if (pendingApprovals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No Users Awaiting Authorization',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'New technician registrations will appear here for authorization',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingApprovals.length,
          itemBuilder: (context, index) {
            final approval = pendingApprovals[index];
            return _buildApprovalCard(approval, true);
          },
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return Consumer<PendingApprovalsProvider>(
      builder: (context, provider, child) {
        final approvedApprovals = provider.getApprovedApprovals();

        if (approvedApprovals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No Authorized Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Authorized technician registrations will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvedApprovals.length,
          itemBuilder: (context, index) {
            final approval = approvedApprovals[index];
            return _buildApprovalCard(approval, false);
          },
        );
      },
    );
  }

  Widget _buildRejectedTab() {
    return Consumer<PendingApprovalsProvider>(
      builder: (context, provider, child) {
        final rejectedApprovals = provider.getRejectedApprovals();

        if (rejectedApprovals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No Rejected Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rejected technician registrations will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rejectedApprovals.length,
          itemBuilder: (context, index) {
            final approval = rejectedApprovals[index];
            return _buildApprovalCard(approval, false);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(dynamic approval, bool showActions) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(approval.status).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(approval.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getStatusIcon(approval.status),
                    color: _getStatusColor(approval.status),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.fullName ?? 'Unknown User',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        approval.email,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(approval.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              approval.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(approval.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (approval.rejectionCount > 0) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${approval.rejectionCount} rejections',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (approval.employeeId != null || approval.phone != null || approval.department != null) ...[
              SizedBox(height: 16),
              Divider(color: Colors.grey.withValues(alpha: 0.3)),
              SizedBox(height: 8),
              _buildInfoRow('Employee ID', approval.employeeId),
              if (approval.phone != null) _buildInfoRow('Phone', approval.phone),
              if (approval.department != null) _buildInfoRow('Department', approval.department),
              if (approval.hireDate != null) _buildInfoRow('Hire Date', _formatDate(approval.hireDate)),
            ],
            
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                SizedBox(width: 8),
                Text(
                  'Submitted: ${_formatDateTime(approval.submittedAt)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            if (approval.reviewedAt != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[400]),
                  SizedBox(width: 8),
                  Text(
                    'Reviewed: ${_formatDateTime(approval.reviewedAt!)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            
            if (approval.rejectionReason != null) ...[
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      approval.rejectionReason!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (showActions) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveUser(approval),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Authorize'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(approval),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null) return SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveUser(dynamic approval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Authorize User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to authorize ${approval.fullName ?? approval.email} as a technician?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Authorize'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<PendingApprovalsProvider>();
      final success = await provider.approveUser(approval.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User authorized successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to authorize user: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(dynamic approval) {
    _rejectionReasonController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Reject User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${approval.fullName ?? approval.email}?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300]),
            ),
            SizedBox(height: 16),
            Text(
              'Reason for rejection:',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Enter reason for rejection...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            if (approval.rejectionCount >= 2) ...[
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is the 3rd rejection. The user account will be deleted.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_rejectionReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a reason for rejection'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _rejectUser(approval, _rejectionReasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectUser(dynamic approval, String reason) async {
    final provider = context.read<PendingApprovalsProvider>();
    final success = await provider.rejectUser(approval.id, reason);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User rejected successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject user: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
