import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../models/tool_issue.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'add_tool_issue_screen.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';

class ToolIssuesScreen extends StatefulWidget {
  const ToolIssuesScreen({super.key});

  @override
  State<ToolIssuesScreen> createState() => _ToolIssuesScreenState();
}

class _ToolIssuesScreenState extends State<ToolIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final VoidCallback _tabListener;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Recent';

  final List<String> _filters = [
    'All',
    'Open',
    'Critical',
    'Resolved',
  ];
  final List<String> _sortOptions = ['Recent', 'Priority', 'Type', 'Age'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabListener = () {
      if (!_tabController.indexIsChanging &&
          _tabController.index >= 0 &&
          _tabController.index < _filters.length) {
        setState(() {
          _selectedFilter = _filters[_tabController.index];
        });
      }
    };
    _tabController.addListener(_tabListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolIssueProvider>().loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildFilterPills(),
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
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text('Retry'),
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
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Sign In'),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddToolIssueScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Report New Issue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
          ),
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
    final searchTerm = _searchQuery.trim().toLowerCase();
    final filteredIssues = searchTerm.isEmpty
        ? issues
        : issues.where((issue) {
            final haystack = [
              issue.toolName,
              issue.issueType,
              issue.reportedBy,
            ].join(' ').toLowerCase();
            return haystack.contains(searchTerm);
          }).toList();
    final sortedIssues = _sortIssues(filteredIssues);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return RefreshIndicator(
      onRefresh: () => context.read<ToolIssueProvider>().loadIssues(),
      color: AppTheme.secondaryColor,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16,
          isDesktop ? 20 : 16,
          isDesktop ? 24 : 16,
          120,
        ),
        itemCount: sortedIssues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final issue = sortedIssues[index];
          return _buildPremiumIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildPremiumIssueCard(ToolIssue issue) {
    final theme = Theme.of(context);
    final letter =
        issue.toolName.isNotEmpty ? issue.toolName[0].toUpperCase() : '?';
    final details = [
      '#${issue.toolId}',
      if (issue.location != null && issue.location!.isNotEmpty)
        issue.location!,
    ].join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showIssueDetails(issue),
      child: Container(
        decoration: context.cardDecoration,
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                        issue.toolName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
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
                _buildIssueTypePill(issue.issueType),
                _buildPriorityPill(issue.priority),
                _buildStatusOutlineChip(issue.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Reported by ${issue.reportedBy} • ${issue.ageText}',
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

  void _showIssueDetails(ToolIssue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
                Icons.info_outline,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Issue Details',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Close'),
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
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text('Assign'),
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
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text('Resolve'),
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
        backgroundColor: Colors.white,
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
                Icons.person_add_outlined,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Assign Issue'),
            ),
          ],
        ),
        content: TextField(
          controller: assignController,
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: 'Assign to (Admin/Technician)',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (assignController.text.trim().isNotEmpty) {
                context.read<ToolIssueProvider>().assignIssue(
                  issue.id!,
                  assignController.text.trim(),
                );
                Navigator.pop(context);
                AuthErrorHandler.showSuccessSnackBar(
                  context,
                  'Issue assigned successfully',
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
            child: const Text('Assign'),
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
        backgroundColor: Colors.white,
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
              child: Text('Resolve Issue'),
            ),
          ],
        ),
        content: TextField(
          controller: resolutionController,
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: 'Resolution details',
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Cancel'),
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
                AuthErrorHandler.showSuccessSnackBar(
                  context,
                  'Issue resolved successfully',
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
            child: const Text('Resolve'),
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

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: const Text(
        'Tool Issues',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => NavigationHelper.safePop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: context.cardDecoration,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      actions: [],
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
              showCheckmark: false,
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) {
                final targetIndex = _filters.indexOf(filter);
                if (targetIndex >= 0 && targetIndex < _tabController.length) {
                  _tabController.animateTo(targetIndex);
                }
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: context.cardBackground,
              selectedColor: AppTheme.secondaryColor.withOpacity(0.08),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.black.withOpacity(0.04),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: context.cardDecoration,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: context.chatGPTInputDecoration.copyWith(
            hintText: 'Search issues, tools, reporters...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypePill(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getIssueTypeColor(type),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    final color = _getPriorityAccentColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
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
      case 'Open':
        return const Color(0xFFFF4D4F);
      case 'In Progress':
        return const Color(0xFFFAAD14);
      case 'Resolved':
        return const Color(0xFF52C41A);
      case 'Closed':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
