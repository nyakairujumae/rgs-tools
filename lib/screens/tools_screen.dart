import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../utils/file_helper.dart' if (dart.library.html) '../utils/file_helper_stub.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../models/tool.dart';
import '../models/tool_group.dart';
import 'tool_detail_screen.dart';
import 'tool_instances_screen.dart';
import 'technicians_screen.dart';
import 'permanent_assignment_screen.dart';
import 'add_tool_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../widgets/common/offline_sync_banner.dart';
import '../providers/connectivity_provider.dart';
import '../utils/navigation_helper.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final bool isSelectionMode;
  final bool selectionForShared;

  const ToolsScreen({
    super.key,
    this.initialStatusFilter,
    this.isSelectionMode = false,
    this.selectionForShared = false,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Category';
  late String _selectedStatus;
  String _searchQuery = '';
  Set<String> _selectedTools = <String>{};
  /// Web: false=grid, true=list
  bool _webViewList = false;
  /// Mobile: true=list (default), false=grid
  bool _isListView = true;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter ?? 'All';
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
  }

  Future<void> _refresh() async {
    await context.read<SupabaseToolProvider>().loadTools();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text;
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        final tools = toolProvider.tools;
        final categories = [
          'Category',
          ...toolProvider.getCategories(),
        ];

        final filteredTools = tools.where((tool) {
          final matchesSearch = _matchesSmartSearch(tool);
          final matchesCategory =
              _selectedCategory == 'Category' || tool.category == _selectedCategory;
          final matchesStatus =
              _selectedStatus == 'All' || tool.status == _selectedStatus;
          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();

        // Sort alphabetically by name for list view
        filteredTools.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final toolGroups = ToolGroup.groupTools(filteredTools);
        final theme = Theme.of(context);
        final hasActiveFilter = _searchQuery.isNotEmpty ||
            _selectedStatus != 'All' ||
            _selectedCategory != 'Category';

        return Scaffold(
          backgroundColor: context.scaffoldBackground,
          body: SafeArea(
            bottom: false,
            child: Container(
              color: context.scaffoldBackground,
              child: Column(
                children: [
                  // ── Selection mode header ──────────────────────────────
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left,
                                size: 24,
                                color: theme.colorScheme.onSurface),
                            onPressed: () => NavigationHelper.safePop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Select Tools',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                )),
                          ),
                        ],
                      ),
                    ),

                  // ── Normal header ──────────────────────────────────────
                  if (!widget.isSelectionMode)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        kIsWeb ? 24 : 16,
                        kIsWeb ? 28 : 20,
                        kIsWeb ? 24 : 16,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (Navigator.canPop(context)) ...[
                            IconButton(
                              icon: Icon(Icons.chevron_left,
                                  size: 24,
                                  color: theme.colorScheme.onSurface),
                              onPressed: () => NavigationHelper.safePop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Tools',
                                        style: TextStyle(
                                          fontSize: kIsWeb ? 32 : 30,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    // Add Tool button
                                    FilledButton.icon(
                                      onPressed: () async {
                                        final added = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const AddToolScreen()),
                                        );
                                        if (added == true && context.mounted) {
                                          await toolProvider.loadTools();
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Tool',
                                          style: TextStyle(fontSize: 13)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 0),
                                        minimumSize: const Size(0, 36),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tools.length} tools in inventory',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Filter bar ─────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        kIsWeb ? 24 : 16, 12, kIsWeb ? 24 : 16, 0),
                    child: Column(
                      children: [
                        // Row 1: search + view toggle
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
                                    prefixIcon: Icon(Icons.search,
                                        size: 17,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4)),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.close,
                                                size: 16,
                                                color: theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.4)),
                                            onPressed: () {
                                              _searchController.clear();
                                              FocusScope.of(context).unfocus();
                                            },
                                          )
                                        : null,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                            // View toggle (ml-auto like web)
                            if (!kIsWeb)
                              Container(
                                height: 38,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
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
                                      onTap: () =>
                                          setState(() => _isListView = true),
                                    ),
                                    _viewToggleBtn(
                                      icon: Icons.grid_view_rounded,
                                      active: !_isListView,
                                      onTap: () =>
                                          setState(() => _isListView = false),
                                    ),
                                  ],
                                ),
                              ),
                            if (kIsWeb)
                              Container(
                                height: 38,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
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
                                      onTap: () =>
                                          setState(() => _webViewList = true),
                                    ),
                                    _viewToggleBtn(
                                      icon: Icons.grid_view_rounded,
                                      active: !_webViewList,
                                      onTap: () =>
                                          setState(() => _webViewList = false),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: status + category dropdowns + clear
                        Row(
                          children: [
                            _filterDropdown(
                              value: _selectedStatus,
                              resetLabel: 'All Status',
                              items: const [
                                'All',
                                'Available',
                                'Assigned',
                                'In Use',
                                'Maintenance',
                                'Retired',
                              ],
                              hint: 'Status',
                              onChanged: (v) =>
                                  setState(() => _selectedStatus = v!),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _filterDropdown(
                                value: _selectedCategory,
                                items: categories,
                                hint: 'Category',
                                resetLabel: 'All Categories',
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v!),
                              ),
                            ),
                            if (hasActiveFilter) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _selectedStatus = 'All';
                                    _selectedCategory = 'Category';
                                  });
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

                  // ── Content ────────────────────────────────────────────
                  Expanded(
                    child: RefreshIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2.5,
                      onRefresh: _refresh,
                      child: Consumer<ConnectivityProvider>(
                        builder: (context, connectivityProvider, _) {
                          final isOffline = !connectivityProvider.isOnline;

                          if (isOffline &&
                              (toolProvider.isLoading || filteredTools.isEmpty)) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OfflineSyncBanner(isOffline: isOffline),
                                const Expanded(
                                  child: OfflineToolGridSkeleton(
                                    itemCount: 6,
                                    crossAxisCount: 2,
                                    message: 'You are offline. Showing cached data.',
                                  ),
                                ),
                              ],
                            );
                          }

                          Widget content;
                          if (toolProvider.isLoading) {
                            content = (!kIsWeb && _isListView)
                                ? const ToolListSkeleton(itemCount: 8)
                                : ToolCardGridSkeleton(
                                    itemCount: kIsWeb ? 6 : 8,
                                    crossAxisCount: kIsWeb ? 2 : 2,
                                    crossAxisSpacing: 12.0,
                                    mainAxisSpacing: 16.0,
                                    childAspectRatio: kIsWeb ? 0.75 : 0.7,
                                  );
                          } else if (filteredTools.isEmpty) {
                            content = _buildEmptyState(context);
                          } else {
                            content = LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop =
                                    kIsWeb && constraints.maxWidth >= 900;
                                if (isDesktop) {
                                  return _webViewList
                                      ? _buildWebToolsTable(context, toolGroups)
                                      : _buildWebGrid(
                                          context, toolGroups, constraints.maxWidth);
                                }
                                return _isListView
                                    ? _buildMobileList(context, filteredTools, toolProvider)
                                    : _buildMobileGrid(context, toolGroups);
                              },
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OfflineSyncBanner(isOffline: isOffline),
                              Expanded(child: content),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton:
              widget.isSelectionMode && _selectedTools.isNotEmpty
                  ? _buildSelectionFAB(context, toolProvider)
                  : null,
        );
      },
    );
  }

  // ── View toggle button ─────────────────────────────────────────────────
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

  // ── Filter dropdown pill ───────────────────────────────────────────────
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
    final key = GlobalKey();

    String displayText(String item) {
      if (item == 'All' || item == 'Category') return resetLabel;
      return item;
    }

    void openMenu() {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      showMenu<String>(
        context: context,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height + 4,
          offset.dx + size.width,
          0,
        ),
        items: items.map((item) => PopupMenuItem<String>(
          value: item,
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text(displayText(item),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value == item ? FontWeight.w600 : FontWeight.normal,
                      color: value == item
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface,
                    )),
              ),
              if (value == item)
                Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
            ],
          ),
        )).toList(),
      ).then((selected) {
        if (selected != null) onChanged(selected);
      });
    }

    return GestureDetector(
      key: key,
      onTap: openMenu,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText(value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16,
                color: isActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  // ── Mobile list view — full-table horizontal + vertical scroll ───────
  Widget _buildMobileList(
      BuildContext context, List<Tool> tools, SupabaseToolProvider toolProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final techProvider = context.read<SupabaseTechnicianProvider>();

    const double colName     = 160;
    const double colCat      = 130;
    const double colBrand    = 110;
    const double colSerial   = 130;
    const double colStatus   = 100;
    const double colCond     = 110;
    const double colValue    = 100;
    const double colAssigned = 130;
    const double colAction   =  44;
    const double totalW = colName + colCat + colBrand + colSerial + colStatus + colCond + colValue + colAssigned + colAction;

    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: onSurface.withValues(alpha: 0.45),
      letterSpacing: 0.3,
    );
    final cellStyle = TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6));
    final divColor  = isDark ? AppTheme.darkCardBorder : const Color(0xFFF0F0F0);
    final headerBg  = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFA);

    Widget cell(double w, Widget child, {EdgeInsets? padding}) => SizedBox(
          width: w,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: child,
          ),
        );

    // Header row
    Widget header = Container(
      color: headerBg,
      child: Row(children: [
        cell(colName,   Text('NAME',      style: headerStyle)),
        cell(colCat,    Text('CATEGORY',  style: headerStyle)),
        cell(colBrand,  Text('BRAND',     style: headerStyle)),
        cell(colSerial, Text('SERIAL #',  style: headerStyle)),
        cell(colStatus,   Text('STATUS',      style: headerStyle)),
        cell(colCond,     Text('CONDITION',   style: headerStyle)),
        cell(colValue,    Text('VALUE',        style: headerStyle)),
        cell(colAssigned, Text('ASSIGNED TO',  style: headerStyle)),
        SizedBox(width: colAction),
      ]),
    );

    // Data rows
    List<Widget> rows = [];
    for (int i = 0; i < tools.length; i++) {
      final tool = tools[i];
      final imagePath = tool.imagePath;
      final hasImage  = imagePath != null && imagePath.isNotEmpty;
      final isLast    = i == tools.length - 1;

      final isRowSelected = widget.isSelectionMode && tool.id != null && _selectedTools.contains(tool.id!);

      rows.add(
        InkWell(
          onTap: () {
            if (widget.isSelectionMode) {
              _toggleToolSelection(tool);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: isRowSelected
                ? AppTheme.secondaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selection checkbox
              if (widget.isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isRowSelected ? AppTheme.secondaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isRowSelected
                            ? AppTheme.secondaryColor
                            : onSurface.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isRowSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                ),
              // Name + thumbnail
              SizedBox(
                width: colName,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 40, height: 40,
                        child: hasImage && (imagePath.startsWith('http') || kIsWeb)
                            ? Image.network(imagePath, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                            : _buildPlaceholderImage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tool.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (tool.toolType == 'shared')
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('Shared',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple)),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              // Category
              cell(colCat, Text(tool.category, style: cellStyle,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              // Brand
              cell(colBrand, Text(tool.brand ?? '–', style: cellStyle,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              // Serial
              cell(colSerial, Text(tool.serialNumber ?? '–',
                  style: cellStyle.copyWith(fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              // Status
              cell(colStatus, _buildStatusPill(tool.status, compact: true),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              // Condition
              cell(colCond, Text(tool.condition, style: cellStyle,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              // Value
              cell(colValue, Text(
                () {
                  final v = tool.currentValue ?? tool.purchasePrice;
                  if (v == null) return '–';
                  return 'AED ${v.toStringAsFixed(0)}';
                }(),
                style: cellStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              // Assigned To
              cell(colAssigned, Text(
                () {
                  final uid = tool.assignedTo;
                  if (uid == null || uid.isEmpty) return '–';
                  return techProvider.getTechnicianNameById(uid) ?? '–';
                }(),
                style: cellStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              // Action menu
              SizedBox(
                width: colAction,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 18,
                      color: onSurface.withValues(alpha: 0.35)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  elevation: 4,
                  onSelected: (v) => _handleToolAction(context, v, tool, toolProvider),
                  itemBuilder: (_) => [
                    _menuItem('view',   Icons.visibility_outlined,  'View',   onSurface),
                    _menuItem('assign', Icons.person_add_outlined,  'Assign', onSurface),
                    if (tool.assignedTo != null && tool.assignedTo!.isNotEmpty) ...[
                      _menuItem('reassign', Icons.swap_horiz_rounded, 'Reassign', onSurface),
                      _menuItem('return',   Icons.undo_rounded,        'Return',   onSurface),
                    ],
                    if (tool.toolType == 'inventory')
                      _menuItem('make_shared',   Icons.share_outlined,       'Make Shared',   onSurface)
                    else
                      _menuItem('make_inventory', Icons.inventory_2_outlined, 'Make Inventory', onSurface),
                    const PopupMenuDivider(),
                    _menuItem('delete', Icons.delete_outline, 'Delete', Colors.red),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      );
      if (!isLast) rows.add(Divider(height: 1, thickness: 1, color: divColor));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // Horizontal scroll wraps the entire table
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            // Vertical scroll for rows
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                header,
                Divider(height: 1, thickness: 1, color: divColor),
                ...rows,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileToolRow(BuildContext context, Tool tool,
      SupabaseToolProvider toolProvider, int index, int total) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final imagePath = tool.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final isFirst = index == 0;
    final isLast = index == total - 1;

    final isRowSelected = widget.isSelectionMode && tool.id != null && _selectedTools.contains(tool.id!);

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 12 : 0),
      topRight: Radius.circular(isFirst ? 12 : 0),
      bottomLeft: Radius.circular(isLast ? 12 : 0),
      bottomRight: Radius.circular(isLast ? 12 : 0),
    );

    return Material(
      color: isRowSelected
          ? AppTheme.secondaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
          : (isDark ? const Color(0xFF141414) : Colors.white),
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () {
          if (widget.isSelectionMode) {
            if (tool.id != null) {
              setState(() {
                if (_selectedTools.contains(tool.id!)) {
                  _selectedTools.remove(tool.id!);
                } else {
                  _selectedTools.add(tool.id!);
                }
              });
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ToolDetailScreen(tool: tool)),
            );
          }
        },
        borderRadius: borderRadius,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  // Selection checkbox
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isRowSelected ? AppTheme.secondaryColor : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRowSelected
                                ? AppTheme.secondaryColor
                                : onSurface.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isRowSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 12)
                            : null,
                      ),
                    ),

                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: hasImage &&
                              (imagePath.startsWith('http') || kIsWeb)
                          ? Image.network(imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage())
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + category + shared badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tool.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tool.toolType == 'shared') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Shared',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            tool.category,
                            if (tool.brand != null && tool.brand!.isNotEmpty)
                              tool.brand,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.45),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status pill
                  _buildStatusPill(tool.status),
                  const SizedBox(width: 4),

                  // Action menu (not shown in selection mode)
                  if (!widget.isSelectionMode)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz,
                            size: 18,
                            color: onSurface.withValues(alpha: 0.4)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        elevation: 4,
                        onSelected: (value) =>
                            _handleToolAction(context, value, tool, toolProvider),
                        itemBuilder: (_) => [
                          _menuItem('view', Icons.visibility_outlined,
                              'View', onSurface),
                          _menuItem('assign', Icons.person_add_outlined,
                              'Assign', onSurface),
                          if (tool.assignedTo != null &&
                              tool.assignedTo!.isNotEmpty) ...[
                            _menuItem('reassign', Icons.swap_horiz_rounded,
                                'Reassign', onSurface),
                            _menuItem('return', Icons.undo_rounded,
                                'Return', onSurface),
                          ],
                          if (tool.toolType == 'inventory')
                            _menuItem('make_shared', Icons.share_outlined,
                                'Make Shared', onSurface)
                          else
                            _menuItem('make_inventory', Icons.inventory_2_outlined,
                                'Make Inventory', onSurface),
                          const PopupMenuDivider(),
                          _menuItem('delete', Icons.delete_outline,
                              'Delete', Colors.red),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Divider between rows (not on last)
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                endIndent: 0,
                color: isDark
                    ? AppTheme.darkCardBorder
                    : const Color(0xFFF0F0F0),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleToolSelection(Tool tool) {
    final id = tool.id;
    if (id == null) return;
    setState(() {
      if (_selectedTools.contains(id)) {
        _selectedTools.remove(id);
      } else {
        _selectedTools.add(id);
      }
    });
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _handleToolAction(BuildContext context, String action, Tool tool,
      SupabaseToolProvider toolProvider) {
    switch (action) {
      case 'view':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)));
        break;
      case 'assign':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PermanentAssignmentScreen(tools: [tool])),
        );
        break;
      case 'reassign':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PermanentAssignmentScreen(tools: [tool])),
        );
        break;
      case 'return':
        _confirmReturn(context, tool, toolProvider);
        break;
      case 'make_shared':
        _convertToSharedTool(context, tool, toolProvider);
        break;
      case 'make_inventory':
        _convertToInventoryTool(context, tool, toolProvider);
        break;
      case 'delete':
        _confirmDelete(context, tool, toolProvider);
        break;
    }
  }

  void _confirmReturn(
      BuildContext context, Tool tool, SupabaseToolProvider toolProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Return Tool'),
        content: Text('Return "${tool.name}" from assignment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (tool.id != null) {
                await toolProvider.returnTool(tool.id!);
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Tool tool, SupabaseToolProvider toolProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tool'),
        content: Text('Delete "${tool.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (tool.id != null) {
                await toolProvider.deleteTool(tool.id!);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Mobile grid view ───────────────────────────────────────────────────
  Widget _buildMobileGrid(BuildContext context, List<ToolGroup> toolGroups) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: toolGroups.length,
      itemBuilder: (_, i) => _buildToolCard(toolGroups[i]),
    );
  }

  // ── Web grid view ──────────────────────────────────────────────────────
  Widget _buildWebGrid(
      BuildContext context, List<ToolGroup> toolGroups, double width) {
    int crossAxisCount = 2;
    if (width > 1600) crossAxisCount = 6;
    else if (width > 1200) crossAxisCount = 5;
    else if (width > 900) crossAxisCount = 4;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: toolGroups.length,
      itemBuilder: (_, i) => _buildToolCard(toolGroups[i]),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasFilter = _searchQuery.isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedCategory != 'Category';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 52, color: onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No tools match your filters' : 'No tools in inventory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try adjusting your search or filters'
                : 'Tap Add Tool to get started',
            style: TextStyle(
                fontSize: 13, color: onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }

  // ── Selection FAB ──────────────────────────────────────────────────────
  Widget _buildSelectionFAB(
      BuildContext context, SupabaseToolProvider toolProvider) {
    return Container(
      margin: EdgeInsets.all(context.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final selectedToolsList = toolProvider.tools
                .where(
                    (t) => t.id != null && _selectedTools.contains(t.id!))
                .toList();
            if (selectedToolsList.isEmpty) return;
            if (widget.selectionForShared) {
              for (final tool in selectedToolsList) {
                final updated = tool.copyWith(
                  toolType: 'shared',
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await toolProvider.updateTool(updated);
              }
              await toolProvider.loadTools();
              if (context.mounted) Navigator.of(context).pop(true);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PermanentAssignmentScreen(tools: selectedToolsList)),
            );
          },
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    widget.selectionForShared ? Icons.share : Icons.people,
                    color: Colors.white,
                    size: 22),
                const SizedBox(width: 12),
                Text(
                  widget.selectionForShared
                      ? 'Mark ${_selectedTools.length} as shared'
                      : 'Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tool card (grid) ───────────────────────────────────────────────────
  Widget _buildToolCard(ToolGroup toolGroup) {
    final representativeTool =
        toolGroup.representativeTool ?? toolGroup.instances.first;
    final isSelected = widget.isSelectionMode &&
        toolGroup.instances
            .any((t) => t.id != null && _selectedTools.contains(t.id!));
    final cardRadius = kIsWeb ? 8.0 : context.borderRadiusLarge;

    return InkWell(
      onTap: () {
        if (widget.isSelectionMode) {
          if (toolGroup.instances.length == 1) {
            final id = toolGroup.instances.first.id;
            if (id != null) {
              setState(() {
                if (_selectedTools.contains(id)) {
                  _selectedTools.remove(id);
                } else {
                  _selectedTools.add(id);
                }
              });
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ToolInstancesScreen(
                  toolGroup: toolGroup,
                  isSelectionMode: true,
                  selectedToolIds: _selectedTools,
                  onSelectionChanged: (Set<String> selectedIds) {
                    setState(() => _selectedTools = selectedIds);
                  },
                ),
              ),
            );
          }
        } else {
          if (toolGroup.instances.length == 1) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) =>
                    ToolDetailScreen(tool: toolGroup.instances.first)));
          } else {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => ToolInstancesScreen(toolGroup: toolGroup)));
          }
        }
      },
      onLongPress: widget.isSelectionMode
          ? () {}
          : () => _showToolActions(context, representativeTool),
      borderRadius: BorderRadius.circular(cardRadius),
      child: kIsWeb
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildToolCardImage(
                          representativeTool, toolGroup, cardRadius, isSelected),
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: _buildToolCardDetails(toolGroup),
                ),
              ],
            )
          : _buildMobileToolGridCard(representativeTool, toolGroup, cardRadius, isSelected),
    );
  }

  Widget _buildMobileToolGridCard(dynamic representativeTool, ToolGroup toolGroup, double cardRadius, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isSelected
        ? AppTheme.secondaryColor
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07));
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius - 1)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildToolCardImageFill(representativeTool, cardRadius),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _buildStatusPill(toolGroup.bestStatus),
                  ),
                  if (toolGroup.totalCount > 1)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('×${toolGroup.totalCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (widget.isSelectionMode && isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            child: Text(
              toolGroup.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.2,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Text(
              toolGroup.category,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 9,
                height: 1.2,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCardImageFill(dynamic representativeTool, double cardRadius) {
    if (representativeTool.imagePath != null &&
        representativeTool.imagePath!.isNotEmpty) {
      if (representativeTool.imagePath!.startsWith('http') || kIsWeb) {
        return Image.network(
          representativeTool.imagePath!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        );
      } else {
        final localImage =
            buildLocalFileImage(representativeTool.imagePath!, fit: BoxFit.cover);
        if (localImage != null) return localImage;
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildToolCardImage(dynamic representativeTool, ToolGroup toolGroup,
      double cardRadius, bool isSelected) {
    return Stack(
      children: [
        Container(
          decoration: context.cardDecoration.copyWith(
            borderRadius: BorderRadius.circular(cardRadius),
            border: widget.isSelectionMode && isSelected
                ? Border.all(color: AppTheme.secondaryColor, width: 3)
                : context.cardDecoration.border,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildToolCardImageFill(representativeTool, cardRadius),
        ),
        if (toolGroup.totalCount > 1)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('${toolGroup.totalCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        if (widget.isSelectionMode && isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  const Icon(Icons.check, color: Colors.white, size: 18),
            ),
          ),
      ],
    );
  }

  Widget _buildToolCardDetails(ToolGroup toolGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          toolGroup.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.2,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          toolGroup.category,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            height: 1.2,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _buildStatusPill(toolGroup.bestStatus),
      ],
    );
  }

  // ── Web table ──────────────────────────────────────────────────────────
  Widget _buildWebToolsTable(BuildContext context, List<ToolGroup> toolGroups) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final headerBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFFAFAFC);
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.02);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      letterSpacing: 0.2,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${toolGroups.length} tool${toolGroups.length == 1 ? '' : ' groups'}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: headerBg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: Text('Name', style: headerStyle)),
                    Expanded(
                        flex: 2, child: Text('Category', style: headerStyle)),
                    Expanded(flex: 2, child: Text('Brand', style: headerStyle)),
                    SizedBox(
                        width: 60,
                        child: Text('Qty',
                            style: headerStyle,
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 100,
                        child: Text('Status', style: headerStyle)),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),
              ...toolGroups.asMap().entries.map((entry) {
                final index = entry.key;
                final toolGroup = entry.value;
                final tool =
                    toolGroup.representativeTool ?? toolGroup.instances.first;
                final isLast = index == toolGroups.length - 1;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (widget.isSelectionMode) {
                            if (toolGroup.instances.length == 1) {
                              _toggleToolSelection(toolGroup.instances.first);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ToolInstancesScreen(
                                    toolGroup: toolGroup,
                                    isSelectionMode: true,
                                    selectedToolIds: _selectedTools,
                                    onSelectionChanged: (Set<String> selectedIds) {
                                      setState(() => _selectedTools = selectedIds);
                                    },
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          if (toolGroup.instances.length == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ToolDetailScreen(tool: toolGroup.instances.first),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ToolInstancesScreen(toolGroup: toolGroup),
                            ),
                          );
                        },
                        hoverColor: hoverColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: tool.imagePath != null &&
                                          tool.imagePath!.isNotEmpty
                                      ? (tool.imagePath!.startsWith('http') ||
                                              kIsWeb
                                          ? Image.network(tool.imagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildPlaceholderImage())
                                          : (() {
                                              final img = buildLocalFileImage(
                                                  tool.imagePath!,
                                                  fit: BoxFit.cover);
                                              return img ??
                                                  _buildPlaceholderImage();
                                            })())
                                      : _buildPlaceholderImage(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  toolGroup.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                        _getCategoryIcon(toolGroup.category),
                                        size: 14,
                                        color: _getCategoryIconColor(
                                            toolGroup.category)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        toolGroup.category,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.65),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  toolGroup.brand ?? '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFF5F5F7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${toolGroup.totalCount}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: 100,
                                  child: _buildStatusPill(
                                      toolGroup.bestStatus)),
                              SizedBox(
                                width: 36,
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, thickness: 1, color: borderColor),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Status pill ────────────────────────────────────────────────────────
  Widget _buildStatusPill(String status, {bool compact = false}) {
    final normalized = status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor;
    Color backgroundColor;

    switch (normalized) {
      case 'available':
        textColor =
            isDark ? const Color(0xFF34D399) : const Color(0xFF0FA958);
        backgroundColor = isDark
            ? const Color(0xFF0FA958).withValues(alpha: 0.15)
            : const Color(0xFFE9F8F1);
        break;
      case 'in use':
      case 'assigned':
        textColor =
            isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);
        backgroundColor = isDark
            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
            : const Color(0xFFEFF6FF);
        break;
      case 'maintenance':
        textColor =
            isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD9534F);
        backgroundColor = isDark
            ? const Color(0xFFD9534F).withValues(alpha: 0.15)
            : const Color(0xFFFCEAEA);
        break;
      default:
        textColor =
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
        backgroundColor =
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : (kIsWeb ? 10 : 7),
        vertical: compact ? 2.5 : (kIsWeb ? 4 : 3),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1,
              )
            : null,
        boxShadow: (!compact && isDark)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 84 : 180),
        child: Text(
          status,
          style: TextStyle(
            fontSize: compact ? 9.5 : (kIsWeb ? 12 : 10),
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: compact ? 0 : -0.1,
            shadows: (!compact && isDark)
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.75),
                      blurRadius: 4,
                      offset: const Offset(0, 0.5),
                    ),
                  ]
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── Smart search ───────────────────────────────────────────────────────
  bool _matchesSmartSearch(Tool tool) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return true;
    final queryTokens =
        _tokenize(query).where((token) => token.isNotEmpty).toList();
    if (queryTokens.isEmpty) return true;
    final fieldTokens = <String>{
      ..._tokenize(tool.name),
      ..._tokenize(tool.category),
      ..._tokenize(tool.brand ?? ''),
      ..._tokenize(tool.model ?? ''),
      ..._tokenize(tool.serialNumber ?? ''),
      ..._tokenize(tool.status),
      ..._tokenize(tool.condition),
      ..._tokenize(tool.location ?? ''),
      ..._tokenize(tool.notes ?? ''),
    }..removeWhere((token) => token.isEmpty);
    if (fieldTokens.isEmpty) return false;
    return queryTokens
        .every((token) => fieldTokens.any((ft) => ft.contains(token)));
  }

  List<String> _tokenize(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }

  String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  // ── Category helpers ───────────────────────────────────────────────────
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'carpentry tools': return Icons.hardware_outlined;
      case 'electrical tools': return Icons.electrical_services_outlined;
      case 'fastening tools': return Icons.construction_outlined;
      case 'safety equipment': return Icons.shield_outlined;
      case 'testing equipment': return Icons.science_outlined;
      case 'hand tools': return Icons.build_outlined;
      case 'power tools': return Icons.power_outlined;
      case 'measuring tools': return Icons.straighten_outlined;
      case 'cutting tools': return Icons.content_cut_outlined;
      case 'plumbing tools': return Icons.plumbing_outlined;
      case 'automotive tools': return Icons.directions_car_outlined;
      case 'garden tools': return Icons.yard_outlined;
      default: return Icons.category_outlined;
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'carpentry tools': return Colors.brown;
      case 'electrical tools': return Colors.amber;
      case 'fastening tools': return Colors.orange;
      case 'safety equipment': return Colors.red;
      case 'testing equipment': return Colors.purple;
      case 'hand tools': return AppTheme.secondaryColor;
      case 'power tools': return Colors.blueGrey;
      case 'measuring tools': return Colors.teal;
      case 'cutting tools': return Colors.deepOrange;
      case 'plumbing tools': return Colors.cyan;
      case 'automotive tools': return AppTheme.textSecondary;
      case 'garden tools': return Colors.green;
      default: return AppTheme.primaryColor;
    }
  }

  // ── Placeholder image ──────────────────────────────────────────────────
  Widget _buildPlaceholderImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF5F5F7),
      child: Center(
        child: Icon(
          Icons.construction_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  // ── Legacy bottom sheet (long-press) ───────────────────────────────────
  void _showToolActions(BuildContext context, Tool tool) {
    final toolProvider = context.read<SupabaseToolProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(tool.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => ToolDetailScreen(tool: tool)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Assign'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              PermanentAssignmentScreen(tools: [tool])));
                },
              ),
              if (tool.toolType == 'inventory')
                ListTile(
                  leading: Icon(Icons.share_outlined,
                      color: AppTheme.secondaryColor),
                  title: const Text('Make Shared'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _convertToSharedTool(context, tool, toolProvider);
                  },
                ),
              if (tool.toolType == 'shared')
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Make Inventory'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _convertToInventoryTool(context, tool, toolProvider);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _convertToSharedTool(BuildContext context, Tool tool,
      SupabaseToolProvider toolProvider) async {
    try {
      await toolProvider.updateTool(tool.copyWith(toolType: 'shared'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tool.name} is now a shared tool'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _convertToInventoryTool(BuildContext context, Tool tool,
      SupabaseToolProvider toolProvider) async {
    try {
      await toolProvider.updateTool(tool.copyWith(toolType: 'inventory'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${tool.name} moved back to inventory'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

