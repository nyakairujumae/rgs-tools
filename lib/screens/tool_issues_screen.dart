import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../models/tool_issue.dart';
import 'add_tool_issue_screen.dart';

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          'Tool Issues Management',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<ToolIssueProvider>().loadIssues(),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${context.watch<ToolIssueProvider>().totalIssues})'),
            Tab(text: 'Open (${context.watch<ToolIssueProvider>().openIssuesCount})'),
            Tab(text: 'Critical (${context.watch<ToolIssueProvider>().criticalIssuesCount})'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Consumer<ToolIssueProvider>(
        builder: (context, issueProvider, child) {
          if (issueProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
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
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading issues',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    issueProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => issueProvider.loadIssues(),
                        child: Text('Retry'),
                      ),
                      if (issueProvider.error!.contains('Session expired') || 
                          issueProvider.error!.contains('Please log in'))
                        SizedBox(width: 16),
                      if (issueProvider.error!.contains('Session expired') || 
                          issueProvider.error!.contains('Please log in'))
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to role selection screen
                            Navigator.pushNamedAndRemoveUntil(
                              context, 
                              '/role-selection', 
                              (route) => false
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddToolIssueScreen(),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Report New Issue'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
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
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'No issues found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'All tools are working properly!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedIssues.length,
        itemBuilder: (context, index) {
          final issue = sortedIssues[index];
          return _buildIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildIssueCard(ToolIssue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Issue type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getIssueTypeColor(issue.issueType).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIssueTypeIcon(issue.issueType),
                      color: _getIssueTypeColor(issue.issueType),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Tool name and issue type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.toolName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          issue.issueType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              
              SizedBox(height: 12),
              
              // Description
              Text(
                issue.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Footer row
              Row(
                children: [
                  // Priority
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(issue.priority).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issue.priority,
                      style: TextStyle(
                        color: _getPriorityColor(issue.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // Reported by
                  Expanded(
                    child: Text(
                      'Reported by ${issue.reportedBy}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  
                  // Age
                  Text(
                    issue.ageText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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
        title: Text('Issue Details'),
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
                _buildDetailRow('Estimated Cost', '\$${issue.estimatedCost!.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                issue.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (issue.status == 'Open')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAssignDialog(issue);
              },
              child: Text('Assign'),
            ),
          if (issue.status == 'In Progress')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDialog(issue);
              },
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

