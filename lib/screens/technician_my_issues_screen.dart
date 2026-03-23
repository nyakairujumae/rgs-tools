import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_issue.dart';
import '../providers/tool_issue_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'add_tool_issue_screen.dart';

class TechnicianMyIssuesScreen extends StatefulWidget {
  const TechnicianMyIssuesScreen({super.key});

  @override
  State<TechnicianMyIssuesScreen> createState() =>
      _TechnicianMyIssuesScreenState();
}

class _TechnicianMyIssuesScreenState
    extends State<TechnicianMyIssuesScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Open',
    'In Progress',
    'Resolved',
    'Closed'
  ];
  Timer? _refreshTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) _load();
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _load() => context.read<ToolIssueProvider>().loadIssues();

  String? get _currentUserId =>
      SupabaseService.client.auth.currentUser?.id;

  List<ToolIssue> _getMyFilteredIssues(List<ToolIssue> all) {
    final userId = _currentUserId;
    var mine = userId != null
        ? all.where((i) => i.reportedByUserId == userId).toList()
        : <ToolIssue>[];

    if (_selectedFilter != 'All') {
      mine = mine
          .where((i) =>
              i.status.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    return mine;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.errorColor;
      case 'in progress':
        return AppTheme.warningColor;
      case 'resolved':
        return AppTheme.successColor;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.error_outline;
      case 'in progress':
        return Icons.build_circle_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Consumer<ToolIssueProvider>(
        builder: (context, provider, _) {
          final issues = _getMyFilteredIssues(provider.issues);
          return Column(
            children: [
              const SizedBox(height: 12),
              _buildFilterPills(),
              const SizedBox(height: 8),
              Expanded(
                child: provider.isLoading && provider.issues.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.secondaryColor,
                        ),
                      )
                    : issues.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            color: AppTheme.secondaryColor,
                            backgroundColor: context.scaffoldBackground,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 4, 16, 120),
                              itemCount: issues.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) =>
                                  _buildIssueCard(issues[i]),
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
              builder: (_) => AddToolIssueScreen(
                onNavigateToDashboard: () => Navigator.pop(context),
              ),
            ),
          ).then((_) => _load());
        },
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Report Issue',
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
              isFiltered
                  ? Icons.filter_list_off
                  : Icons.report_problem_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No $_selectedFilter Issues' : 'No Issues Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'You have no $_selectedFilter issues.'
                  : 'Tap the button below to report an issue.',
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

  Widget _buildIssueCard(ToolIssue issue) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(issue.status);
    final priorityColor = _priorityColor(issue.priority);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showIssueDetails(issue),
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(issue.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.toolName,
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
                        issue.issueType,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
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
                      Icon(_statusIcon(issue.status),
                          size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        issue.status,
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
              issue.description,
              style: TextStyle(
                fontSize: 13,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Priority pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    issue.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today,
                    size: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  issue.ageText,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                if (issue.isResolved && issue.resolution != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle,
                      size: 11, color: AppTheme.successColor),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      issue.resolution!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.successColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (issue.assignedTo != null &&
                    !issue.isResolved) ...[
                  const Spacer(),
                  Icon(Icons.person_outline,
                      size: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(width: 3),
                  Text(
                    issue.assignedTo!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
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

  void _showIssueDetails(ToolIssue issue) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(issue.status);
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
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.report_problem,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Issue Details',
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
                    Icon(_statusIcon(issue.status),
                        size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      issue.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    if (issue.isResolved &&
                        issue.resolvedAt != null) ...[
                      const Spacer(),
                      Text(
                        'Resolved ${_formatDate(issue.resolvedAt!)}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                statusColor.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                issue.toolName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(ctx, 'Issue Type', issue.issueType),
              _detailRow(ctx, 'Priority', issue.priority),
              _detailRow(
                  ctx, 'Reported', _formatDate(issue.reportedAt)),
              if (issue.location != null)
                _detailRow(ctx, 'Location', issue.location!),
              if (issue.assignedTo != null)
                _detailRow(ctx, 'Assigned To', issue.assignedTo!),
              if (issue.estimatedCost != null)
                _detailRow(ctx, 'Est. Cost',
                    '\$${issue.estimatedCost!.toStringAsFixed(2)}'),
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
                issue.description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              if (issue.isResolved && issue.resolution != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.successColor
                            .withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.resolution!,
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
              // Attachments
              if (issue.attachments != null &&
                  issue.attachments!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.attach_file,
                        size: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Attachments (${issue.attachments!.length})',
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
                  children: issue.attachments!.map((url) {
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
                                    url,
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
                                      padding:
                                          const EdgeInsets.all(4),
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
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme
                                  .colorScheme.surfaceContainerHighest,
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
                  }).toList(),
                ),
              ],
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
