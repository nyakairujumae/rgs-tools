import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technician Approvals',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review and manage technician access requests',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodyLarge?.color),
                      onPressed: () {
                        context.read<PendingApprovalsProvider>().loadPendingApprovals();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradientFor(context),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
          controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey[600],
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                            const Icon(Icons.pending, size: 18),
                            const SizedBox(width: 8),
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
                            const Icon(Icons.check_circle, size: 18),
                            const SizedBox(width: 8),
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
                            const Icon(Icons.cancel, size: 18),
                            const SizedBox(width: 8),
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
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildApprovedTab(),
          _buildRejectedTab(),
        ],
                ),
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: approval.status == 'pending'
            ? Border.all(
          color: _getStatusColor(approval.status).withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(approval.status).withValues(alpha: 0.2),
                        _getStatusColor(approval.status).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                    color: _getStatusColor(approval.status).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(approval.status),
                    color: _getStatusColor(approval.status),
                    size: 28,
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
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        approval.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(approval.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(approval.status).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              approval.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(approval.status),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (approval.rejectionCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${approval.rejectionCount} rejections',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (approval.employeeId != null || approval.phone != null || approval.department != null) ...[
              SizedBox(height: 12),
              Divider(color: Colors.grey.withValues(alpha: 0.3), height: 1),
              SizedBox(height: 8),
              _buildInfoRow('Employee ID', approval.employeeId),
              if (approval.phone != null) _buildInfoRow('Phone', approval.phone),
              if (approval.department != null) _buildInfoRow('Department', approval.department),
              if (approval.hireDate != null) _buildInfoRow('Hire Date', _formatDate(approval.hireDate)),
            ],
            
            SizedBox(height: 12),
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade600, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _approveUser(approval),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Authorize',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.red, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showRejectDialog(approval),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
