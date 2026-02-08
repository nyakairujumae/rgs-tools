import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/approval_workflow.dart';
import '../providers/approval_workflows_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';

class ApprovalWorkflowsScreen extends StatefulWidget {
  const ApprovalWorkflowsScreen({super.key});

  @override
  State<ApprovalWorkflowsScreen> createState() => _ApprovalWorkflowsScreenState();
}

class _ApprovalWorkflowsScreenState extends State<ApprovalWorkflowsScreen> {
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;
  bool _isDisposed = false;
  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Overdue'
  ];
  final List<String> _types = [
    'All',
    RequestTypes.toolAssignment,
    RequestTypes.toolPurchase,
    RequestTypes.toolDisposal,
    RequestTypes.maintenance,
    RequestTypes.transfer,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalWorkflowsProvider>().loadWorkflows();
      // Refresh workflows every 30 seconds to catch new requests
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) {
          context.read<ApprovalWorkflowsProvider>().loadWorkflows();
        }
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 900 : double.infinity,
            ),
            child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFilterPills(),
            const SizedBox(height: 8),
            _buildTypePills(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildWorkflowsList(),
            ),
          ],
        ),
          ),
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildWorkflowsList() {
    final workflows = _getFilteredWorkflows();

    if (workflows.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ApprovalWorkflowsProvider>().loadWorkflows();
      },
      color: AppTheme.secondaryColor,
      backgroundColor: context.scaffoldBackground,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          kIsWeb ? 24 : 16,
          kIsWeb ? 16 : 12,
          kIsWeb ? 24 : 16,
          120,
        ),
        itemCount: workflows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final workflow = workflows[index];
          return _buildWorkflowCard(workflow);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: context.chatGPTInputDecoration.copyWith(
          hintText: 'Search requests, tools, or reporters...',
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: context.cardBackground,
              selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.08),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : AppTheme.getCardBorderSubtle(context),
                width: isSelected ? 1.2 : 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypePills() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedType = type);
              },
              backgroundColor: context.cardBackground,
              selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.08),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : AppTheme.getCardBorderSubtle(context),
                width: isSelected ? 1.2 : 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Pending':
        title = 'No Pending Requests';
        subtitle = 'No pending approval requests found';
        icon = Icons.pending;
        break;
      case 'Approved':
        title = 'No Approved Requests';
        subtitle = 'No approved requests found';
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        title = 'No Rejected Requests';
        subtitle = 'No rejected requests found';
        icon = Icons.cancel;
        break;
      case 'Overdue':
        title = 'No Overdue Requests';
        subtitle = 'No overdue requests found';
        icon = Icons.warning;
        break;
      default:
        title = 'No Requests Found';
        subtitle = 'No requests match the selected filters';
        icon = Icons.assignment;
    }

    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionText: null,
      onAction: null,
    );
  }

  Widget _buildWorkflowCard(ApprovalWorkflow workflow) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);
    final initial =
        workflow.title.isNotEmpty ? workflow.title[0].toUpperCase() : '?';
    final details = [
      workflow.requestType,
      workflow.requesterRole,
    ].join(' • ');

    return InkWell(
      borderRadius: radius,
      onTap: () => _viewWorkflowDetails(workflow),
      child: Container(
        decoration: context.cardDecoration.copyWith(
          borderRadius: radius,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(workflow.requestType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: _getTypeColor(workflow.requestType),
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
                        workflow.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                _buildIssueTypePill(workflow.requestType),
                _buildPriorityPill(workflow.priority),
                _buildStatusOutlineChip(workflow.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workflow.description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Requested by ${workflow.requesterName} • ${_formatDate(workflow.requestDate)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTypePill(String type) {
    return FilterChip(
      label: Text(
        type,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: false,
      onSelected: (_) {},
      showCheckmark: false,
      backgroundColor: context.cardBackground,
      selectedColor: _getTypeColor(type).withValues(alpha: 0.08),
      side: BorderSide(
        color: AppTheme.getCardBorderSubtle(context),
        width: 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelStyle: TextStyle(
        color: _getTypeColor(type),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPriorityPill(String priority) {
    final color = _getPriorityAccentColor(priority);
    return FilterChip(
      label: Text(
        priority,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      selected: false,
      onSelected: (_) {},
      showCheckmark: false,
      backgroundColor: color,
      selectedColor: color,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    final color = _getStatusColor(status);
    return FilterChip(
      label: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: false,
      onSelected: (_) {},
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      selectedColor: color.withValues(alpha: 0.08),
      side: BorderSide(
        color: color,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Color _getPriorityAccentColor(String priority) {
    switch (priority) {
      case 'Critical':
      case 'High':
        return const Color(0xFFFF4D4F);
      case 'Medium':
        return const Color(0xFFFAAD14);
      case 'Low':
        return const Color(0xFF52C41A);
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFF4D4F);
      case 'Approved':
        return const Color(0xFF52C41A);
      case 'Rejected':
        return const Color(0xFFFAAD14);
      case 'Cancelled':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  List<ApprovalWorkflow> _getFilteredWorkflows() {
    final provider = context.watch<ApprovalWorkflowsProvider>();
    var workflows = List<ApprovalWorkflow>.from(provider.workflows);

    // Filter by status
    switch (_selectedFilter) {
      case 'Pending':
        workflows = workflows.where((w) => w.isPending).toList();
        break;
      case 'Approved':
        workflows = workflows.where((w) => w.isApproved).toList();
        break;
      case 'Rejected':
        workflows = workflows.where((w) => w.isRejected).toList();
        break;
      case 'Overdue':
        workflows = workflows.where((w) => w.isOverdue).toList();
        break;
    }

    // Filter by type
    if (_selectedType != 'All') {
      workflows = workflows.where((w) => w.requestType == _selectedType).toList();
    }

    final searchTerm = _searchQuery.trim().toLowerCase();
    if (searchTerm.isNotEmpty) {
      workflows = workflows.where((issue) {
        final haystack = [
          issue.title,
          issue.description,
          issue.requesterName,
          issue.requestType,
        ].join(' ').toLowerCase();
        return haystack.contains(searchTerm);
      }).toList();
    }

    return workflows;
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: context.appBarBackground,
      elevation: 0,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: 0,
      foregroundColor: theme.colorScheme.onSurface,
      title: Text(
        'Approval Workflows',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => NavigationHelper.safePop(context),
        ),
      ),
      actions: [],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return AppTheme.primaryColor;
      case RequestTypes.toolPurchase:
        return AppTheme.secondaryColor;
      case RequestTypes.toolDisposal:
        return AppTheme.errorColor;
      case RequestTypes.maintenance:
        return AppTheme.warningColor;
      case RequestTypes.transfer:
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return Icons.person_add;
      case RequestTypes.toolPurchase:
        return Icons.shopping_cart;
      case RequestTypes.toolDisposal:
        return Icons.delete;
      case RequestTypes.maintenance:
        return Icons.build;
      case RequestTypes.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateRequestDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CreateRequestDialog(
          onRequestCreated: (workflow) {
            // Add the new workflow to the list
            setState(() {
              // In a real app, this would be saved to the database
              // For now, we'll just refresh the UI
            });
          },
        ),
      ),
    );
  }

  void _approveWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Approve Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve "${workflow.title}"?',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateWorkflowStatus(workflow, 'Approved');
              if (mounted) {
                AuthErrorHandler.showSuccessSnackBar(
                  context,
                  'Request "${workflow.title}" approved',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text('Approve'),
          ),
        ],
      );
    },
    );
  }

  void _rejectWorkflow(ApprovalWorkflow workflow) {
    final rejectionReasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reject Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this request?',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rejectionReasonController,
              decoration: context.chatGPTInputDecoration.copyWith(
                labelText: 'Rejection Reason',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () async {
              final reason = rejectionReasonController.text.trim();
              Navigator.pop(context);
              await _updateWorkflowStatus(workflow, 'Rejected', rejectionReason: reason.isEmpty ? 'No reason provided' : reason);
              if (mounted) {
                AuthErrorHandler.showErrorSnackBar(
                  context,
                  'Request "${workflow.title}" rejected',
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      );
    },
    );
  }

  Future<void> _updateWorkflowStatus(ApprovalWorkflow workflow, String newStatus, {String? rejectionReason}) async {
    final provider = context.read<ApprovalWorkflowsProvider>();
    try {
      final workflowId = workflow.id?.toString();
      if (workflowId == null) {
        throw Exception('Workflow ID is null');
      }
      
      if (newStatus == 'Approved') {
        await provider.approveWorkflow(workflowId, comments: null);
      } else if (newStatus == 'Rejected') {
        await provider.rejectWorkflow(workflowId, rejectionReason ?? 'No reason provided');
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to update workflow: $e',
        );
      }
    }
  }

  void _viewWorkflowDetails(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(workflow.requestType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(workflow.requestType),
                color: _getTypeColor(workflow.requestType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Request Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workflow.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Type', workflow.requestType),
              _buildDetailRow('Status', workflow.status),
              _buildDetailRow('Priority', workflow.priority),
              _buildDetailRow('Requester', workflow.requesterName),
              _buildDetailRow('Request Date', _formatDate(workflow.requestDate)),
              if (workflow.dueDate != null) _buildDetailRow('Due Date', _formatDate(workflow.dueDate!)),
              if (workflow.assignedTo != null) _buildDetailRow('Assigned To', workflow.assignedTo!),
              if (workflow.location != null) _buildDetailRow('Location', workflow.location!),
              if (workflow.approvedDate != null) _buildDetailRow('Approved Date', _formatDate(workflow.approvedDate!)),
              if (workflow.approvedBy != null) _buildDetailRow('Approved By', workflow.approvedBy!),
              if (workflow.rejectedDate != null) _buildDetailRow('Rejected Date', _formatDate(workflow.rejectedDate!)),
              if (workflow.rejectedBy != null) _buildDetailRow('Rejected By', workflow.rejectedBy!),
              if (workflow.rejectionReason != null) _buildDetailRow('Rejection Reason', workflow.rejectionReason!),
              const SizedBox(height: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workflow.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (workflow.isPending) ...[
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectWorkflow(workflow);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveWorkflow(workflow);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text('Approve'),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryColor,
              ),
              child: const Text('Close'),
            ),
        ],
      );
    },
    );
  }

  void _resubmitWorkflow(ApprovalWorkflow workflow) {
    AuthErrorHandler.showInfoSnackBar(
      context,
      'Resubmitting request "${workflow.title}"',
    );
  }
}

class _CreateRequestDialog extends StatefulWidget {
  final Function(ApprovalWorkflow) onRequestCreated;

  const _CreateRequestDialog({
    required this.onRequestCreated,
  });

  @override
  State<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<_CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentsController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _supplierController = TextEditingController();
  final _technicianController = TextEditingController();
  final _toolController = TextEditingController();
  final _reasonController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();

  String _selectedRequestType = RequestTypes.toolAssignment;
  String _selectedPriority = 'Medium';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  String _selectedAssignedTo = 'Manager';
  String _selectedAssignedToRole = 'Manager';

  final List<String> _requestTypes = RequestTypes.allTypes;
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _assignedToOptions = ['Manager', 'Supervisor', 'Admin', 'Maintenance Team'];
  final List<String> _assignedToRoles = ['Manager', 'Supervisor', 'Admin', 'Maintenance Supervisor'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentsController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _totalCostController.dispose();
    _supplierController.dispose();
    _technicianController.dispose();
    _toolController.dispose();
    _reasonController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: (isDesktop ? 24 : 20) + bottomInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                    minHeight: constraints.maxHeight - ((isDesktop ? 20 : 16) * 2),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: isDesktop ? 20 : 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                              height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                              decoration: context.cardDecoration,
                              child: IconButton(
                                icon: Icon(
                                  Icons.chevron_left,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create New Request',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                                      fontWeight: FontWeight.w700,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Request approvals for tools, purchases, maintenance, and more.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Request Type Selection
                              _buildRequestTypeSection(),
                              const SizedBox(height: 24),

                              // Basic Information
                              _buildBasicInfoSection(),
                              const SizedBox(height: 24),

                              // Dynamic Fields Based on Request Type
                              _buildDynamicFields(),
                              const SizedBox(height: 24),

                              // Priority and Due Date
                              _buildPriorityAndDueDateSection(),
                              const SizedBox(height: 24),

                              // Assignment Information
                              _buildAssignmentSection(),
                              const SizedBox(height: 24),

                              // Comments
                              _buildCommentsSection(),

                              const SizedBox(height: 24),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    ),
                                    child: const Text('Create Request'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return context.chatGPTInputDecoration.copyWith(
      labelText: label,
    );
  }

  Widget _buildRequestTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedRequestType,
          decoration: _buildInputDecoration('Request Type'),
          items: _requestTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRequestType = value ?? RequestTypes.toolAssignment;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          RequestTypes.typeDescriptions[_selectedRequestType] ?? '',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration('Request Title'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a request title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: _buildInputDecoration('Description'),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: _buildInputDecoration('Location'),
        ),
      ],
    );
  }

  Widget _buildDynamicFields() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return _buildToolPurchaseFields();
      case RequestTypes.toolAssignment:
        return _buildToolAssignmentFields();
      case RequestTypes.toolDisposal:
        return _buildToolDisposalFields();
      case RequestTypes.transfer:
        return _buildTransferFields();
      case RequestTypes.maintenance:
        return _buildMaintenanceFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolPurchaseFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: _buildInputDecoration('Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _unitPriceController,
                decoration: _buildInputDecoration('Unit Price (AED)'),
                keyboardType: TextInputType.number,
                onChanged: _calculateTotalCost,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _totalCostController,
          decoration: _buildInputDecoration('Total Cost (AED)'),
          keyboardType: TextInputType.number,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supplierController,
          decoration: _buildInputDecoration('Supplier'),
        ),
      ],
    );
  }

  Widget _buildToolAssignmentFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: _buildInputDecoration('Tool Name/Serial'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _technicianController,
          decoration: _buildInputDecoration('Technician Name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter technician name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildToolDisposalFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disposal Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: _buildInputDecoration('Tool Name/Serial'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          decoration: _buildInputDecoration('Disposal Reason'),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter disposal reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTransferFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: _buildInputDecoration('Tool Name/Serial'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fromLocationController,
                decoration: _buildInputDecoration('From Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter from location';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _toLocationController,
                decoration: _buildInputDecoration('To Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter to location';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaintenanceFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maintenance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: _buildInputDecoration('Tool Name/Serial'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          decoration: _buildInputDecoration('Maintenance Type/Reason'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter maintenance type or reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriorityAndDueDateSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority & Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: _buildInputDecoration('Priority'),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'Medium';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.getCardBorderSubtle(context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDueDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedAssignedTo,
                decoration: _buildInputDecoration('Assigned To'),
                items: _assignedToOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedTo = value ?? 'Manager';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedAssignedToRole,
                decoration: _buildInputDecoration('Role'),
                items: _assignedToRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedToRole = value ?? 'Manager';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _commentsController,
          decoration: _buildInputDecoration('Comments (Optional)'),
          maxLines: 3,
        ),
      ],
    );
  }

  void _calculateTotalCost(String value) {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(value) ?? 0.0;
    final total = quantity * unitPrice;
    _totalCostController.text = total.toStringAsFixed(2);
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Create the approval workflow
      final workflow = ApprovalWorkflow(
        requestType: _selectedRequestType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requesterId: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
        requesterName: 'Current User', // In a real app, get from auth
        requesterRole: 'User', // In a real app, get from auth
        status: 'Pending',
        priority: _selectedPriority,
        requestDate: DateTime.now(),
        dueDate: _selectedDueDate,
        assignedTo: _selectedAssignedTo,
        assignedToRole: _selectedAssignedToRole,
        comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        requestData: _buildRequestData(),
      );

      // Save to database
      final provider = context.read<ApprovalWorkflowsProvider>();
      await provider.createWorkflow(workflow);
      
      widget.onRequestCreated(workflow);
      Navigator.pop(context);
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Request created successfully!',
        );
      }
    }
  }

  Map<String, dynamic> _buildRequestData() {
    final data = <String, dynamic>{};
    
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        data['quantity'] = _quantityController.text;
        data['unit_price'] = _unitPriceController.text;
        data['total_cost'] = _totalCostController.text;
        data['supplier'] = _supplierController.text;
        break;
      case RequestTypes.toolAssignment:
        data['tool_name'] = _toolController.text;
        data['technician_name'] = _technicianController.text;
        break;
      case RequestTypes.toolDisposal:
        data['tool_name'] = _toolController.text;
        data['disposal_reason'] = _reasonController.text;
        break;
      case RequestTypes.transfer:
        data['tool_name'] = _toolController.text;
        data['from_location'] = _fromLocationController.text;
        data['to_location'] = _toLocationController.text;
        break;
      case RequestTypes.maintenance:
        data['tool_name'] = _toolController.text;
        data['maintenance_type'] = _reasonController.text;
        break;
    }
    
    return data;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return AppTheme.primaryColor;
      case RequestTypes.toolPurchase:
        return AppTheme.secondaryColor;
      case RequestTypes.toolDisposal:
        return AppTheme.errorColor;
      case RequestTypes.maintenance:
        return AppTheme.warningColor;
      case RequestTypes.transfer:
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return Icons.person_add;
      case RequestTypes.toolPurchase:
        return Icons.shopping_cart;
      case RequestTypes.toolDisposal:
        return Icons.delete;
      case RequestTypes.maintenance:
        return Icons.build;
      case RequestTypes.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
