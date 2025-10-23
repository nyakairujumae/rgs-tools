import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/technician.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../theme/app_theme.dart';
import 'add_technician_screen.dart';

class TechnicianDetailScreen extends StatefulWidget {
  final Technician technician;

  const TechnicianDetailScreen({super.key, required this.technician});

  @override
  State<TechnicianDetailScreen> createState() => _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState extends State<TechnicianDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load related data
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
          widget.technician.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTechnicianScreen(technician: widget.technician),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Tools'),
            Tab(text: 'Issues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildToolsTab(),
          _buildIssuesTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(),
          SizedBox(height: 24),
          
          // Contact Information
          _buildInfoCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildInfoRow(Icons.badge, 'Employee ID', widget.technician.employeeId),
              _buildInfoRow(Icons.phone, 'Phone', widget.technician.phone),
              _buildInfoRow(Icons.email, 'Email', widget.technician.email),
            ],
          ),
          SizedBox(height: 16),
          
          // Employment Details
          _buildInfoCard(
            title: 'Employment Details',
            icon: Icons.work,
            children: [
              _buildInfoRow(Icons.business, 'Department', widget.technician.department),
              _buildInfoRow(Icons.calendar_today, 'Hire Date', widget.technician.hireDate),
              _buildInfoRow(Icons.access_time, 'Created', widget.technician.createdAt),
            ],
          ),
          SizedBox(height: 16),
          
          // Status Information
          _buildInfoCard(
            title: 'Status Information',
            icon: Icons.info,
            children: [
              _buildStatusRow(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: widget.technician.status == 'Active' ? Colors.green : Colors.grey,
            backgroundImage: widget.technician.profilePictureUrl != null
                ? NetworkImage(widget.technician.profilePictureUrl!)
                : null,
            child: widget.technician.profilePictureUrl == null
                ? Text(
                    widget.technician.name.isNotEmpty ? widget.technician.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          SizedBox(height: 16),
          
          // Name and Department
          Text(
            widget.technician.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.technician.department != null) ...[
            SizedBox(height: 4),
            Text(
              widget.technician.department!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 12),
          
          // Status Chip
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final isActive = widget.technician.status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            widget.technician.status,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info, color: AppTheme.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                _buildStatusChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        // Get tools assigned to this technician
        final assignedTools = toolProvider.tools.where((tool) => 
          tool.assignedTo == widget.technician.name || 
          tool.assignedTo == widget.technician.employeeId
        ).toList();

        if (assignedTools.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No tools assigned',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This technician has no tools assigned to them',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignedTools.length,
          itemBuilder: (context, index) {
            final tool = assignedTools[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.build, color: Colors.white),
                ),
                title: Text(
                  tool.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tool.category != null)
                      Text('Category: ${tool.category}'),
                    if (tool.brand != null)
                      Text('Brand: ${tool.brand}'),
                    Text('Status: ${tool.status}'),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to tool detail screen
                  // TODO: Implement tool detail navigation
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIssuesTab() {
    return Consumer<ToolIssueProvider>(
      builder: (context, issueProvider, child) {
        // Get issues reported by this technician
        final reportedIssues = issueProvider.issues.where((issue) => 
          issue.reportedBy.contains(widget.technician.name) ||
          issue.reportedBy.contains(widget.technician.employeeId ?? '')
        ).toList();

        if (reportedIssues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  'No issues reported',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This technician has not reported any tool issues',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportedIssues.length,
          itemBuilder: (context, index) {
            final issue = reportedIssues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getIssueColor(issue.priority),
                  child: Icon(_getIssueIcon(issue.issueType), color: Colors.white),
                ),
                title: Text(
                  issue.toolName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Issue: ${issue.issueType}'),
                    Text('Priority: ${issue.priority}'),
                    Text('Status: ${issue.status}'),
                    if (issue.description.isNotEmpty)
                      Text(
                        issue.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: _buildIssueStatusChip(issue.status),
                onTap: () {
                  // Navigate to issue detail screen
                  // TODO: Implement issue detail navigation
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getIssueColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow[700]!;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIssueIcon(String issueType) {
    switch (issueType) {
      case 'Faulty':
        return Icons.build;
      case 'Lost':
        return Icons.search_off;
      case 'Damaged':
        return Icons.warning;
      case 'Missing Parts':
        return Icons.inventory;
      default:
        return Icons.report_problem;
    }
  }

  Widget _buildIssueStatusChip(String status) {
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
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
