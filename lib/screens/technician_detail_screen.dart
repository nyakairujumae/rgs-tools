import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/technician.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/auth_error_handler.dart';
import 'add_technician_screen.dart';
import 'technicians_screen.dart';

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          widget.technician.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: context.cardDecoration,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Colors.black.withOpacity(0.04),
                    width: 0.5,
                  ),
                ),
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTechnicianScreen(technician: widget.technician),
                ),
              );
                  } else if (value == 'delete') {
                _deleteTechnician();
              }
            },
            itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    height: 52,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppTheme.secondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Technician',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                value: 'delete',
                    height: 52,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete Technician',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: context.cardDecoration,
            child: TabBar(
          controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Tools'),
            Tab(text: 'Issues'),
          ],
            ),
          ),
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
      decoration: context.cardDecoration,
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: widget.technician.profilePictureUrl != null &&
                    widget.technician.profilePictureUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.technician.profilePictureUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Error loading profile picture for ${widget.technician.name}: $error');
                        debugPrint('❌ URL: ${widget.technician.profilePictureUrl}');
                        return Center(
                          child: Text(
                            widget.technician.name.isNotEmpty ? widget.technician.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 36,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      widget.technician.name.isNotEmpty ? widget.technician.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 36,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
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
    return FilterChip(
      showCheckmark: false,
      avatar: Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
        color: isActive ? AppTheme.secondaryColor : Colors.grey,
            size: 16,
          ),
      label: Text(
            widget.technician.status,
            style: TextStyle(
          color: isActive ? AppTheme.secondaryColor : Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: true,
      onSelected: null,
      backgroundColor: isActive 
          ? AppTheme.secondaryColor.withOpacity(0.08)
          : Colors.grey.withOpacity(0.08),
      selectedColor: isActive 
          ? AppTheme.secondaryColor.withOpacity(0.08)
          : Colors.grey.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide(
        color: isActive ? AppTheme.secondaryColor : Colors.grey,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: context.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.secondaryColor, size: 20),
              ),
              const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
            ...children,
          ],
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: context.cardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildToolImage(tool),
                  ),
                ),
                title: Text(
                  tool.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tool.category != null)
                        Text(
                          'Category: ${tool.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    if (tool.brand != null)
                        Text(
                          'Brand: ${tool.brand}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      Text(
                        'Status: ${tool.status}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: context.cardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getIssueColor(issue.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIssueIcon(issue.issueType),
                    color: _getIssueColor(issue.priority),
                    size: 24,
                  ),
                ),
                title: Text(
                  issue.toolName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        'Issue: ${issue.issueType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        'Priority: ${issue.priority}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    if (issue.description.isNotEmpty)
                      Text(
                        issue.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                      ),
                  ],
                  ),
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

    return FilterChip(
      showCheckmark: false,
      label: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: true,
      onSelected: null,
      backgroundColor: color.withOpacity(0.08),
      selectedColor: color.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide(
        color: color,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  void _deleteTechnician() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Query database directly to check for assigned tools
      // This ensures we check the actual database state, not local cache
      // Check for tools assigned by ID, name, or employee ID
      List<dynamic> assignedTools = [];
      
      // Check by technician ID
      if (widget.technician.id != null) {
        final toolsById = await SupabaseService.client
            .from('tools')
            .select('id, name')
            .eq('assigned_to', widget.technician.id!);
        assignedTools.addAll(toolsById as List);
      }
      
      // Check by technician name (if different from ID)
      if (widget.technician.name.isNotEmpty && 
          widget.technician.name != widget.technician.id) {
        final toolsByName = await SupabaseService.client
            .from('tools')
            .select('id, name')
            .eq('assigned_to', widget.technician.name);
        assignedTools.addAll(toolsByName as List);
      }
      
      // Check by employee ID (if different from name and ID)
      if (widget.technician.employeeId != null && 
          widget.technician.employeeId!.isNotEmpty &&
          widget.technician.employeeId != widget.technician.id &&
          widget.technician.employeeId != widget.technician.name) {
        final toolsByEmployeeId = await SupabaseService.client
            .from('tools')
            .select('id, name')
            .eq('assigned_to', widget.technician.employeeId!);
        assignedTools.addAll(toolsByEmployeeId as List);
      }
      
      // Remove duplicates (in case a tool matches multiple conditions)
      final uniqueAssignedTools = assignedTools.toSet().toList();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (uniqueAssignedTools.isNotEmpty) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Cannot delete technician with assigned tools. Please reassign or return ${uniqueAssignedTools.length} tool(s) first.',
      );
      return;
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      debugPrint('Error checking assigned tools: $e');
      // If query fails, continue with deletion attempt
      // The database will enforce constraints if tools actually exist
    }

    // Capture the screen's navigator before showing dialog
    final screenNavigator = Navigator.of(context);
    final screenScaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Technician',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${widget.technician.name}"?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently delete:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• The technician record',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '• All associated data',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
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
                child: Text(
                  'This action cannot be undone!',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Close confirmation dialog first
                Navigator.pop(dialogContext);
                
                try {
                  final technicianProvider = context.read<SupabaseTechnicianProvider>();
                  final technicianName = widget.technician.name;
                  
                  // Delete from database
                  await technicianProvider.deleteTechnician(widget.technician.id!);
                  
                  // Navigate back to technicians screen
                  screenNavigator.pop();
                  
                  // Show success message
                  Future.delayed(const Duration(milliseconds: 100), () {
                    AuthErrorHandler.showSuccessSnackBar(
                      screenScaffoldMessenger.context,
                      'Technician "$technicianName" deleted successfully',
                    );
                  });
                } catch (e) {
                  debugPrint('❌ Error deleting technician: $e');
                  
                  if (mounted) {
                    String errorMessage = 'Failed to delete technician. ';
                    if (e.toString().contains('permission')) {
                      errorMessage += 'You do not have permission to delete this technician.';
                    } else if (e.toString().contains('network')) {
                      errorMessage += 'Network error. Please check your connection.';
                    } else if (e.toString().contains('foreign key') || e.toString().contains('constraint')) {
                      errorMessage += 'Cannot delete technician with associated records.';
                    } else {
                      errorMessage += 'Please try again. Error: ${e.toString()}';
                    }
                    
                    AuthErrorHandler.showErrorSnackBar(context, errorMessage);
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolImage(dynamic tool) {
    if (tool.imagePath == null || tool.imagePath!.isEmpty) {
      return _buildPlaceholderImage();
    }

    final imagePath = tool.imagePath!;
    
    // Handle network images
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              ),
            ),
          );
        },
      );
    }

    // Handle local file images
    if (kIsWeb) {
      // On web, local file paths might not work, show placeholder
      return _buildPlaceholderImage();
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBackground,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
