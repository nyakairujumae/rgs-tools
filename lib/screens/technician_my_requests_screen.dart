import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/approval_workflow.dart';
import '../providers/approval_workflows_provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import 'request_new_tool_screen.dart';

class TechnicianMyRequestsScreen extends StatefulWidget {
  const TechnicianMyRequestsScreen({super.key});

  @override
  State<TechnicianMyRequestsScreen> createState() =>
      _TechnicianMyRequestsScreenState();
}

class _TechnicianMyRequestsScreenState
    extends State<TechnicianMyRequestsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];
  Timer? _refreshTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyRequests();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) _loadMyRequests();
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadMyRequests() {
    context.read<ApprovalWorkflowsProvider>().loadWorkflows();
  }

  String? get _currentUserId =>
      SupabaseService.client.auth.currentUser?.id;

  List<ApprovalWorkflow> _getMyFilteredWorkflows(
      List<ApprovalWorkflow> all) {
    final userId = _currentUserId;
    var mine = userId != null
        ? all.where((w) => w.requesterId == userId).toList()
        : <ApprovalWorkflow>[];

    if (_selectedFilter != 'All') {
      mine = mine
          .where((w) =>
              w.status.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    return mine;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case RequestTypes.toolPurchase:
        return AppTheme.warningColor;
      case RequestTypes.toolAssignment:
        return AppTheme.secondaryColor;
      case RequestTypes.maintenance:
        return Colors.orange;
      case RequestTypes.toolDisposal:
        return Colors.red;
      case RequestTypes.transfer:
        return Colors.purple;
      default:
        return AppTheme.secondaryColor;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_top;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Consumer<ApprovalWorkflowsProvider>(
        builder: (context, provider, _) {
          final workflows = _getMyFilteredWorkflows(provider.workflows);
          return Column(
            children: [
              const SizedBox(height: 12),
              _buildFilterPills(),
              const SizedBox(height: 8),
              Expanded(
                child: provider.isLoading && provider.workflows.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.secondaryColor,
                        ),
                      )
                    : workflows.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async => _loadMyRequests(),
                            color: AppTheme.secondaryColor,
                            backgroundColor: context.scaffoldBackground,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 4, 16, 120),
                              itemCount: workflows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) =>
                                  _buildRequestCard(workflows[i]),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RequestNewToolScreen(),
            ),
          ).then((_) => _loadMyRequests());
        },
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) =>
                  setState(() => _selectedFilter = filter),
              backgroundColor: context.cardBackground,
              selectedColor:
                  AppTheme.secondaryColor.withValues(alpha: 0.08),
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
    final isFiltered = _selectedFilter != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.filter_list_off : Icons.assignment_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No $_selectedFilter Requests'
                  : 'No Requests Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'You have no $_selectedFilter requests.'
                  : 'Tap the button below to submit your first request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(ApprovalWorkflow workflow) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(workflow.status);
    final typeColor = _getTypeColor(workflow.requestType);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showRequestDetails(workflow),
      child: Container(
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      workflow.title.isNotEmpty
                          ? workflow.title[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workflow.requestType,
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(workflow.status),
                          size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        workflow.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              workflow.description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  _formatDate(workflow.requestDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                if (workflow.isRejected &&
                    workflow.rejectionReason != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.info_outline,
                      size: 11, color: AppTheme.errorColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      workflow.rejectionReason!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (workflow.isApproved &&
                    workflow.approvedBy != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person_outline,
                      size: 11,
                      color: AppTheme.successColor),
                  const SizedBox(width: 4),
                  Text(
                    'by ${workflow.approvedBy}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(ApprovalWorkflow workflow) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(workflow.status);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(workflow.requestType)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment,
                color: _getTypeColor(workflow.requestType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Request Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
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
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(workflow.status),
                        size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      workflow.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    if (workflow.isApproved &&
                        workflow.approvedDate != null) ...[
                      const Spacer(),
                      Text(
                        _formatDate(workflow.approvedDate!),
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor.withValues(alpha: 0.7)),
                      ),
                    ],
                    if (workflow.isRejected &&
                        workflow.rejectedDate != null) ...[
                      const Spacer(),
                      Text(
                        _formatDate(workflow.rejectedDate!),
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                workflow.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(ctx, 'Type', workflow.requestType),
              _detailRow(ctx, 'Priority', workflow.priority),
              _detailRow(ctx, 'Submitted',
                  _formatDate(workflow.requestDate)),
              if (workflow.dueDate != null)
                _detailRow(
                    ctx, 'Due Date', _formatDate(workflow.dueDate!)),
              if (workflow.approvedBy != null)
                _detailRow(ctx, 'Approved By', workflow.approvedBy!),
              if (workflow.rejectedBy != null)
                _detailRow(ctx, 'Rejected By', workflow.rejectedBy!),
              if (workflow.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.errorColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.errorColor
                            .withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejection Reason',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workflow.rejectionReason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workflow.description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              // Attachments
              Builder(builder: (context) {
                final rawUrls = workflow.requestData?['image_urls'];
                final imageUrls = rawUrls is List
                    ? rawUrls.whereType<String>().toList()
                    : <String>[];
                if (imageUrls.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.attach_file,
                            size: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'Attachments (${imageUrls.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(imageUrls.length, (i) {
                        const thumbSize = 90.0;
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      child: Image.network(
                                        imageUrls[i],
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                              child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                  size: 48),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.pop(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white,
                                              size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: thumbSize,
                            height: thumbSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrls[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                  child: Icon(Icons.broken_image,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3)),
                                ),
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : Container(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2)),
                                          ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: AppTheme.secondaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
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
            ),
          ),
        ],
      ),
    );
  }
}
