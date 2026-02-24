import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/tool_history.dart';
import '../services/tool_history_service.dart';
import '../services/user_name_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/auth_error_handler.dart';

class AllToolHistoryScreen extends StatefulWidget {
  const AllToolHistoryScreen({super.key});

  @override
  State<AllToolHistoryScreen> createState() => _AllToolHistoryScreenState();
}

class _AllToolHistoryScreenState extends State<AllToolHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isExporting = false;
  List<ToolHistory> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await ToolHistoryService.getAllHistory();
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

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      final file = await ReportService.generateToolMovementHistoryReport(
        historyItems: _historyItems,
      );
      if (mounted) {
        setState(() => _isExporting = false);
        AuthErrorHandler.showSuccessSnackBar(context, 'Report exported successfully');
        try {
          await OpenFile.open(file.path);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        AuthErrorHandler.showErrorSnackBar(context, 'Error exporting report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tool History'),
        backgroundColor: context.appBarBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isExporting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                    ),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _isExporting ? null : _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Recent', 'Assignments', 'Maintenance', 'Updates'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f),
              selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.secondaryColor,
            ),
          );
        }).toList(),
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
      itemBuilder: (context, index) => _buildHistoryCard(filteredItems[index]),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    switch (_selectedFilter) {
      case 'Recent':
        title = 'No Recent Activity';
        subtitle = 'No recent changes across all tools';
        icon = Icons.schedule;
        break;
      case 'Assignments':
        title = 'No Assignment History';
        subtitle = 'No assignment records found';
        icon = Icons.person_add;
        break;
      case 'Maintenance':
        title = 'No Maintenance History';
        subtitle = 'No maintenance records found';
        icon = Icons.build;
        break;
      case 'Updates':
        title = 'No Update History';
        subtitle = 'No update records found';
        icon = Icons.edit;
        break;
      default:
        title = 'No History Available';
        subtitle = 'No history records found';
        icon = Icons.history;
    }
    return EmptyState(title: title, subtitle: subtitle, icon: icon);
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
                const SizedBox(width: 12),
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
                        '${item.toolName} • ${item.timeAgo}',
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
            const SizedBox(height: 12),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (item.oldValue != null && item.newValue != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Container(
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
                          child: _buildValueDisplay(context, item.oldValue!, theme.colorScheme.onSurface),
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
                          child: _buildValueDisplay(context, item.newValue!, AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ],
            if (item.performedBy != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    item.performedBy!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

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
            item.action == ToolHistoryActions.releasedToRequester).toList();
      case 'Maintenance':
        return items.where((item) => item.action == ToolHistoryActions.maintenance).toList();
      case 'Updates':
        return items.where((item) =>
            item.action == ToolHistoryActions.updated ||
            item.action == ToolHistoryActions.statusChanged ||
            item.action == ToolHistoryActions.conditionChanged ||
            item.action == ToolHistoryActions.valueUpdated ||
            item.action == ToolHistoryActions.notesUpdated).toList();
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
