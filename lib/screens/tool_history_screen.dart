import 'package:flutter/material.dart';
import '../models/tool_history.dart';
import '../services/tool_history_service.dart';
import '../services/user_name_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_widget.dart';

class ToolHistoryScreen extends StatefulWidget {
  final String toolId;
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
  List<ToolHistory> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await ToolHistoryService.getHistoryForTool(widget.toolId);
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text('${widget.toolName} History'),
        backgroundColor: context.appBarBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppTheme.secondaryColor,
                    child: _buildHistoryList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
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
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    : theme.colorScheme.onSurface.withValues(alpha: 0.12),
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
    final filteredItems = _filterHistoryItems(_historyItems);

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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.cardDecoration,
      clipBehavior: Clip.antiAlias,
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
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            // Value Changes (resolve user IDs to names for clearer display)
            if (item.oldValue != null && item.newValue != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'From: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Expanded(
                          child: _buildValueDisplay(
                            context,
                            item.oldValue!,
                            theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          'To: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Expanded(
                          child: _buildValueDisplay(
                            context,
                            item.newValue!,
                            AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            // Performed By
            if (item.performedBy != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Performed by: ${item.performedBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 4),
                  Text(
                    item.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: context.inputBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  /// Display value - resolves user IDs (UUIDs) to names when possible
  Widget _buildValueDisplay(BuildContext context, String value, Color textColor) {
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
    if (!isUuid) {
      return Text(
        value,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    return FutureBuilder<String>(
      future: UserNameService.getUserName(value),
      builder: (context, snapshot) {
        final display = snapshot.hasData ? snapshot.data! : value;
        return Text(
          display,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
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
          item.action == ToolHistoryActions.transferred ||
          item.action == ToolHistoryActions.badged ||
          item.action == ToolHistoryActions.releasedBadge ||
          item.action == ToolHistoryActions.releasedToRequester
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
      case ToolHistoryActions.badged:
        return AppTheme.primaryColor;
      case ToolHistoryActions.returned:
      case ToolHistoryActions.releasedBadge:
      case ToolHistoryActions.releasedToRequester:
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
      case ToolHistoryActions.badged:
        return Icons.person_add;
      case ToolHistoryActions.returned:
      case ToolHistoryActions.releasedBadge:
      case ToolHistoryActions.releasedToRequester:
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

}
