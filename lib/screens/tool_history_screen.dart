import 'package:flutter/material.dart';
import '../models/tool_history.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';

class ToolHistoryScreen extends StatefulWidget {
  final int toolId;
  final String toolName;

  const ToolHistoryScreen({
    super.key,
    required this.toolId,
    required this.toolName,
  });

  @override
  State<ToolHistoryScreen> createState() => _ToolHistoryScreenState();
}

class _ToolHistoryScreenState extends State<ToolHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.toolName} History'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // History List
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Recent', 'Assignments', 'Maintenance', 'Updates'];
    
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
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
                setState(() {
                  _selectedFilter = filter;
                });
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

  Widget _buildHistoryList() {
    final historyItems = ToolHistoryService.getMockHistory();
    final filteredItems = _filterHistoryItems(historyItems);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Recent':
        title = 'No Recent Activity';
        subtitle = 'No recent changes to this tool';
        icon = Icons.schedule;
        break;
      case 'Assignments':
        title = 'No Assignment History';
        subtitle = 'This tool has not been assigned yet';
        icon = Icons.person_add;
        break;
      case 'Maintenance':
        title = 'No Maintenance History';
        subtitle = 'No maintenance has been performed on this tool';
        icon = Icons.build;
        break;
      case 'Updates':
        title = 'No Update History';
        subtitle = 'This tool has not been updated yet';
        icon = Icons.edit;
        break;
      default:
        title = 'No History Available';
        subtitle = 'No history records found for this tool';
        icon = Icons.history;
    }

    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
    );
  }

  Widget _buildHistoryCard(ToolHistory item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getActionColor(item.action).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getActionIcon(item.action),
                    color: _getActionColor(item.action),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.actionDisplayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recent',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Description
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            
            // Value Changes
            if (item.oldValue != null && item.newValue != null) ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      'From: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      item.oldValue!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 16),
                    Text(
                      'To: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      item.newValue!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Performed By
            if (item.performedBy != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Performed by: ${item.performedBy}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.performedByRole != null) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.performedByRole!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Location
            if (item.location != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    item.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            
            // Notes
            if (item.notes != null) ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<ToolHistory> _filterHistoryItems(List<ToolHistory> items) {
    switch (_selectedFilter) {
      case 'Recent':
        return items.where((item) => item.isRecent).toList();
      case 'Assignments':
        return items.where((item) => 
          item.action == ToolHistoryActions.assigned || 
          item.action == ToolHistoryActions.returned ||
          item.action == ToolHistoryActions.transferred
        ).toList();
      case 'Maintenance':
        return items.where((item) => item.action == ToolHistoryActions.maintenance).toList();
      case 'Updates':
        return items.where((item) => 
          item.action == ToolHistoryActions.updated ||
          item.action == ToolHistoryActions.statusChanged ||
          item.action == ToolHistoryActions.conditionChanged ||
          item.action == ToolHistoryActions.valueUpdated ||
          item.action == ToolHistoryActions.notesUpdated
        ).toList();
      default:
        return items;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case ToolHistoryActions.created:
        return AppTheme.successColor;
      case ToolHistoryActions.assigned:
        return AppTheme.primaryColor;
      case ToolHistoryActions.returned:
        return AppTheme.secondaryColor;
      case ToolHistoryActions.maintenance:
        return AppTheme.warningColor;
      case ToolHistoryActions.updated:
        return AppTheme.accentColor;
      case ToolHistoryActions.deleted:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case ToolHistoryActions.created:
        return Icons.add_circle;
      case ToolHistoryActions.assigned:
        return Icons.person_add;
      case ToolHistoryActions.returned:
        return Icons.assignment_return;
      case ToolHistoryActions.maintenance:
        return Icons.build;
      case ToolHistoryActions.updated:
        return Icons.edit;
      case ToolHistoryActions.deleted:
        return Icons.delete;
      case ToolHistoryActions.transferred:
        return Icons.swap_horiz;
      case ToolHistoryActions.statusChanged:
        return Icons.toggle_on;
      case ToolHistoryActions.locationChanged:
        return Icons.location_on;
      case ToolHistoryActions.conditionChanged:
        return Icons.construction;
      case ToolHistoryActions.valueUpdated:
        return Icons.attach_money;
      case ToolHistoryActions.imageAdded:
        return Icons.image;
      case ToolHistoryActions.notesUpdated:
        return Icons.note;
      default:
        return Icons.history;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All', 'Show all history'),
            _buildFilterOption('Recent', 'Show recent activity (last 24 hours)'),
            _buildFilterOption('Assignments', 'Show assignment changes'),
            _buildFilterOption('Maintenance', 'Show maintenance records'),
            _buildFilterOption('Updates', 'Show tool updates'),
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

  Widget _buildFilterOption(String filter, String description) {
    return ListTile(
      title: Text(filter),
      subtitle: Text(description),
      trailing: _selectedFilter == filter ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
    );
  }
}
