import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../models/tool_issue.dart';
import '../theme/app_theme.dart';
import 'add_tool_issue_screen.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_helper.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';

class ToolIssuesScreen extends StatefulWidget {
  const ToolIssuesScreen({super.key});

  @override
  State<ToolIssuesScreen> createState() => _ToolIssuesScreenState();
}

class _ToolIssuesScreenState extends State<ToolIssuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';

  final List<String> _filters = ['All', 'Open', 'In Progress', 'Resolved', 'Critical'];
  final List<String> _sortOptions = ['Recent', 'Priority', 'Type', 'Age'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolIssueProvider>().loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                      ),
                      onPressed: () => NavigationHelper.safePop(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Expanded(
                    child: Text(
                      'Tool Issues',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                      ),
                      onPressed: () => context.read<ToolIssueProvider>().loadIssues(),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardSurfaceColor(context),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'All (${context.watch<ToolIssueProvider>().totalIssues})'),
                  Tab(text: 'Open (${context.watch<ToolIssueProvider>().openIssuesCount})'),
                  Tab(text: 'Critical (${context.watch<ToolIssueProvider>().criticalIssuesCount})'),
                  const Tab(text: 'Resolved'),
                ],
              ),
            ),
            Expanded(
              child: Consumer2<ToolIssueProvider, ConnectivityProvider>(
                builder: (context, issueProvider, connectivityProvider, child) {
                  final isOffline = !connectivityProvider.isOnline;
                  
                  if (isOffline && !issueProvider.isLoading) {
                    return OfflineListSkeleton(
                      itemCount: 5,
                      itemHeight: 120,
                      message: 'You are offline. Showing cached issues.',
                    );
                  }
                  
                  if (issueProvider.isLoading) {
                    return ListSkeletonLoader(
                      itemCount: 5,
                      itemHeight: 120,
                    );
                  }
                  if (issueProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading issues',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              issueProvider.error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () => issueProvider.loadIssues(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.secondaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Retry'),
                              ),
                              if (issueProvider.error!.contains('Session expired') || 
                                  issueProvider.error!.contains('Please log in'))
                                const SizedBox(width: 16),
                              if (issueProvider.error!.contains('Session expired') || 
                                  issueProvider.error!.contains('Please log in'))
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context, 
                                      '/role-selection', 
                                      (route) => false
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text('Sign In'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIssuesList(issueProvider.issues),
                      _buildIssuesList(issueProvider.openIssues),
                      _buildIssuesList(issueProvider.criticalIssues),
                      _buildIssuesList(issueProvider.resolvedIssues),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddToolIssueScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Report New Issue'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _buildIssuesList(List<ToolIssue> issues) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No issues found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All tools are working properly!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort issues based on selected sort option
    final sortedIssues = _sortIssues(issues);

    return RefreshIndicator(
      onRefresh: () => context.read<ToolIssueProvider>().loadIssues(),
      color: AppTheme.secondaryColor,
      child: ListView.builder(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        itemCount: sortedIssues.length,
        itemBuilder: (context, index) {
          final issue = sortedIssues[index];
          return _buildIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildIssueCard(ToolIssue issue) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Issue type icon
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
                    decoration: BoxDecoration(
                      color: _getIssueTypeColor(issue.issueType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                    ),
                    child: Icon(
                      _getIssueTypeIcon(issue.issueType),
                      color: _getIssueTypeColor(issue.issueType),
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Tool name and issue type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.toolName,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                        Text(
                          issue.issueType,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                            color: _getIssueTypeColor(issue.issueType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status chip
                  _buildStatusChip(issue.status),
                ],
              ),
              
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              
              // Description
              Text(
                issue.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              
              // Footer row
              Row(
                children: [
                  // Priority
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, 10),
                      vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(issue.priority).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                    ),
                    child: Text(
                      issue.priority,
                      style: TextStyle(
                        color: _getPriorityColor(issue.priority),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  
                  // Reported by
                  Expanded(
                    child: Text(
                      'Reported by ${issue.reportedBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  
                  // Age
                  Text(
                    issue.ageText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Open':
        color = Colors.red;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showIssueDetails(ToolIssue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Issue Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tool', issue.toolName),
              _buildDetailRow('Type', issue.issueType),
              _buildDetailRow('Priority', issue.priority),
              _buildDetailRow('Status', issue.status),
              _buildDetailRow('Reported By', issue.reportedBy),
              _buildDetailRow('Reported At', _formatDateTime(issue.reportedAt)),
              if (issue.assignedTo != null)
                _buildDetailRow('Assigned To', issue.assignedTo!),
              if (issue.resolvedAt != null)
                _buildDetailRow('Resolved At', _formatDateTime(issue.resolvedAt!)),
              if (issue.resolution != null)
                _buildDetailRow('Resolution', issue.resolution!),
              if (issue.location != null)
                _buildDetailRow('Location', issue.location!),
              if (issue.estimatedCost != null)
                _buildDetailRow('Estimated Cost', CurrencyFormatter.formatCurrency(issue.estimatedCost!)),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
            ),
            child: Text('Close'),
          ),
          if (issue.status == 'Open')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAssignDialog(issue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Assign'),
            ),
          if (issue.status == 'In Progress')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDialog(issue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Resolve'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(ToolIssue issue) {
    final assignController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Issue'),
        content: TextField(
          controller: assignController,
          decoration: InputDecoration(
            labelText: 'Assign to (Admin/Technician)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (assignController.text.trim().isNotEmpty) {
                context.read<ToolIssueProvider>().assignIssue(
                  issue.id!,
                  assignController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Issue assigned successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(ToolIssue issue) {
    final resolutionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve Issue'),
        content: TextField(
          controller: resolutionController,
          decoration: InputDecoration(
            labelText: 'Resolution details',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (resolutionController.text.trim().isNotEmpty) {
                context.read<ToolIssueProvider>().resolveIssue(
                  issue.id!,
                  resolutionController.text.trim(),
                  issue.assignedTo ?? 'Admin',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Issue resolved successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter options
            Text('Filter by Status:'),
            SizedBox(height: 8),
            ..._filters.map((filter) => RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            )),
            
            Divider(),
            
            // Sort options
            Text('Sort by:'),
            SizedBox(height: 8),
            ..._sortOptions.map((sort) => RadioListTile<String>(
              title: Text(sort),
              value: sort,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  List<ToolIssue> _sortIssues(List<ToolIssue> issues) {
    switch (_selectedSort) {
      case 'Priority':
        return List.from(issues)..sort((a, b) => _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority)));
      case 'Type':
        return List.from(issues)..sort((a, b) => a.issueType.compareTo(b.issueType));
      case 'Age':
        return List.from(issues)..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      case 'Recent':
      default:
        return List.from(issues)..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    }
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'Critical': return 4;
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 0;
    }
  }

  Color _getIssueTypeColor(String type) {
    switch (type) {
      case 'Faulty': return Colors.red;
      case 'Lost': return Colors.orange;
      case 'Damaged': return Colors.purple;
      case 'Missing Parts': return Colors.blue;
      case 'Other': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getIssueTypeIcon(String type) {
    switch (type) {
      case 'Faulty': return Icons.error;
      case 'Lost': return Icons.search_off;
      case 'Damaged': return Icons.build;
      case 'Missing Parts': return Icons.inventory_2;
      case 'Other': return Icons.help_outline;
      default: return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.yellow[700]!;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

