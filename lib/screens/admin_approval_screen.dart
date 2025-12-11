import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/admin_notification_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/navigation_helper.dart';
import '../utils/responsive_helper.dart';
import '../utils/auth_error_handler.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendingApprovalsProvider>().loadPendingApprovals();
    });
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: context.cardDecoration,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      text:
                          'Pending (${context.watch<PendingApprovalsProvider>().pendingCount})',
                    ),
                    Tab(
                      text:
                          'Authorized (${context.watch<PendingApprovalsProvider>().approvedCount})',
                    ),
                    Tab(
                      text:
                          'Rejected (${context.watch<PendingApprovalsProvider>().rejectedCount})',
                    ),
                  ],
                ),
              ),
            ),
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
    );
  }

  Widget _buildPendingTab() {
    return Consumer<PendingApprovalsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.secondary,
              ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                SizedBox(height: 16),
                Text(
                  'No Users Awaiting Authorization',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'New technician registrations will appear here for authorization',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                SizedBox(height: 16),
                Text(
                  'No Authorized Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Authorized technician registrations will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                SizedBox(height: 16),
                Text(
                  'No Rejected Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rejected technician registrations will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: context.cardDecoration,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: context.chatGPTInputDecoration.copyWith(
            hintText: 'Search registrations...',
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.55),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: const Text(
        'Authorize Users',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: context.cardDecoration,
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Colors.black87,
            ),
            onPressed: () => NavigationHelper.safePop(context),
            splashRadius: 24,
          ),
        ),
      ),
      actions: [],
    );
  }

  Widget _buildApprovalCard(PendingApproval approval, bool showActions) {
    final theme = Theme.of(context);
    final displayName = approval.fullName?.trim().isNotEmpty == true
        ? approval.fullName!.trim()
        : approval.email;
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (approval.email.isNotEmpty ? approval.email[0].toUpperCase() : '?');
    final detailPieces = [
      if (approval.department?.trim().isNotEmpty == true)
        approval.department!.trim(),
      if (approval.employeeId?.trim().isNotEmpty == true)
        'ID ${approval.employeeId!.trim()}',
    ];
    final detailText = detailPieces.join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: context.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval.email,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                    if (detailText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detailText,
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (approval.department?.trim().isNotEmpty == true)
                _buildDepartmentPill(approval.department!.trim()),
              _buildSeverityPill(approval.rejectionCount),
              _buildStatusOutlineChip(approval.status),
            ],
          ),
          if (approval.employeeId != null ||
              approval.phone != null ||
              approval.department != null ||
              approval.hireDate != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: theme.colorScheme.onSurface.withOpacity(0.04),
              height: 1,
              thickness: 0.5,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Employee ID', approval.employeeId),
            if (approval.phone != null) _buildInfoRow('Phone', approval.phone),
            if (approval.department != null)
              _buildInfoRow('Department', approval.department),
            if (approval.hireDate != null)
              _buildInfoRow('Hire Date', _formatDate(approval.hireDate!)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Text(
                'Submitted: ${_formatDateTime(approval.submittedAt)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (approval.reviewedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reviewed: ${_formatDateTime(approval.reviewedAt!)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (approval.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason:',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveUser(approval),
                    icon: const Icon(
                      Icons.check,
                      size: 18,
                    ),
                    label: const Text(
                      'Authorize',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(approval),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Reject',
                      style:
                          TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundColor: Colors.red,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentPill(String department) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 0.5,
        ),
      ),
      child: Text(
        department,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSeverityPill(int rejectionCount) {
    final color = _getSeverityColor(rejectionCount);
    final label = _getSeverityLabel(rejectionCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _formatStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getSeverityLabel(int rejectionCount) {
    if (rejectionCount >= 2) return 'High';
    if (rejectionCount == 1) return 'Medium';
    return 'Low';
  }

  Color _getSeverityColor(int rejectionCount) {
    if (rejectionCount >= 2) return const Color(0xFFFF4D4F);
    if (rejectionCount == 1) return const Color(0xFFFAAD14);
    return const Color(0xFF52C41A);
  }

  String _formatStatusLabel(String value) {
    if (value.isEmpty) return value;
    final normalized = value.toLowerCase();
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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

  Future<void> _approveUser(PendingApproval approval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Authorize User',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to authorize ${approval.fullName ?? approval.email} as a technician?',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
      final success = await provider.approveUser(approval, buildContext: context);

      if (success && mounted) {
        await context.read<SupabaseTechnicianProvider>().loadTechnicians();
        await context.read<AuthProvider>().initialize();
        // Reload notifications to show the new approval notification
        await context.read<AdminNotificationProvider>().loadNotifications();
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'User authorized successfully',
        );
      } else if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to authorize user: ${provider.error}',
        );
      }
    }
  }

  void _showRejectDialog(dynamic approval) {
    _rejectionReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Reject User',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${approval.fullName ?? approval.email}?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
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
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: context.chatGPTInputDecoration.copyWith(
                hintText: 'Enter reason for rejection...',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1.4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
            if (approval.rejectionCount >= 2) ...[
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 0.5,
                  ),
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
                AuthErrorHandler.showErrorSnackBar(
                  context,
                  'Please enter a reason for rejection',
                );
                return;
              }

              Navigator.pop(context);
              await _rejectUser(
                  approval, _rejectionReasonController.text.trim());
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
