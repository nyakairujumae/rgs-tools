import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../services/report_service.dart';
import 'report_detail_screen.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_helper.dart';

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
                        'Reports & Analytics',
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
              Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
                builder: (context, toolProvider, technicianProvider, child) {
                  if (toolProvider.isLoading || technicianProvider.isLoading) {
                    return const Expanded(
                      child: Center(
                        child: LoadingWidget(message: 'Loading data...'),
                      ),
                    );
                  }

                  final tools = toolProvider.tools;
                  final technicians = technicianProvider.technicians;
                  
                  return Expanded(
                    child: Column(
                      children: [
                        // Report Configuration Section
                        _buildConfigurationSection(context),
                        
                        // Data Preview Section
                        Expanded(
                          child: _buildDataPreviewSection(
                            context,
                            tools,
                            technicians,
                            toolProvider,
                            technicianProvider,
                          ),
                        ),

                        // Export Button Bar
                        _buildExportButton(context),
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
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.cardSurfaceColor(context),
              borderRadius: BorderRadius.circular(24),
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
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search reports...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  value: (_reportTypes[_selectedReportType]!['name'] as String),
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
  
  Widget _buildFilterPill(BuildContext context, {required String label, required String value, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 48),
        padding: EdgeInsets.symmetric(
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
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
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
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
    SupabaseToolProvider toolProvider,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    final theme = Theme.of(context);
    final reportData = _reportTypes[_selectedReportType] as Map<String, dynamic>?;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_chart,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report Data Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
              if (reportData != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${reportData['name']} - ${reportData['description']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Preview Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildDetailedPreview(
              tools,
              technicians,
              toolProvider,
              technicianProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedPreview(
    List tools,
    List technicians,
    SupabaseToolProvider toolProvider,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    switch (_selectedReportType) {
      case ReportType.toolsInventory:
        return _buildToolsInventoryDetailed(tools, technicianProvider);
      case ReportType.toolAssignments:
        return _buildAssignmentsDetailed(tools, technicians, technicianProvider);
      case ReportType.technicianSummary:
        return _buildTechnicianSummaryDetailed(tools, technicians);
      case ReportType.toolIssues:
        return _buildIssuesDetailed();
      case ReportType.financialSummary:
        return _buildFinancialDetailed(tools);
      case ReportType.toolHistory:
        return _buildHistoryDetailed(tools, technicianProvider);
      case ReportType.comprehensive:
        return _buildComprehensiveDetailed(tools, technicians, technicianProvider);
    }
  }

  Widget _buildToolsInventoryDetailed(List tools, SupabaseTechnicianProvider technicianProvider) {
    final statusCounts = <String, int>{};
    for (final tool in tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                          tool.name,
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
                    child: StatusChip(status: tool.status),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
                ),
              ],
            ),
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
                  'Assigned to:\n${technicianProvider.getTechnicianNameById(tool.assignedTo) ?? "Unknown"}',
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
          final assignedCount = tools.where((t) => t.assignedTo == tech.id).length;
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
                ),
              ],
            ),
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
          decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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

  Widget _buildIssuesDetailed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Tool Issues', 'Historical issue tracking data'),
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
        const SizedBox(height: 24),
                      Container(
          padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
                          borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tool Issues Data',
                          style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All tool issues, maintenance requests, and resolutions\nwill be included in the exported report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
          ],
        ),
      ),
        ),
      ],
    );
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
                ),
              ],
            ),
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
    SupabaseTechnicianProvider technicianProvider,
  ) {
    final assignedTools = tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty).length;
    final totalValue = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Comprehensive Report',
          'Complete overview including all report sections',
        ),
        const SizedBox(height: 20),
        
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
            _buildInfoCard(Icons.account_balance, 'Financial Summary', 1, Colors.purple),
          ],
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Report Contents', 'All sections included in this comprehensive report'),
        const SizedBox(height: 12),
        
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
          'Financial Summary',
          'Financial analysis including total value of ${CurrencyFormatter.formatCurrencyWhole(totalValue)}',
          Icons.account_balance,
          Colors.purple,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
                ),
              ],
            ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
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

  Widget _buildExportButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isExporting ? null : _exportReport,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isExporting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isExporting ? 'Exporting...' : 'Export to Excel',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

      // Ensure data is loaded
      if (toolProvider.tools.isEmpty) {
        await toolProvider.loadTools();
      }
      if (technicianProvider.technicians.isEmpty) {
        await technicianProvider.loadTechnicians();
      }

      final startDate = _getStartDate();
      final endDate = DateTime.now();

      File? file;
      try {
        // Try Excel export first
        file = await ReportService.generateReport(
          reportType: _selectedReportType,
          tools: toolProvider.tools,
          technicians: technicianProvider.technicians,
          startDate: startDate,
          endDate: endDate,
          format: ReportFormat.excel,
        );
      } catch (excelError) {
        // Check if it's the iOS native framework error
        final errorString = excelError.toString().toLowerCase();
        if (errorString.contains('dobjc_initializeapi') || 
            errorString.contains('objective_c.framework') ||
            errorString.contains('native function') ||
            errorString.contains('symbol not found')) {
          // iOS native framework issue - try PDF as fallback
          debugPrint('⚠️ Excel export failed due to iOS native framework issue, trying PDF fallback...');
          try {
            file = await ReportService.generateReport(
              reportType: _selectedReportType,
              tools: toolProvider.tools,
              technicians: technicianProvider.technicians,
              startDate: startDate,
              endDate: endDate,
              format: ReportFormat.pdf,
            );
            // Show info that PDF was used instead
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Excel export unavailable on iOS. Exported as PDF instead.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } catch (pdfError) {
            // If PDF also fails, rethrow the original Excel error
            throw excelError;
          }
        } else {
          // Other error, rethrow
          rethrow;
        }
      }

      if (file == null) {
        throw Exception('Failed to generate report file');
      }

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

    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error exporting report: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
