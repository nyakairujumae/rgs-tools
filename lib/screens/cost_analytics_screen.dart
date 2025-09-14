import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';

class CostAnalyticsScreen extends StatefulWidget {
  const CostAnalyticsScreen({super.key});

  @override
  State<CostAnalyticsScreen> createState() => _CostAnalyticsScreenState();
}

class _CostAnalyticsScreenState extends State<CostAnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Analytics'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Consumer<SupabaseToolProvider>(
        builder: (context, toolProvider, child) {
          final tools = toolProvider.tools;
          
          if (tools.isEmpty) {
            return const EmptyState(
              title: 'No Tools Available',
              subtitle: 'Add some tools to see cost analytics',
              icon: Icons.analytics,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period and Category Filters
                _buildFilters(tools),
                const SizedBox(height: 24),

                // Key Metrics Cards
                _buildKeyMetrics(tools),
                const SizedBox(height: 24),

                // Cost Breakdown Chart
                _buildCostBreakdown(tools),
                const SizedBox(height: 24),

                // Top Expensive Tools
                _buildTopExpensiveTools(tools),
                const SizedBox(height: 24),

                // Category Analysis
                _buildCategoryAnalysis(tools),
                const SizedBox(height: 24),

                // Depreciation Analysis
                _buildDepreciationAnalysis(tools),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<Tool> tools) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: const InputDecoration(
              labelText: 'Time Period',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: const [
              DropdownMenuItem(value: 'This Week', child: Text('This Week')),
              DropdownMenuItem(value: 'This Month', child: Text('This Month')),
              DropdownMenuItem(value: 'This Year', child: Text('This Year')),
              DropdownMenuItem(value: 'All Time', child: Text('All Time')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPeriod = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: [
              const DropdownMenuItem(value: 'All', child: Text('All Categories')),
              ..._getUniqueCategories(tools).map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(List<Tool> tools) {
    final filteredTools = _filterTools(tools);
    final totalValue = _calculateTotalValue(filteredTools);
    final totalPurchaseCost = _calculateTotalPurchaseCost(filteredTools);
    final depreciation = totalPurchaseCost - totalValue;
    final averageToolValue = filteredTools.isNotEmpty ? totalValue / filteredTools.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Value',
                '\$${totalValue.toStringAsFixed(2)}',
                Icons.attach_money,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Investment',
                '\$${totalPurchaseCost.toStringAsFixed(2)}',
                Icons.shopping_cart,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Depreciation',
                '\$${depreciation.toStringAsFixed(2)}',
                Icons.trending_down,
                AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Tool Value',
                '\$${averageToolValue.toStringAsFixed(2)}',
                Icons.analytics,
                AppTheme.successColor,
              ),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(List<Tool> tools) {
    final filteredTools = _filterTools(tools);
    final categoryBreakdown = _getCategoryBreakdown(filteredTools);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Breakdown by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryBreakdown.entries.map((entry) {
              final percentage = (entry.value / _calculateTotalValue(filteredTools)) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(entry.key),
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

  Widget _buildTopExpensiveTools(List<Tool> tools) {
    final filteredTools = _filterTools(tools);
    final sortedTools = List<Tool>.from(filteredTools)
      ..sort((a, b) => (b.currentValue ?? 0.0).compareTo(a.currentValue ?? 0.0));

    final topTools = sortedTools.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Valuable Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...topTools.map((tool) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.build,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            tool.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(tool.currentValue ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
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

  Widget _buildCategoryAnalysis(List<Tool> tools) {
    final filteredTools = _filterTools(tools);
    final categoryStats = _getCategoryStatistics(filteredTools);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryStats.entries.map((entry) {
              final stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(entry.key).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(entry.key).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('Count', '${stats['count']}'),
                          ),
                          Expanded(
                            child: _buildStatItem('Total Value', '\$${stats['totalValue'].toStringAsFixed(2)}'),
                          ),
                          Expanded(
                            child: _buildStatItem('Avg Value', '\$${stats['avgValue'].toStringAsFixed(2)}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepreciationAnalysis(List<Tool> tools) {
    final filteredTools = _filterTools(tools);
    final depreciationData = _getDepreciationData(filteredTools);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Depreciation Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Depreciation',
                    '\$${depreciationData['totalDepreciation'].toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Depreciation',
                    '\$${depreciationData['avgDepreciation'].toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tools with Highest Depreciation:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...depreciationData['topDepreciated'].map<Widget>((tool) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tool.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${tool.depreciation.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  List<Tool> _filterTools(List<Tool> tools) {
    var filtered = tools;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((tool) => tool.category == _selectedCategory).toList();
    }
    
    // Add time period filtering logic here if needed
    return filtered;
  }

  List<String> _getUniqueCategories(List<Tool> tools) {
    return tools.map((tool) => tool.category).toSet().toList();
  }

  double _calculateTotalValue(List<Tool> tools) {
    return tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0.0));
  }

  double _calculateTotalPurchaseCost(List<Tool> tools) {
    return tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0.0));
  }

  Map<String, double> _getCategoryBreakdown(List<Tool> tools) {
    final breakdown = <String, double>{};
    for (final tool in tools) {
      breakdown[tool.category] = (breakdown[tool.category] ?? 0.0) + (tool.currentValue ?? 0.0);
    }
    return breakdown;
  }

  Map<String, Map<String, dynamic>> _getCategoryStatistics(List<Tool> tools) {
    final stats = <String, Map<String, dynamic>>{};
    for (final tool in tools) {
      if (!stats.containsKey(tool.category)) {
        stats[tool.category] = {
          'count': 0,
          'totalValue': 0.0,
          'avgValue': 0.0,
        };
      }
      stats[tool.category]!['count']++;
      stats[tool.category]!['totalValue'] += (tool.currentValue ?? 0.0);
    }
    
    // Calculate averages
    for (final entry in stats.entries) {
      final count = entry.value['count'] as int;
      final totalValue = entry.value['totalValue'] as double;
      entry.value['avgValue'] = totalValue / count;
    }
    
    return stats;
  }

  Map<String, dynamic> _getDepreciationData(List<Tool> tools) {
    final totalDepreciation = tools.fold(0.0, (sum, tool) => sum + ((tool.purchasePrice ?? 0.0) - (tool.currentValue ?? 0.0)));
    final avgDepreciation = tools.isNotEmpty ? totalDepreciation / tools.length : 0.0;
    
    final toolsWithDepreciation = tools.map((tool) => {
      'tool': tool,
      'depreciation': (tool.purchasePrice ?? 0.0) - (tool.currentValue ?? 0.0),
    }).toList();
    
    toolsWithDepreciation.sort((a, b) => (b['depreciation'] as double).compareTo(a['depreciation'] as double));
    
    return {
      'totalDepreciation': totalDepreciation,
      'avgDepreciation': avgDepreciation,
      'topDepreciated': toolsWithDepreciation.take(5).toList(),
    };
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
    ];
    return colors[category.hashCode % colors.length];
  }
}
