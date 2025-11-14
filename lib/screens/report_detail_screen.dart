import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';

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

      // Ensure data is loaded
      if (toolProvider.tools.isEmpty) {
        await toolProvider.loadTools();
      }
      if (technicianProvider.technicians.isEmpty) {
        await technicianProvider.loadTechnicians();
      }

      final tools = toolProvider.tools;
      final technicians = technicianProvider.technicians;

      final startDate = _getStartDate();
      final endDate = DateTime.now();

      final file = await ReportService.generateReport(
        reportType: widget.reportType,
        tools: tools,
        technicians: technicians,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // Show success message and open file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Report exported successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  file.path,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                await OpenFile.open(file.path);
              },
            ),
          ),
        );

        // Try to open the file
        try {
          await OpenFile.open(file.path);
        } catch (e) {
          // File opening failed, but report was saved successfully
          debugPrint('Could not open file: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                    Container(
                      width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                      height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
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
                child: Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
                  builder: (context, toolProvider, technicianProvider, child) {
                    if (toolProvider.isLoading || technicianProvider.isLoading) {
                      return const Center(
                        child: LoadingWidget(message: 'Loading data...'),
                      );
                    }

                    final tools = toolProvider.tools;
                    final technicians = technicianProvider.technicians;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildReportContent(tools, technicians, technicianProvider),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(
    List tools,
    List technicians,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    switch (widget.reportType) {
      case ReportType.toolsInventory:
        return _buildToolsInventoryReport(tools, technicianProvider);
      case ReportType.toolAssignments:
        return _buildAssignmentsReport(tools, technicians, technicianProvider);
      case ReportType.technicianSummary:
        return _buildTechnicianSummaryReport(tools, technicians);
      case ReportType.toolIssues:
        return _buildIssuesReport();
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

  Widget _buildIssuesReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tool Issues Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All tool issues, maintenance requests, and resolutions\nwill be included in the exported report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            MaterialPageRoute(
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
            MaterialPageRoute(
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
            MaterialPageRoute(
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
            MaterialPageRoute(
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
                color: Theme.of(context).primaryColor.withOpacity(0.1),
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
            color: Colors.blue.withOpacity(0.1),
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
            color: Colors.grey[600],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tool.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
              color: AppTheme.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment, color: AppTheme.secondaryColor, size: 24),
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
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tool.category} • ${tool.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                  ),
                ),
                if (tech.email != null && tech.email!.isNotEmpty)
                  Text(
                    tech.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500],
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

  Widget _buildFinancialToolCard(dynamic tool) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
              color: Colors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 24),
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
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.subtleBorder,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.history,
              color: Colors.grey[600],
              size: 20,
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
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                  ),
                ),
                if (tool.assignedTo != null)
                  Text(
                    'Assigned to: ${technicianProvider.getTechnicianNameById(tool.assignedTo!) ?? "Unknown"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500],
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
                color: Colors.grey[600],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.subtleBorder,
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
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[400],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
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
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

