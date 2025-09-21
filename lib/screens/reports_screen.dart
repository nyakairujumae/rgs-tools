import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Last 30 Days';
  bool _isLoading = false;

  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'Last Year',
    'All Time',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
        builder: (context, toolProvider, technicianProvider, child) {
          if (toolProvider.isLoading || technicianProvider.isLoading) {
            return const LoadingWidget(message: 'Loading reports...');
          }

          final tools = toolProvider.tools;
          final technicians = technicianProvider.technicians;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                SizedBox(height: 24),

                // Key Metrics
                _buildKeyMetrics(tools, technicians),
                SizedBox(height: 24),

                // Tool Status Distribution
                _buildToolStatusChart(tools),
                SizedBox(height: 24),

                // Tool Condition Analysis
                _buildToolConditionChart(tools),
                SizedBox(height: 24),

                // Top Technicians
                _buildTopTechnicians(tools, technicians),
                SizedBox(height: 24),

                // Recent Activity
                _buildRecentActivity(tools),
                SizedBox(height: 24),

                // Maintenance Alerts
                _buildMaintenanceAlerts(tools),
                SizedBox(height: 24),

                // Financial Summary
                _buildFinancialSummary(tools),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(List tools, List technicians) {
    final totalTools = tools.length;
    final availableTools = tools.where((t) => t.status == 'Available').length;
    final inUseTools = tools.where((t) => t.status == 'In Use').length;
    final maintenanceTools = tools.where((t) => t.status == 'Maintenance').length;
    final totalValue = tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0));
    final activeTechnicians = technicians.where((t) => t.status == 'Active').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard('Total Tools', totalTools.toString(), Icons.build, AppTheme.primaryColor),
            _buildMetricCard('Active Technicians', activeTechnicians.toString(), Icons.people, AppTheme.secondaryColor),
            _buildMetricCard('Available Tools', availableTools.toString(), Icons.check_circle, AppTheme.successColor),
            _buildMetricCard('In Use', inUseTools.toString(), Icons.person, AppTheme.statusInUse),
            _buildMetricCard('Maintenance', maintenanceTools.toString(), Icons.build, AppTheme.statusMaintenance),
            _buildMetricCard('Total Value', '\$${totalValue.toStringAsFixed(0)}', Icons.attach_money, AppTheme.accentColor),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolStatusChart(List tools) {
    final statusCounts = <String, int>{};
    for (final tool in tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tool Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ...statusCounts.entries.map((entry) {
              final percentage = (entry.value / tools.length * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    StatusChip(status: entry.key),
                    SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / tools.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.getStatusColor(entry.key),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${entry.value} (${percentage}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolConditionChart(List tools) {
    final conditionCounts = <String, int>{};
    for (final tool in tools) {
      conditionCounts[tool.condition] = (conditionCounts[tool.condition] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tool Condition Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ...conditionCounts.entries.map((entry) {
              final percentage = (entry.value / tools.length * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ConditionChip(condition: entry.key),
                    SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / tools.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.getConditionColor(entry.key),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${entry.value} (${percentage}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTechnicians(List tools, List technicians) {
    final technicianToolCounts = <String, int>{};
    for (final tool in tools) {
      if (tool.assignedTo != null) {
        technicianToolCounts[tool.assignedTo!] = (technicianToolCounts[tool.assignedTo!] ?? 0) + 1;
      }
    }

    final sortedTechnicians = technicianToolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Technicians by Tool Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            if (sortedTechnicians.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No tool assignments found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...sortedTechnicians.take(5).map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value} tools',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List tools) {
    // Sort tools by updated date (most recent first)
    final recentTools = tools.toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ...recentTools.take(5).map((tool) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.getStatusColor(tool.status),
                    child: Icon(Icons.build, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                  ),
                  title: Text(
                    tool.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${tool.category} • ${tool.brand ?? 'Unknown'}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: StatusChip(status: tool.status),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceAlerts(List tools) {
    final maintenanceTools = tools.where((tool) => 
      tool.condition == 'Poor' || tool.condition == 'Needs Repair'
    ).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text(
                  'Maintenance Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${maintenanceTools.length}',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (maintenanceTools.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'All tools are in good condition!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...maintenanceTools.map((tool) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.getConditionColor(tool.condition),
                      child: Icon(Icons.build, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                    ),
                    title: Text(
                      tool.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${tool.category} • ${tool.condition}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: ConditionChip(condition: tool.condition),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(List tools) {
    final totalValue = tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0));
    final totalPurchasePrice = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));
    final depreciation = totalPurchasePrice - totalValue;
    final depreciationPercentage = totalPurchasePrice > 0 ? (depreciation / totalPurchasePrice * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            _buildFinancialRow('Total Purchase Value', '\$${totalPurchasePrice.toStringAsFixed(2)}'),
            _buildFinancialRow('Current Value', '\$${totalValue.toStringAsFixed(2)}'),
            _buildFinancialRow('Total Depreciation', '\$${depreciation.toStringAsFixed(2)}'),
            _buildFinancialRow('Depreciation %', '${depreciationPercentage.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    // TODO: Implement report export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

