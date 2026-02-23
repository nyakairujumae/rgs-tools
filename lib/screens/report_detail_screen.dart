import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/approval_workflows_provider.dart';
import '../models/tool_issue.dart';
import '../models/approval_workflow.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/auth_error_handler.dart';
import '../utils/logger.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportType reportType;
  final String timePeriod;

  const ReportDetailScreen({
    super.key,
    required this.reportType,
    required this.timePeriod,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Load issues and workflows if needed for the report type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.reportType == ReportType.toolIssuesSummary || 
            widget.reportType == ReportType.toolIssues ||
            widget.reportType == ReportType.comprehensive) {
          final issueProvider = Provider.of<ToolIssueProvider>(context, listen: false);
          // Always refresh to get latest data
          if (!issueProvider.isLoading) {
            issueProvider.loadIssues();
          }
        }
        if (widget.reportType == ReportType.approvalWorkflowsSummary ||
            widget.reportType == ReportType.comprehensive) {
          final workflowProvider = Provider.of<ApprovalWorkflowsProvider>(context, listen: false);
          // Always refresh to get latest data
          if (!workflowProvider.isLoading) {
            workflowProvider.loadWorkflows();
          }
        }
      }
    });
  }

  String _getReportTitle() {
    switch (widget.reportType) {
      case ReportType.toolsInventory:
        return 'Tools Inventory Report';
      case ReportType.toolAssignments:
        return 'Tool Assignments Report';
      case ReportType.technicianSummary:
        return 'Technician Summary Report';
      case ReportType.toolIssues:
        return 'Tool Issues Report';
      case ReportType.toolIssuesSummary:
        return 'Tool Issues Summary Report';
      case ReportType.approvalWorkflowsSummary:
        return 'Approval Workflows Summary Report';
      case ReportType.financialSummary:
        return 'Financial Summary Report';
      case ReportType.toolHistory:
        return 'Tool History Report';
      case ReportType.comprehensive:
        return 'Comprehensive Report';
    }
  }

  IconData _getReportIcon() {
    switch (widget.reportType) {
      case ReportType.toolsInventory:
        return Icons.build_circle;
      case ReportType.toolAssignments:
        return Icons.assignment_ind;
      case ReportType.technicianSummary:
        return Icons.people;
      case ReportType.toolIssues:
        return Icons.warning_amber;
      case ReportType.toolIssuesSummary:
        return Icons.analytics;
      case ReportType.approvalWorkflowsSummary:
        return Icons.summarize;
      case ReportType.financialSummary:
        return Icons.account_balance;
      case ReportType.toolHistory:
        return Icons.history;
      case ReportType.comprehensive:
        return Icons.assessment;
    }
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (widget.timePeriod) {
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
      final toolProvider = Provider.of<SupabaseToolProvider>(context, listen: false);
      final technicianProvider = Provider.of<SupabaseTechnicianProvider>(context, listen: false);

      // Always refresh data from database to ensure reports have latest information
      await toolProvider.loadTools();
      await technicianProvider.loadTechnicians();

      final tools = toolProvider.tools;
      final technicians = technicianProvider.technicians;

      // Load issues and workflows if needed for reports
      List<ToolIssue>? issues;
      List<ApprovalWorkflow>? workflows;
      
      if (widget.reportType == ReportType.toolIssuesSummary || 
          widget.reportType == ReportType.toolIssues ||
          widget.reportType == ReportType.comprehensive) {
        final issueProvider = Provider.of<ToolIssueProvider>(context, listen: false);
        await issueProvider.loadIssues();
        issues = issueProvider.issues;
      }
      
      if (widget.reportType == ReportType.approvalWorkflowsSummary ||
          widget.reportType == ReportType.comprehensive) {
        final workflowProvider = Provider.of<ApprovalWorkflowsProvider>(context, listen: false);
        await workflowProvider.loadWorkflows();
        workflows = workflowProvider.workflows;
      }

      final startDate = _getStartDate();
      final endDate = DateTime.now();

      final file = await ReportService.generateReport(
        reportType: widget.reportType,
        tools: tools,
        technicians: technicians,
        startDate: startDate,
        endDate: endDate,
        issues: issues,
        workflows: workflows,
      );

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
          await OpenFile.open(file.path);
        } catch (e) {
          // File opening failed, but report was saved successfully
          Logger.debug('Could not open file: $e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 900 : double.infinity,
            ),
            child: Container(
              color: context.scaffoldBackground,
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kIsWeb ? 24 : 16,
                  kIsWeb ? 24 : 20,
                  kIsWeb ? 24 : 16,
                  0,
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: Text(
                        _getReportTitle(),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
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
              Expanded(
                child: Consumer4<SupabaseToolProvider, SupabaseTechnicianProvider, ToolIssueProvider, ApprovalWorkflowsProvider>(
                  builder: (context, toolProvider, technicianProvider, issueProvider, workflowProvider, child) {
                    if (toolProvider.isLoading || technicianProvider.isLoading || 
                        (widget.reportType == ReportType.toolIssuesSummary || widget.reportType == ReportType.toolIssues) && issueProvider.isLoading ||
                        (widget.reportType == ReportType.approvalWorkflowsSummary) && workflowProvider.isLoading) {
                      return const Center(
                        child: LoadingWidget(message: 'Loading data...'),
                      );
                    }

                    final tools = toolProvider.tools;
                    final technicians = technicianProvider.technicians;
                    final issues = issueProvider.issues;
                    final workflows = workflowProvider.workflows;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(kIsWeb ? 24 : 16, 0, kIsWeb ? 24 : 16, 16),
                      child: _buildReportContent(tools, technicians, technicianProvider, issues, workflows),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildReportContent(
    List tools,
    List technicians,
    SupabaseTechnicianProvider technicianProvider,
    List issues,
    List workflows,
  ) {
    switch (widget.reportType) {
      case ReportType.toolsInventory:
        return _buildToolsInventoryReport(tools, technicianProvider);
      case ReportType.toolAssignments:
        return _buildAssignmentsReport(tools, technicians, technicianProvider);
      case ReportType.technicianSummary:
        return _buildTechnicianSummaryReport(tools, technicians);
      case ReportType.toolIssues:
        return _buildIssuesReport(issues);
      case ReportType.toolIssuesSummary:
        return _buildToolIssuesSummaryReport(issues);
      case ReportType.approvalWorkflowsSummary:
        return _buildApprovalWorkflowsSummaryReport(workflows);
      case ReportType.financialSummary:
        return _buildFinancialReport(tools);
      case ReportType.toolHistory:
        return _buildHistoryReport(tools, technicianProvider);
      case ReportType.comprehensive:
        return _buildComprehensiveReport(tools, technicians, technicianProvider);
    }
  }

  Widget _buildToolsInventoryReport(List tools, SupabaseTechnicianProvider technicianProvider) {
    final statusCounts = <String, int>{};
    for (final tool in tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics
        _buildStatsGrid([
          _buildStatCard('Total Tools', tools.length.toString(), Icons.build, Colors.blue),
          _buildStatCard('Available', statusCounts['Available']?.toString() ?? '0', Icons.check_circle, Colors.green),
          _buildStatCard('In Use', statusCounts['In Use']?.toString() ?? '0', Icons.work, Colors.orange),
          _buildStatCard('Maintenance', statusCounts['Maintenance']?.toString() ?? '0', Icons.build_circle, Colors.red),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('All Tools', 'Complete inventory listing'),
        const SizedBox(height: 16),
        
        // Tools List
        ...tools.map((tool) => _buildToolCard(tool, technicianProvider, dateFormat)),
      ],
    );
  }

  Widget _buildAssignmentsReport(List tools, List technicians, SupabaseTechnicianProvider technicianProvider) {
    final assignedTools = tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty).toList();
    final unassignedCount = tools.length - assignedTools.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Assigned Tools', assignedTools.length.toString(), Icons.assignment, Colors.green),
          _buildStatCard('Unassigned Tools', unassignedCount.toString(), Icons.assignment_late, Colors.orange),
          _buildStatCard('Total Tools', tools.length.toString(), Icons.build, Colors.blue),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('Assigned Tools', 'Tools currently assigned to technicians'),
        const SizedBox(height: 16),
        
        ...assignedTools.map((tool) {
          final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? 'Unknown';
          return _buildAssignmentCard(tool, technicianName);
        }),
      ],
    );
  }

  Widget _buildTechnicianSummaryReport(List tools, List technicians) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Technicians', technicians.length.toString(), Icons.people, Colors.blue),
          _buildStatCard('Active', technicians.where((t) => t.status == 'Active').length.toString(), Icons.check_circle, Colors.green),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('Technician Details', 'Complete technician information'),
        const SizedBox(height: 16),
        
        ...technicians.map((tech) {
          final assignedCount = tools.where((t) => t.assignedTo == tech.id).length;
          return _buildTechnicianDetailCard(tech, assignedCount);
        }),
      ],
    );
  }

  Widget _buildFinancialReport(List tools) {
    final totalPurchasePrice = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Purchase Value', CurrencyFormatter.formatCurrencyWhole(totalPurchasePrice), Icons.shopping_cart, Colors.blue),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('Top Value Tools', 'Tools with highest purchase price'),
        const SizedBox(height: 16),
        
        ...() {
          final sortedTools = tools
            .where((t) => (t.purchasePrice ?? 0) > 0)
            .toList()
            ..sort((a, b) => (b.purchasePrice ?? 0).compareTo(a.purchasePrice ?? 0));
          return sortedTools
            .take(10)
            .map((tool) => _buildFinancialToolCard(tool))
            .toList();
        }(),
      ],
    );
  }

  Widget _buildIssuesReport(List issues) {
    if (issues.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: context.cardDecoration,
          child: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: context.placeholderIcon,
              ),
              const SizedBox(height: 16),
              Text(
                'No Tool Issues Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[300],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tool issues found in the selected period.\nAll tool issues will be included in the exported report.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Issues', issues.length.toString(), Icons.warning_amber, Colors.red),
          _buildStatCard('Open', issues.where((i) => i.status == 'Open').length.toString(), Icons.error_outline, Colors.orange),
          _buildStatCard('Resolved', issues.where((i) => i.status == 'Resolved').length.toString(), Icons.check_circle, Colors.green),
        ]),
        const SizedBox(height: 24),
        _buildSectionTitle('Tool Issues', 'All tool issues will be included in the exported report'),
        const SizedBox(height: 16),
        ...issues.map((issue) => _buildIssueCard(issue)),
      ],
    );
  }

  Widget _buildToolIssuesSummaryReport(List issues) {
    if (issues.isEmpty) {
      return Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: context.cardDecoration,
            child: Column(
              children: [
                Icon(
                Icons.check_circle_outline,
                  size: 64,
                  color: context.placeholderIcon,
                ),
                const SizedBox(height: 16),
                Text(
                'No Tool Issues Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                'No tool issues found in the selected period.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
      );
    }

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

    // Sort issues by reported date (newest first)
    final sortedIssues = List.from(issues)
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Issues', issues.length.toString(), Icons.warning_amber, Colors.red),
          _buildStatCard('Open Issues', openIssues.toString(), Icons.error_outline, Colors.orange),
          _buildStatCard('Resolved', resolvedIssues.toString(), Icons.check_circle, Colors.green),
          _buildStatCard('Estimated Cost', CurrencyFormatter.formatCurrency(totalCost), Icons.attach_money, Colors.teal),
        ]),
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
        
        const SizedBox(height: 32),
        _buildSectionTitle('All Tool Issues', 'Complete list of all ${issues.length} issues'),
        const SizedBox(height: 16),
        
        // Issues List
        ...sortedIssues.map((issue) => _buildDetailedIssueCard(issue)),
      ],
    );
  }

  Widget _buildApprovalWorkflowsSummaryReport(List workflows) {
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
        _buildStatsGrid([
          _buildStatCard('Total Workflows', workflows.length.toString(), Icons.approval, Colors.purple),
          _buildStatCard('Pending', pendingWorkflows.toString(), Icons.pending, Colors.orange),
          _buildStatCard('Approved', approvedWorkflows.toString(), Icons.check_circle, Colors.green),
          _buildStatCard('Rejected', rejectedWorkflows.toString(), Icons.cancel, Colors.red),
        ]),
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

  Widget _buildIssueCard(dynamic issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  issue.toolName ?? 'Unknown Tool',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(issue.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  issue.status ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(issue.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${issue.issueType ?? 'Unknown'} • Priority: ${issue.priority ?? 'Medium'}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (issue.description != null && issue.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              issue.description!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedIssueCard(dynamic issue) {
    final theme = Theme.of(context);
    final letter = issue.toolName.isNotEmpty ? issue.toolName[0].toUpperCase() : '?';
    final details = [
      '#${issue.toolId}',
      if (issue.location != null && issue.location!.isNotEmpty)
        issue.location!,
    ].where((d) => d.isNotEmpty).join(' • ');

    final dateFormat = DateFormat('MMM dd, yyyy');
    final reportedDate = dateFormat.format(issue.reportedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
              _buildIssueTypePill(issue.issueType ?? 'Unknown'),
              _buildPriorityPill(issue.priority ?? 'Medium'),
              _buildStatusChip(issue.status ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issue.description ?? 'No description',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reported by ${issue.reportedBy} • $reportedDate',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
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
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      case 'low':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFinancialRow(String label, double value, {bool isPercentage = false}) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(2)}%'
                : value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryReport(List tools, SupabaseTechnicianProvider technicianProvider) {
    final recentTools = tools.toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Tools', tools.length.toString(), Icons.build, Colors.blue),
          _buildStatCard('Recent Updates', recentTools.take(30).length.toString(), Icons.history, Colors.orange),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('History Timeline', 'Recent tool status changes and updates'),
        const SizedBox(height: 16),
        
        ...recentTools.take(30).map((tool) {
          final updatedAt = DateTime.tryParse(tool.updatedAt ?? '');
          return _buildHistoryCard(tool, updatedAt, dateFormat, technicianProvider);
        }),
      ],
    );
  }

  Widget _buildComprehensiveReport(List tools, List technicians, SupabaseTechnicianProvider technicianProvider) {
    final assignedTools = tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty).length;
    final totalValue = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid([
          _buildStatCard('Total Tools', tools.length.toString(), Icons.build_circle, Colors.blue),
          _buildStatCard('Assigned Tools', assignedTools.toString(), Icons.assignment_ind, Colors.green),
          _buildStatCard('Technicians', technicians.length.toString(), Icons.people, Colors.orange),
          _buildStatCard('Total Value', CurrencyFormatter.formatCurrencyWhole(totalValue), Icons.account_balance, Colors.purple),
        ]),
        
        const SizedBox(height: 32),
        _buildSectionTitle('Report Sections', 'All sections included in this comprehensive report'),
        const SizedBox(height: 16),
        
        _buildComprehensiveSectionCard(
          'Tools Inventory',
          'Complete list of all ${tools.length} tools',
          Icons.build_circle,
          Colors.blue,
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ReportDetailScreen(
                reportType: ReportType.toolsInventory,
                timePeriod: widget.timePeriod,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSectionCard(
          'Tool Assignments',
          'History of all tool assignments',
          Icons.assignment_ind,
          Colors.green,
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ReportDetailScreen(
                reportType: ReportType.toolAssignments,
                timePeriod: widget.timePeriod,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSectionCard(
          'Technician Summary',
          'Complete information for all ${technicians.length} technicians',
          Icons.people,
          Colors.orange,
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ReportDetailScreen(
                reportType: ReportType.technicianSummary,
                timePeriod: widget.timePeriod,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildComprehensiveSectionCard(
          'Financial Summary',
          'Financial analysis and valuation',
          Icons.account_balance,
          Colors.purple,
          () => Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ReportDetailScreen(
                reportType: ReportType.financialSummary,
                timePeriod: widget.timePeriod,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildReportHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getReportIcon(),
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                widget.timePeriod,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ],
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
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: children,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: context.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large value centered, taking up center space
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          // Icon and name together at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 6)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(dynamic tool, SupabaseTechnicianProvider technicianProvider, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(status: tool.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow('Category', tool.category),
              ),
              Expanded(
                child: _buildInfoRow('Brand', tool.brand ?? 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  'Assigned To',
                  tool.assignedTo != null
                      ? (technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? 'Unknown')
                      : 'Unassigned',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  'Purchase Price',
                  CurrencyFormatter.formatCurrencyWhole(tool.purchasePrice ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic tool, String technicianName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assigned to: $technicianName',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tool.category} • ${tool.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianDetailCard(dynamic tech, int assignedCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryColor,
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (tech.email != null && tech.email!.isNotEmpty)
                  Text(
                    tech.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  assignedCount.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'tools',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialToolCard(dynamic tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tool.category} • ${tool.brand ?? "No Brand"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCurrencyWhole(tool.purchasePrice ?? 0),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tool.category} • ${tool.status}',
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
    );
  }

  Widget _buildComprehensiveSectionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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








