import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../models/tool_history.dart';
import '../services/tool_history_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/empty_state.dart';
import '../utils/responsive_helper.dart';

class AllToolHistoryScreen extends StatefulWidget {
  const AllToolHistoryScreen({super.key});

  @override
  State<AllToolHistoryScreen> createState() => _AllToolHistoryScreenState();
}

class _AllToolHistoryScreenState extends State<AllToolHistoryScreen> {
  List<ToolHistory> _historyItems = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String _actionFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await ToolHistoryService.getAllHistory(
        actionFilter: _actionFilter.isEmpty ? null : _actionFilter,
        startDate: _startDate,
        endDate: _endDate,
        limit: 200,
      );
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
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() => _isExporting = false);
        final path = file.path;
        await OpenFile.open(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to $path'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tool Movement History'),
        backgroundColor: context.scaffoldBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          TextButton.icon(
            onPressed: _isExporting || _historyItems.isEmpty ? null : _exportReport,
            icon: _isExporting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                  )
                : const Icon(Icons.download, size: 20),
            label: const Text('Generate Report'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppTheme.secondaryColor,
                    child: _historyItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 12),
                            itemCount: _historyItems.length,
                            itemBuilder: (context, index) => _buildHistoryCard(_historyItems[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final actions = [
      '',
      ToolHistoryActions.badged,
      ToolHistoryActions.releasedBadge,
      ToolHistoryActions.releasedToRequester,
      ToolHistoryActions.assigned,
      ToolHistoryActions.returned,
      ToolHistoryActions.maintenance,
      ToolHistoryActions.updated,
    ];
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _actionFilter.isEmpty ? '' : _actionFilter,
              decoration: InputDecoration(
                labelText: 'Action',
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Actions')),
                ...actions.where((a) => a.isNotEmpty).map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a),
                    )),
              ],
              onChanged: (v) {
                setState(() {
                  _actionFilter = v ?? '';
                  _loadHistory();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 30)),
                        end: DateTime.now(),
                      ),
              );
              if (range != null && mounted) {
                setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                  _loadHistory();
                });
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_startDate != null ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}' : 'Date Range'),
          ),
          if (_startDate != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _loadHistory();
                });
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'No History Available',
      subtitle: 'No tool movement history found. History is recorded when tools are badged, released, assigned, or updated.',
      icon: Icons.history,
    );
  }

  Widget _buildHistoryCard(ToolHistory item) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(context, item.action).withValues(alpha: 0.15),
          child: Icon(_getActionIcon(item.action), color: _getActionColor(context, item.action), size: 22),
        ),
        title: Text(
          item.actionDisplayName,
          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.toolName, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
            Text(item.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            if (item.performedBy != null)
              Text('by ${item.performedBy}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
        trailing: Text(
          item.timeAgo,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Color _getActionColor(BuildContext context, String action) {
    final theme = Theme.of(context);
    switch (action) {
      case ToolHistoryActions.badged:
      case ToolHistoryActions.assigned:
        return AppTheme.primaryColor;
      case ToolHistoryActions.releasedBadge:
      case ToolHistoryActions.releasedToRequester:
      case ToolHistoryActions.returned:
        return AppTheme.secondaryColor;
      case ToolHistoryActions.maintenance:
        return AppTheme.warningColor;
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case ToolHistoryActions.badged:
      case ToolHistoryActions.assigned:
        return Icons.person_add;
      case ToolHistoryActions.releasedBadge:
      case ToolHistoryActions.releasedToRequester:
      case ToolHistoryActions.returned:
        return Icons.assignment_return;
      case ToolHistoryActions.maintenance:
        return Icons.build;
      default:
        return Icons.history;
    }
  }
}
