import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'technician_add_tool_screen.dart';
import 'add_tool_screen.dart';
import 'tool_detail_screen.dart';

class TechnicianMyToolsScreen extends StatefulWidget {
  const TechnicianMyToolsScreen({super.key});

  @override
  State<TechnicianMyToolsScreen> createState() => _TechnicianMyToolsScreenState();
}

class _TechnicianMyToolsScreenState extends State<TechnicianMyToolsScreen> {
  /// Must stay in sync with the status [DropdownMenuItem] values.
  static const List<String> _statusFilterItems = [
    'All',
    'Available',
    'Assigned',
    'In Use',
    'Maintenance',
    'Retired',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final ScrollController _tableScrollController = ScrollController();
  bool _requestedInitialScrollReset = false;
  /// Web: false=grid, true=list (matches [ToolsScreen]).
  bool _webViewList = false;
  /// Mobile: true=list (default), false=grid (matches [ToolsScreen]).
  bool _isListView = true;

  void _normalizeStatusFilter() {
    if (!_statusFilterItems.contains(_selectedStatus)) {
      _selectedStatus = 'All';
    }
  }

  @override
  void initState() {
    super.initState();
    _normalizeStatusFilter();
    _searchController.addListener(() {
      final v = _searchController.text;
      if (v != _searchQuery) setState(() => _searchQuery = v);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
    // Ensure the "NAME" column (with the thumbnail/icon) is visible.
    // Only relevant in list/table mode.
    if (_isListView) {
      _requestScrollReset();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload can keep old state (e.g. 'All Status') that no longer matches [DropdownMenuItem]s.
    _normalizeStatusFilter();
  }

  void _requestScrollReset([int attemptsLeft = 5]) {
    if (_requestedInitialScrollReset) return;
    _requestedInitialScrollReset = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tableScrollController.hasClients) {
        _tableScrollController.jumpTo(0);
        return;
      }

      if (attemptsLeft > 0) {
        _requestedInitialScrollReset = false; // allow retry
        _requestScrollReset(attemptsLeft - 1);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _openAddTool() async {
    final authProvider = context.read<AuthProvider>();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => authProvider.isAdmin
            ? const AddToolScreen(isFromMyTools: true)
            : const TechnicianAddToolScreen(),
      ),
    );
    if (added == true && mounted) {
      await context.read<SupabaseToolProvider>().loadTools();
    }
  }

  bool _matchesSearch(Tool tool) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return tool.name.toLowerCase().contains(q) ||
        tool.category.toLowerCase().contains(q) ||
        (tool.brand?.toLowerCase().contains(q) ?? false) ||
        (tool.model?.toLowerCase().contains(q) ?? false) ||
        (tool.serialNumber?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Consumer3<SupabaseToolProvider, AuthProvider, ConnectivityProvider>(
          builder: (context, toolProvider, authProvider, connectivity, _) {
            final currentUserId = authProvider.userId;
            final allMyTools = currentUserId == null
                ? <Tool>[]
                : toolProvider.tools
                    .where((t) => t.assignedTo == currentUserId)
                    .toList();

            final filtered = allMyTools.where((t) {
              final matchesSearch = _matchesSearch(t);
              final matchesStatus =
                  _selectedStatus == 'All' || t.status == _selectedStatus;
              return matchesSearch && matchesStatus;
            }).toList();

            final hasActiveFilter =
                _searchQuery.isNotEmpty || _selectedStatus != 'All';
            final showList = kIsWeb ? _webViewList : _isListView;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('My Tools',
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5, color: colorScheme.onSurface)),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Tools assigned to you · ${allMyTools.length} total',
                              style: TextStyle(fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _openAddTool,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Tool', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter bar (aligned with [ToolsScreen]) ─────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    kIsWeb ? 24 : 16,
                    12,
                    kIsWeb ? 24 : 16,
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search tools…',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 17,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            FocusScope.of(context).unfocus();
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: theme.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!kIsWeb)
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _viewToggleBtn(
                                    icon: Icons.view_list_rounded,
                                    active: _isListView,
                                    onTap: () {
                                      setState(() => _isListView = true);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (_tableScrollController.hasClients) {
                                          _tableScrollController.jumpTo(0);
                                        }
                                      });
                                    },
                                  ),
                                  _viewToggleBtn(
                                    icon: Icons.grid_view_rounded,
                                    active: !_isListView,
                                    onTap: () => setState(() => _isListView = false),
                                  ),
                                ],
                              ),
                            ),
                          if (kIsWeb)
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _viewToggleBtn(
                                    icon: Icons.view_list_rounded,
                                    active: _webViewList,
                                    onTap: () {
                                      setState(() => _webViewList = true);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (_tableScrollController.hasClients) {
                                          _tableScrollController.jumpTo(0);
                                        }
                                      });
                                    },
                                  ),
                                  _viewToggleBtn(
                                    icon: Icons.grid_view_rounded,
                                    active: !_webViewList,
                                    onTap: () => setState(() => _webViewList = false),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _filterDropdown(
                            value: _selectedStatus,
                            resetLabel: 'All Status',
                            items: _statusFilterItems,
                            hint: 'Status',
                            onChanged: (v) =>
                                setState(() => _selectedStatus = v!),
                          ),
                          if (hasActiveFilter) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _selectedStatus = 'All');
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tools Grid (icon/tile mode) ───────────────────────────
                Expanded(
                  child: toolProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? _buildEmpty(colorScheme)
                          : showList
                              ? _buildTable(filtered, colorScheme, isDark)
                              : _buildToolsGrid(context, filtered, colorScheme, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Filter dropdown pill — same as [ToolsScreen._filterDropdown].
  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required String resetLabel,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = value != hint && value != 'All' && value != 'Category';

    String displayText(String item) {
      if (item == 'All' || item == 'Category') return resetLabel;
      return item;
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: hint == 'Category',
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isActive
                ? AppTheme.primaryColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? AppTheme.primaryColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          menuMaxHeight: 300,
          borderRadius: BorderRadius.circular(10),
          selectedItemBuilder: (_) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText(item),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
              .toList(),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    displayText(item),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTable(List<Tool> tools, ColorScheme colorScheme, bool isDark) {
    const colName    = 180.0;
    const colCat     = 130.0;
    const colStatus  = 100.0;
    const colCond    = 100.0;
    const colAction  = 48.0;
    const horizontalPadding = 16.0; // matches Padding(horizontal: 16) below
    const totalW = colName + colCat + colStatus + colCond + colAction + (horizontalPadding * 2);

    final headerStyle = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
      letterSpacing: 0.3,
    );
    final divColor = colorScheme.onSurface.withValues(alpha: 0.07);

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final tableHeight = viewportConstraints.maxHeight.isFinite
            ? viewportConstraints.maxHeight
            : (MediaQuery.of(context).size.height * 0.6);

        return SingleChildScrollView(
          controller: _tableScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            height: tableHeight,
            child: Column(
              children: [
                // Header row
                Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.025),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      SizedBox(width: colName, child: Text('NAME', style: headerStyle)),
                      SizedBox(width: colCat, child: Text('CATEGORY', style: headerStyle)),
                      SizedBox(width: colStatus, child: Text('STATUS', style: headerStyle)),
                      SizedBox(width: colCond, child: Text('CONDITION', style: headerStyle)),
                      SizedBox(width: colAction),
                    ]),
                  ),
                ),
                Divider(height: 1, thickness: 0.5, color: divColor),

                // Rows
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<SupabaseToolProvider>().loadTools(),
                    child: ListView.separated(
                      itemCount: tools.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: divColor,
                      ),
                      itemBuilder: (context, i) => _buildRow(
                        tools[i],
                        colorScheme,
                        isDark,
                        colName,
                        colCat,
                        colStatus,
                        colCond,
                        colAction,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolsGrid(
    BuildContext context,
    List<Tool> tools,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 380 ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tools.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, i) =>
          _buildToolGridCard(context, tools[i], colorScheme, isDark),
    );
  }

  Widget _buildToolGridCard(
    BuildContext context,
    Tool tool,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final imagePath = tool.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? (imagePath!.startsWith('http') || kIsWeb)
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: _thumbPlaceholder(colorScheme),
                              ),
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: _thumbPlaceholder(colorScheme),
                              ),
                            )
                      : Center(child: _thumbPlaceholder(colorScheme)),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _statusPill(tool.status, isDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tool.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tool.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Tool tool, ColorScheme colorScheme, bool isDark,
      double colName, double colCat, double colStatus, double colCond, double colAction) {
    final imagePath = tool.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Name + thumbnail
            SizedBox(
              width: colName,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: hasImage && (imagePath!.startsWith('http') || kIsWeb)
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbPlaceholder(colorScheme),
                            )
                          : _thumbPlaceholder(colorScheme),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface)),
                        if (tool.model != null && tool.model!.isNotEmpty)
                          Text(tool.model!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.45))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category
            SizedBox(
              width: colCat,
              child: Text(tool.category,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ),

            // Status
            SizedBox(
              width: colStatus,
              child: _statusPill(tool.status, isDark),
            ),

            // Condition
            SizedBox(
              width: colCond,
              child: Text(tool.condition,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ),

            // Action
            SizedBox(
              width: colAction,
              child: Icon(Icons.chevron_right_rounded, size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ColorScheme colorScheme) {
    return Icon(Icons.build_rounded, size: 18,
        color: colorScheme.onSurface.withValues(alpha: 0.2));
  }

  Widget _statusPill(String status, bool isDark) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = const Color(0xFF0FA958);
        break;
      case 'in use':
      case 'assigned':
        color = const Color(0xFF3B82F6);
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          maxLines: 1,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    final hasFilter = _searchQuery.isNotEmpty || _selectedStatus != 'All';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            hasFilter ? 'No tools match your filters' : 'No tools assigned to you',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter ? 'Try adjusting your search or filters' : 'Tools assigned to you will appear here',
            style: TextStyle(fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }

  Widget _viewToggleBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFF0F0F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
