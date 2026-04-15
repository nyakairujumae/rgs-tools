import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/tool_history.dart';
import '../services/tool_history_service.dart';
import '../services/user_name_service.dart';
import '../services/report_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/auth_error_handler.dart';
import '../utils/navigation_helper.dart';

/// Global tool history — UI aligned with web `dashboard/history` (Audit Trail).
class AllToolHistoryScreen extends StatefulWidget {
  const AllToolHistoryScreen({super.key});

  @override
  State<AllToolHistoryScreen> createState() => _AllToolHistoryScreenState();
}

class _AllToolHistoryScreenState extends State<AllToolHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Matches web: `actionFilter` — 'all' or exact [ToolHistory.action] string.
  String _actionFilter = 'all';

  bool _isLoading = true;
  bool _isExporting = false;
  List<ToolHistory> _historyItems = [];

  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final isAdmin = auth.isAdmin;
      final userId = auth.userId;

      final items = (!isAdmin && userId != null && userId.isNotEmpty)
          ? await ToolHistoryService.getHistoryForTechnician(userId)
          : await ToolHistoryService.getAllHistory();

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

  List<String> get _distinctActions {
    final set = _historyItems.map((h) => h.action).toSet();
    final list = set.toList()..sort();
    return list;
  }

  List<ToolHistory> get _filtered {
    var result = _historyItems;
    if (_actionFilter != 'all') {
      result = result.where((h) => h.action == _actionFilter).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((h) {
        return h.toolName.toLowerCase().contains(q) ||
            h.description.toLowerCase().contains(q) ||
            (h.performedBy?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) return '-';
    try {
      final dt = DateTime.parse(ts);
      return _dateTimeFormat.format(dt.toLocal());
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.45);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: colorScheme.onSurface),
          onPressed: () => NavigationHelper.safePop(context),
        ),
        titleSpacing: 4,
        title: Text(
          'Audit Trail',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
            child: FilledButton(
              onPressed: _isExporting ? null : _exportReport,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate report',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              (context.read<AuthProvider>().isAdmin)
                  ? 'Complete history of all tool actions'
                  : 'History for your assigned and related tools',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                    cursorColor: AppTheme.secondaryColor,
                    decoration: context.dashboardSurfaceInputDecoration(
                      hintText: 'Search history…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 20, color: muted),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      borderRadius: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionDropdown(colorScheme, muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppTheme.secondaryColor,
                    child: _filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Text(
                                  'No history found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: muted,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildHistoryList(colorScheme, muted),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDropdown(ColorScheme colorScheme, Color muted) {
    final actions = _distinctActions;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        value: _actionFilter == 'all' || actions.contains(_actionFilter) ? _actionFilter : 'all',
        decoration: context.dashboardSurfaceInputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          borderRadius: 12,
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: muted),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        dropdownColor: context.dashboardSurfaceFill,
        borderRadius: BorderRadius.circular(12),
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All Actions')),
          ...actions.map(
            (a) => DropdownMenuItem(
              value: a,
              child: Text(a, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => _actionFilter = v);
        },
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme, Color muted) {
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.12);
    final items = _filtered;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: borderColor),
          itemBuilder: (context, index) {
            final h = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 16,
                      color: muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                h.action,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                h.toolName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h.description,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        if (h.oldValue != null || h.newValue != null) ...[
                          const SizedBox(height: 6),
                          _buildOldNewRow(h.oldValue, h.newValue, muted),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (h.performedBy != null && h.performedBy!.isNotEmpty)
                              Text(
                                'by ${h.performedBy}',
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                            Text(
                              _formatTimestamp(h.timestamp),
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOldNewRow(
    String? oldValue,
    String? newValue,
    Color muted,
  ) {
    if (oldValue == null && newValue == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (oldValue != null)
          Expanded(
            child: _resolvedIdText(
              oldValue,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF87171),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        if (oldValue != null && newValue != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 12, color: muted),
          ),
        ],
        if (newValue != null)
          Expanded(
            child: _resolvedIdText(
              newValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF34D399),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resolvedIdText(String value, {required TextStyle style}) {
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
    if (!isUuid) {
      return Text(
        value,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return FutureBuilder<String>(
      future: UserNameService.getUserName(value),
      builder: (context, snapshot) {
        final display = snapshot.hasData ? snapshot.data! : value;
        return Text(
          display,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
