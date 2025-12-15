import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/approval_workflows_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../services/report_service.dart';
import 'report_detail_screen.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Last 30 Days';
  ReportType _selectedReportType = ReportType.comprehensive;
  bool _isExporting = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'Last Year',
    'All Time',
  ];

  final Map<ReportType, Map<String, dynamic>> _reportTypes = {
    ReportType.comprehensive: {
      'name': 'Comprehensive Report',
      'description': 'Complete overview with all tool data, assignments, and summaries',
      'icon': Icons.assessment,
    },
    ReportType.toolsInventory: {
      'name': 'Tools Inventory',
      'description': 'Complete list of all tools with specifications and status',
      'icon': Icons.build_circle,
    },
    ReportType.toolAssignments: {
      'name': 'Tool Assignments',
      'description': 'History of tool assignments and current holders',
      'icon': Icons.assignment_ind,
    },
    ReportType.technicianSummary: {
      'name': 'Technician Summary',
      'description': 'Technician information and their assigned tools',
      'icon': Icons.people,
    },
    ReportType.toolIssues: {
      'name': 'Tool Issues',
      'description': 'Reported issues, maintenance requests, and resolutions',
      'icon': Icons.warning_amber,
    },
    ReportType.toolIssuesSummary: {
      'name': 'Tool Issues Summary',
      'description': 'Summary statistics and analytics for tool issues',
      'icon': Icons.analytics,
    },
    ReportType.approvalWorkflowsSummary: {
      'name': 'Approval Workflows Summary',
      'description': 'Summary statistics and analytics for approval workflows',
      'icon': Icons.summarize,
    },
    ReportType.financialSummary: {
      'name': 'Financial Summary',
      'description': 'Financial overview: purchase costs and total investment',
      'icon': Icons.account_balance,
    },
    ReportType.toolHistory: {
      'name': 'Tool History',
      'description': 'Complete transaction history and status changes',
      'icon': Icons.history,
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(
                            Icons.chevron_left,
                            size: 24,
                          color: theme.colorScheme.onSurface,
                          ),
                        onPressed: () => NavigationHelper.safePop(context),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports & Analytics',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Preview RGS tools reports summaries',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isExporting)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: _exportReport,
                        tooltip: 'Export Report',
                      ),
                  ],
                ),
              ),
              Consumer4<SupabaseToolProvider, SupabaseTechnicianProvider, ToolIssueProvider, ApprovalWorkflowsProvider>(
                builder: (context, toolProvider, technicianProvider, issueProvider, workflowProvider, child) {
                  if (toolProvider.isLoading || technicianProvider.isLoading || issueProvider.isLoading || workflowProvider.isLoading) {
                    return Expanded(
                      child: _buildReportSkeleton(context),
                    );
                  }

                  final tools = toolProvider.tools;
                  final technicians = technicianProvider.technicians;
                  final issues = issueProvider.issues;
                  final workflows = workflowProvider.workflows;
                  
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report Configuration Section
                        _buildConfigurationSection(context),
                        const SizedBox(height: 12),
                        // Data Preview Section
                        Expanded(
                          child: _buildDataPreviewSection(
                            context,
                            tools,
                            technicians,
                            issues,
                            workflows,
                            toolProvider,
                            technicianProvider,
                            issueProvider,
                            workflowProvider,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildConfigurationSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: context.cardDecoration,
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: context.chatGPTInputDecoration.copyWith(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  // Trigger rebuild for search filtering if needed
                });
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter Pills Row
          Row(
            children: [
              // Report Type Filter Pill
              Expanded(
                child: _buildFilterPill(
                  context,
                  label: 'Report Type',
                  value: (_reportTypes[_selectedReportType]?['name'] as String?) ?? 'Select Report',
                  onTap: () => _showReportTypeSelector(context),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Period Filter Pill
              Expanded(
                child: _buildFilterPill(
                  context,
                  label: 'Period',
                  value: _selectedPeriod,
                  onTap: () => _showPeriodSelector(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportSkeleton(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context, 12);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          SkeletonLoader(
            height: 24,
            width: 200,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            height: 52,
            width: double.infinity,
            borderRadius: BorderRadius.circular(26),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  height: 48,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: SkeletonLoader(
                  height: 48,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SkeletonLoader(
            height: 16,
            width: 150,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.75,
            ),
            itemCount: crossAxisCount * 2,
            itemBuilder: (context, index) => const ToolCardSkeleton(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildFilterPill(BuildContext context, {required String label, required String value, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 48),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        decoration: context.cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurface,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showReportTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Select Report Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: _reportTypes.entries.map((entry) {
                  final data = entry.value;
                  final icon = data['icon'] as IconData;
                  final name = data['name'] as String;
                  final isSelected = _selectedReportType == entry.key;
                  
                  return InkWell(
                    onTap: () {
                      final selectedType = entry.key;
                      Navigator.pop(context); // Close modal first
                      // Navigate directly to the full report detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(
                            reportType: selectedType,
                            timePeriod: _selectedPeriod,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppTheme.secondaryColor.withValues(alpha: 0.08)
                            : context.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : Colors.black.withValues(alpha: 0.04),
                          width: isSelected ? 1.2 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[300],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: _periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
        padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondaryColor.withValues(alpha: 0.08)
                            : context.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondaryColor
                              : Colors.black.withValues(alpha: 0.04),
                          width: isSelected ? 1.2 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              period,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector(BuildContext context) {
    final reportData = _reportTypes[_selectedReportType] as Map<String, dynamic>?;
    
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text(
          'Report Type',
              style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).cardTheme.color,
          ),
          child: DropdownButtonFormField<ReportType>(
            value: _selectedReportType,
            isExpanded: true,
              decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              ),
            items: _reportTypes.entries.map((entry) {
              final data = entry.value as Map<String, dynamic>;
                return DropdownMenuItem(
                value: entry.key,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data['icon'] as IconData,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data['name'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
              ],
            ),
                );
              }).toList(),
              onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedReportType = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Period',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).cardTheme.color,
          ),
          child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
            isExpanded: true,
              decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
              ),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
          children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        period,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                );
              }).toList(),
              onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportDescription(BuildContext context) {
    final reportInfo = _reportTypes[_selectedReportType] as Map<String, dynamic>?;
    if (reportInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Icon(
            reportInfo['icon'] as IconData,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reportInfo['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPreviewSection(
    BuildContext context,
    List tools,
    List technicians,
    List issues,
    List workflows,
    SupabaseToolProvider toolProvider,
    SupabaseTechnicianProvider technicianProvider,
    ToolIssueProvider issueProvider,
    ApprovalWorkflowsProvider workflowProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: _buildDetailedPreview(
        tools,
        technicians,
        issues,
        workflows,
        toolProvider,
        technicianProvider,
        issueProvider,
        workflowProvider,
      ),
    );
  }

  Widget _buildDetailedPreview(
    List tools,
    List technicians,
    List issues,
    List workflows,
    SupabaseToolProvider toolProvider,
    SupabaseTechnicianProvider technicianProvider,
    ToolIssueProvider issueProvider,
    ApprovalWorkflowsProvider workflowProvider,
  ) {
    switch (_selectedReportType) {
      case ReportType.toolsInventory:
        return _buildToolsInventoryDetailed(tools, technicianProvider);
      case ReportType.toolAssignments:
        return _buildAssignmentsDetailed(tools, technicians, technicianProvider);
      case ReportType.technicianSummary:
        return _buildTechnicianSummaryDetailed(tools, technicians);
      case ReportType.toolIssues:
        return _buildIssuesDetailed(issues);
      case ReportType.toolIssuesSummary:
        return _buildToolIssuesSummary(issues);
      case ReportType.approvalWorkflowsSummary:
        return _buildApprovalWorkflowsSummary(workflows);
      case ReportType.financialSummary:
        return _buildFinancialDetailed(tools);
      case ReportType.toolHistory:
        return _buildHistoryDetailed(tools, technicianProvider);
      case ReportType.comprehensive:
        return _buildComprehensiveDetailed(tools, technicians, issues, workflows, technicianProvider);
    }
  }

  Widget _buildToolsInventoryDetailed(List tools, SupabaseTechnicianProvider technicianProvider) {
    final statusCounts = <String, int>{};
    for (final tool in tools) {
      final status = tool.status ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tools Inventory Overview', '${tools.length} total tools in system'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Statistics Row
        _buildStatsRow([
          _buildMiniStat('Total', tools.length.toString(), Colors.blue),
          _buildMiniStat('Available', statusCounts['Available']?.toString() ?? '0', Colors.green),
          _buildMiniStat('In Use', statusCounts['In Use']?.toString() ?? '0', Colors.orange),
          _buildMiniStat('Maintenance', statusCounts['Maintenance']?.toString() ?? '0', Colors.red),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Tool Details', 'Preview of tools included in export'),
        const SizedBox(height: 12),
        
        // Detailed Table
        _buildToolsTable(tools, technicianProvider),
      ],
    );
  }

  Widget _buildToolsTable(List tools, SupabaseTechnicianProvider technicianProvider) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final previewTools = tools.take(20).toList();

    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeaderCell('Tool Name')),
                Expanded(flex: 2, child: _TableHeaderCell('Category')),
                Expanded(flex: 2, child: _TableHeaderCell('Status')),
                Expanded(flex: 2, child: _TableHeaderCell('Assigned To')),
                Expanded(flex: 2, child: _TableHeaderCell('Value')),
              ],
            ),
          ),
          
          // Table Rows
          ...previewTools.map((tool) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                          tool.name ?? 'Unnamed Tool',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (tool.brand != null && tool.brand!.isNotEmpty)
                          Text(
                            '${tool.brand} ${tool.model ?? ''}'.trim(),
              style: TextStyle(
                              fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                    Expanded(
                    flex: 2,
                    child: Text(
                      tool.category,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: StatusChip(status: tool.status ?? 'Unknown'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tool.assignedTo != null
                          ? (technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? 'Unknown')
                          : 'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: tool.assignedTo != null ? 0.8 : 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tool.purchasePrice != null
                          ? CurrencyFormatter.formatCurrencyWhole(tool.purchasePrice!)
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      ),
                    ),
                  ],
                ),
              );
          }),
          ],
      ),
    );
  }

  Widget _buildAssignmentsDetailed(
    List tools,
    List technicians,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    final assignedTools = tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty).toList();
    final previewTools = assignedTools.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tool Assignments', '${assignedTools.length} tools currently assigned'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Statistics
        _buildStatsRow([
          _buildMiniStat('Total Assigned', assignedTools.length.toString(), Colors.blue),
          _buildMiniStat('Unique Technicians', assignedTools.map((t) => t.assignedTo).toSet().length.toString(), Colors.green),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Assignment Details', 'Current tool assignments'),
        const SizedBox(height: 12),
        
        // Assignment Cards
        ...previewTools.map((tool) {
          return _buildAssignmentCard(tool, technicianProvider);
        }),
        
        if (assignedTools.length > 15)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                '... and ${assignedTools.length - 15} more assignments',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentCard(dynamic tool, SupabaseTechnicianProvider technicianProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_ind,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name ?? 'Unnamed Tool',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tool.category ?? "Uncategorized"} • ${tool.brand ?? "No Brand"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(status: tool.status),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Assigned to:\n${(tool.assignedTo != null && tool.assignedTo!.isNotEmpty) ? (technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? "Unknown") : "Unassigned"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSummaryDetailed(List tools, List technicians) {
    final previewTechnicians = technicians.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Technician Summary', '${technicians.length} technicians in system'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Statistics
        _buildStatsRow([
          _buildMiniStat('Active', technicians.where((t) => t.status == 'Active').length.toString(), Colors.green),
          _buildMiniStat('Total', technicians.length.toString(), Colors.blue),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Technician Details', 'Technician information and assigned tools'),
        const SizedBox(height: 12),
        
        ...previewTechnicians.map((tech) {
          final techId = tech.id;
          final assignedCount = techId != null 
              ? tools.where((t) => t.assignedTo != null && t.assignedTo == techId).length
              : 0;
          return _buildTechnicianCard(tech, assignedCount);
        }),
        
        if (technicians.length > 15)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                '... and ${technicians.length - 15} more technicians',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTechnicianCard(dynamic tech, int assignedCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration,
                child: Row(
                  children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
                    Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tech.department ?? "No Department"} • ${tech.status}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (tech.email != null && tech.email!.isNotEmpty)
                    Text(
                    tech.email!,
                      style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  assignedCount.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'tools',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetailed(List tools) {
    final totalPurchasePrice = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Financial Summary', '${tools.length} tools analyzed'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Financial Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildFinancialCard(
              'Total Purchase Value',
              CurrencyFormatter.formatCurrency(totalPurchasePrice),
              Icons.shopping_cart,
              Colors.blue,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Detailed Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text(
                'Financial Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFinancialRow('Total Purchase Value', totalPurchasePrice),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
            Text(
            value,
              style: TextStyle(
              fontSize: 22,
                fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double value, {bool isPercentage = false}) {
                return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(2)}%'
                : CurrencyFormatter.formatCurrency(value),
                          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIssuesSummary(List issues) {
    final openIssues = issues.where((i) => i.status == 'Open').length;
    final inProgressIssues = issues.where((i) => i.status == 'In Progress').length;
    final resolvedIssues = issues.where((i) => i.status == 'Resolved').length;
    final closedIssues = issues.where((i) => i.status == 'Closed').length;
    
    final criticalIssues = issues.where((i) => i.priority == 'Critical').length;
    final highPriorityIssues = issues.where((i) => i.priority == 'High').length;
    final mediumPriorityIssues = issues.where((i) => i.priority == 'Medium').length;
    final lowPriorityIssues = issues.where((i) => i.priority == 'Low').length;
    
    final faultyTools = issues.where((i) => i.issueType == 'Faulty').length;
    final lostTools = issues.where((i) => i.issueType == 'Lost').length;
    final damagedTools = issues.where((i) => i.issueType == 'Damaged').length;
    final missingParts = issues.where((i) => i.issueType == 'Missing Parts').length;
    
    final totalCost = issues.fold(0.0, (sum, issue) => sum + (issue.estimatedCost ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tool Issues Summary', '${issues.length} total issues tracked'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Overview Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildFinancialCard(
              'Total Issues',
              issues.length.toString(),
              Icons.warning_amber,
              Colors.red,
            ),
            _buildFinancialCard(
              'Open Issues',
              openIssues.toString(),
              Icons.error_outline,
              Colors.orange,
            ),
            _buildFinancialCard(
              'Resolved Issues',
              resolvedIssues.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildFinancialCard(
              'Estimated Cost',
              CurrencyFormatter.formatCurrency(totalCost),
              Icons.attach_money,
              Colors.teal,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Status Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFinancialRow('Open', openIssues.toDouble()),
              _buildFinancialRow('In Progress', inProgressIssues.toDouble()),
              _buildFinancialRow('Resolved', resolvedIssues.toDouble()),
              _buildFinancialRow('Closed', closedIssues.toDouble()),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Priority Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Priority Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFinancialRow('Critical', criticalIssues.toDouble()),
              _buildFinancialRow('High', highPriorityIssues.toDouble()),
              _buildFinancialRow('Medium', mediumPriorityIssues.toDouble()),
              _buildFinancialRow('Low', lowPriorityIssues.toDouble()),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Issue Type Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Issue Type Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFinancialRow('Faulty', faultyTools.toDouble()),
              _buildFinancialRow('Lost', lostTools.toDouble()),
              _buildFinancialRow('Damaged', damagedTools.toDouble()),
              _buildFinancialRow('Missing Parts', missingParts.toDouble()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalWorkflowsSummary(List workflows) {
    final pendingWorkflows = workflows.where((w) => w.status == 'Pending').length;
    final approvedWorkflows = workflows.where((w) => w.status == 'Approved').length;
    final rejectedWorkflows = workflows.where((w) => w.status == 'Rejected').length;
    final cancelledWorkflows = workflows.where((w) => w.status == 'Cancelled').length;
    
    // Count by request type
    final toolAssignmentCount = workflows.where((w) => w.requestType == 'Tool Assignment').length;
    final toolPurchaseCount = workflows.where((w) => w.requestType == 'Tool Purchase').length;
    final toolDisposalCount = workflows.where((w) => w.requestType == 'Tool Disposal').length;
    final maintenanceCount = workflows.where((w) => w.requestType == 'Maintenance').length;
    final transferCount = workflows.where((w) => w.requestType == 'Transfer').length;
    final repairCount = workflows.where((w) => w.requestType == 'Repair').length;
    final calibrationCount = workflows.where((w) => w.requestType == 'Calibration').length;
    final certificationCount = workflows.where((w) => w.requestType == 'Certification').length;
    
    // Count by priority
    final criticalPriority = workflows.where((w) => w.priority == 'Critical').length;
    final highPriority = workflows.where((w) => w.priority == 'High').length;
    final mediumPriority = workflows.where((w) => w.priority == 'Medium').length;
    final lowPriority = workflows.where((w) => w.priority == 'Low').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Approval Workflows Summary', '${workflows.length} total workflows'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Overview Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildFinancialCard(
              'Total Workflows',
              workflows.length.toString(),
              Icons.approval,
              Colors.purple,
            ),
            _buildFinancialCard(
              'Pending',
              pendingWorkflows.toString(),
              Icons.pending,
              Colors.orange,
            ),
            _buildFinancialCard(
              'Approved',
              approvedWorkflows.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildFinancialCard(
              'Rejected',
              rejectedWorkflows.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Status Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFinancialRow('Pending', pendingWorkflows.toDouble()),
              _buildFinancialRow('Approved', approvedWorkflows.toDouble()),
              _buildFinancialRow('Rejected', rejectedWorkflows.toDouble()),
              _buildFinancialRow('Cancelled', cancelledWorkflows.toDouble()),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Request Type Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Type Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (toolAssignmentCount > 0)
                _buildFinancialRow('Tool Assignment', toolAssignmentCount.toDouble()),
              if (toolPurchaseCount > 0)
                _buildFinancialRow('Tool Purchase', toolPurchaseCount.toDouble()),
              if (toolDisposalCount > 0)
                _buildFinancialRow('Tool Disposal', toolDisposalCount.toDouble()),
              if (maintenanceCount > 0)
                _buildFinancialRow('Maintenance', maintenanceCount.toDouble()),
              if (transferCount > 0)
                _buildFinancialRow('Transfer', transferCount.toDouble()),
              if (repairCount > 0)
                _buildFinancialRow('Repair', repairCount.toDouble()),
              if (calibrationCount > 0)
                _buildFinancialRow('Calibration', calibrationCount.toDouble()),
              if (certificationCount > 0)
                _buildFinancialRow('Certification', certificationCount.toDouble()),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Priority Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: context.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Priority Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (criticalPriority > 0)
                _buildFinancialRow('Critical', criticalPriority.toDouble()),
              if (highPriority > 0)
                _buildFinancialRow('High', highPriority.toDouble()),
              if (mediumPriority > 0)
                _buildFinancialRow('Medium', mediumPriority.toDouble()),
              if (lowPriority > 0)
                _buildFinancialRow('Low', lowPriority.toDouble()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesDetailed(List issues) {
    final previewIssues = issues.take(15).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tool Issues', '${issues.length} issues tracked'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Statistics
        _buildStatsRow([
          _buildMiniStat('Total Issues', issues.length.toString(), Colors.red),
          _buildMiniStat('Open', issues.where((i) => i.status == 'Open').length.toString(), Colors.orange),
          _buildMiniStat('Resolved', issues.where((i) => i.status == 'Resolved').length.toString(), Colors.green),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Issue Details', 'Recent tool issues and resolutions'),
        const SizedBox(height: 12),
        
        if (previewIssues.isEmpty)
                      Container(
          padding: const EdgeInsets.all(40),
          decoration: context.cardDecoration,
          child: Center(
            child: Column(
              children: [
                Icon(
                    Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                    'No Issues Found',
                          style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    'No tool issues have been reported',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
          ],
        ),
      ),
          )
        else
          ...previewIssues.map((issue) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: context.cardDecoration,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getIssueColor(issue.priority ?? 'Medium').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIssueIcon(issue.issueType ?? 'Faulty'),
                      color: _getIssueColor(issue.priority ?? 'Medium'),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.toolName ?? 'Unknown Tool',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${issue.issueType ?? "Unknown"} • ${issue.priority ?? "Medium"} • ${issue.status ?? "Unknown"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (issue.description != null && issue.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              issue.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        
        if (issues.length > 15)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                '... and ${issues.length - 15} more issues',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
        ),
      ],
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

  Widget _buildHistoryDetailed(List tools, SupabaseTechnicianProvider technicianProvider) {
    final recentTools = tools.toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final previewTools = recentTools.take(15).toList();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tool History', 'Recent activity and updates'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(
                      reportType: _selectedReportType,
                      timePeriod: _selectedPeriod,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View Full Report'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildStatsRow([
          _buildMiniStat('Recent Updates', previewTools.length.toString(), Colors.blue),
        ]),
        
        const SizedBox(height: 24),
        _buildSectionTitle('History Timeline', 'Recent tool status changes'),
        const SizedBox(height: 12),
        
        ...previewTools.map((tool) {
          final updatedAt = DateTime.tryParse(tool.updatedAt ?? '');
          return _buildHistoryCard(tool, updatedAt, dateFormat, technicianProvider);
        }),
      ],
    );
  }

  Widget _buildHistoryCard(
    dynamic tool,
    DateTime? updatedAt,
    DateFormat dateFormat,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  tool.name ?? 'Unnamed Tool',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tool.category ?? "Uncategorized"} • ${tool.status ?? "Unknown"}',
              style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (tool.assignedTo != null)
                  Text(
                    'Assigned to: ${technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? "Unknown"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          if (updatedAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormat.format(updatedAt),
                    style: TextStyle(
                    fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveDetailed(
    List tools,
    List technicians,
    List issues,
    List workflows,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    final assignedTools = tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty).length;
    final totalValue = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildInfoCard(Icons.build_circle, 'Tools Inventory', tools.length, Colors.blue),
            _buildInfoCard(Icons.assignment_ind, 'Tool Assignments', assignedTools, Colors.green),
            _buildInfoCard(Icons.people, 'Technician Summary', technicians.length, Colors.orange),
            _buildInfoCard(Icons.warning_amber, 'Tool Issues', issues.length, Colors.red),
            _buildInfoCard(Icons.approval, 'Approval Workflows', workflows.length, Colors.purple),
            _buildInfoCard(Icons.account_balance, 'Financial Summary', 1, Colors.teal),
          ],
        ),
        const SizedBox(height: 16),
        _buildComprehensiveSection(
          'Tools Inventory',
          'Complete list of all ${tools.length} tools with specifications, status, and assignment details',
          Icons.build_circle,
          Colors.blue,
          ReportType.toolsInventory,
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSection(
          'Tool Assignments',
          'History of all tool assignments showing ${assignedTools} currently assigned tools',
          Icons.assignment_ind,
          Colors.green,
          ReportType.toolAssignments,
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSection(
          'Technician Summary',
          'Complete information for all ${technicians.length} technicians including assigned tools count',
          Icons.people,
          Colors.orange,
          ReportType.technicianSummary,
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSection(
          'Tool Issues Summary',
          'Summary statistics and analytics for ${issues.length} tool issues including status, priority, and type distributions',
          Icons.analytics,
          Colors.red,
          ReportType.toolIssuesSummary,
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSection(
          'Approval Workflows Summary',
          'Summary statistics and analytics for ${workflows.length} approval workflows including status, type, and priority distributions',
          Icons.summarize,
          Colors.purple,
          ReportType.approvalWorkflowsSummary,
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSection(
          'Financial Summary',
          'Financial analysis including total value of ${CurrencyFormatter.formatCurrencyWhole(totalValue)}',
          Icons.account_balance,
          Colors.teal,
          ReportType.financialSummary,
        ),
      ],
    );
  }

  Widget _buildComprehensiveSection(String title, String description, IconData icon, Color color, ReportType? reportType) {
    return InkWell(
      onTap: reportType != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(
                    reportType: reportType,
                    timePeriod: _selectedPeriod,
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              reportType != null ? Icons.arrow_forward_ios : Icons.check_circle,
              color: reportType != null ? Colors.grey[400] : Colors.green,
              size: reportType != null ? 16 : 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
                      style: TextStyle(
              fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<Widget> stats) {
    return Row(
      children: stats
          .map((stat) => Expanded(child: stat))
          .expand((widget) => [widget, const SizedBox(width: 12)])
          .take(stats.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      case 'Last Year':
        return now.subtract(const Duration(days: 365));
      case 'All Time':
      default:
        return null;
    }
  }

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      final technicianProvider = context.read<SupabaseTechnicianProvider>();
      final issueProvider = context.read<ToolIssueProvider>();
      final workflowProvider = context.read<ApprovalWorkflowsProvider>();

      // Always refresh data from database to ensure reports have latest information
      await Future.wait([
        toolProvider.loadTools(),
        technicianProvider.loadTechnicians(),
        issueProvider.loadIssues(),
        workflowProvider.loadWorkflows(),
      ]);

      final startDate = _getStartDate();
      final endDate = DateTime.now();

      // Use PDF format for all reports - table-based PDFs similar to Excel sheets
      final file = await ReportService.generateReport(
        reportType: _selectedReportType,
        tools: toolProvider.tools,
        technicians: technicianProvider.technicians,
        issues: issueProvider.issues,
        workflows: workflowProvider.workflows,
        startDate: startDate,
        endDate: endDate,
        format: ReportFormat.pdf,
      );

      if (file == null) {
        throw Exception('Failed to generate report file');
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // Show success message and open file
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Report exported successfully',
        );

        // Try to open the file
        try {
          if (file != null) {
            await OpenFile.open(file.path);
          }
        } catch (e) {
          debugPrint('Could not open file: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        AuthErrorHandler.showErrorSnackBar(
          context,
          'Error exporting report: $e',
        );
      }
    }
  }
}

// Table Header Cell Widget
class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
}
