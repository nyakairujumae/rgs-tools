import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';
import 'tool_detail_screen.dart';
import 'tools_screen.dart';
import '../services/push_notification_service.dart';
import '../utils/logger.dart';

class SharedToolsScreen extends StatefulWidget {
  const SharedToolsScreen({super.key});

  @override
  State<SharedToolsScreen> createState() => _SharedToolsScreenState();
}

class _SharedToolsScreenState extends State<SharedToolsScreen> {
  String _selectedCategory = 'Category';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isListView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SupabaseToolProvider>().loadTools(),
      context.read<SupabaseTechnicianProvider>().loadTechnicians(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolProviderWatch = context.watch<SupabaseToolProvider>();
    final categories = [
      'Category',
      ...toolProviderWatch.getCategories(),
    ];
    context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Container(
        color: context.scaffoldBackground,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kIsWeb ? 24 : 16, kIsWeb ? 28 : 20, kIsWeb ? 24 : 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Shared Tools',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 32 : 30,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final updated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ToolsScreen(
                                        isSelectionMode: true,
                                        selectionForShared: true,
                                      ),
                                    ),
                                  );
                                  if (updated == true && context.mounted) {
                                    await context.read<SupabaseToolProvider>().loadTools();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Tool', style: TextStyle(fontSize: 13)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${toolProviderWatch.tools.where((t) => t.toolType == 'shared').length} shared tools',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Filter bar ────────────────────────────────────────────
              _buildSearchAndFilters(categories),
              Expanded(
                child: Consumer3<SupabaseToolProvider, SupabaseTechnicianProvider, ConnectivityProvider>(
                  builder: (context, toolProvider, technicianProvider, connectivityProvider, child) {
                    final tools = _getFilteredTools(toolProvider.tools);
                    final isOffline = !connectivityProvider.isOnline;
                    final hasActiveFilters = !(_selectedStatus == 'All' &&
                        _selectedCategory == 'Category' &&
                        _searchQuery.isEmpty);

                    return Column(
                      children: [
                        if (isOffline)
                          Builder(
                            builder: (ctx) {
                              final cs = Theme.of(ctx).colorScheme;
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cs.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.wifi_off,
                                        color: cs.onTertiaryContainer, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Offline — showing cached data',
                                        style: TextStyle(
                                          color: cs.onTertiaryContainer,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        Expanded(child: RefreshIndicator(
                          onRefresh: _refresh,
                          child: _buildSharedToolsContent(context, toolProvider, technicianProvider, tools, isOffline, hasActiveFilters),
                        )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedToolsContent(
    BuildContext context,
    SupabaseToolProvider toolProvider,
    SupabaseTechnicianProvider technicianProvider,
    List<Tool> tools,
    bool isOffline,
    bool hasActiveFilters,
  ) {
    if (toolProvider.isLoading) {
      return ToolCardGridSkeleton(
        itemCount: 9,
        crossAxisCount: kIsWeb ? 2 : 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: kIsWeb ? 0.75 : 0.65,
      );
    }

    if (tools.isEmpty) {
      return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isAdmin = authProvider.userRole == UserRole.admin;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              EmptyState(
                icon: Icons.share,
                title: !hasActiveFilters ? 'No Shared Tools' : 'No Tools Found',
                subtitle: !hasActiveFilters
                    ? (isAdmin
                        ? 'Go to All Tools to mark tools as "Shared" so they appear here'
                        : 'No shared tools available. Contact your admin to share tools.')
                    : 'Try adjusting your filters or search terms',
                actionText: isAdmin ? 'Go to Tools' : null,
                onAction: isAdmin
                    ? () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/admin',
                          (route) => false,
                          arguments: {'initialTab': 1},
                        );
                      }
                    : null,
              ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ResponsiveHelper.isDesktop(context);
        final screenWidth = constraints.maxWidth;

        // Mobile list view — horizontal scrollable table
        if (!isDesktop && _isListView) {
          return _buildSharedToolsTable(context, tools, technicianProvider);
        }

        int crossAxisCount = 3;
        double crossAxisSpacing = 10.0;
        double mainAxisSpacing = 10.0;
        double childAspectRatio = 0.7;
        double padding = 16.0;

        if (isDesktop) {
          if (screenWidth > 1600) {
            crossAxisCount = 6;
          } else if (screenWidth > 1200) {
            crossAxisCount = 5;
          } else if (screenWidth > 900) {
            crossAxisCount = 4;
          } else {
            crossAxisCount = 3;
          }
          crossAxisSpacing = 8.0;
          mainAxisSpacing = 8.0;
          childAspectRatio = 0.85;
          padding = 20.0;
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _buildToolCard(tool, technicianProvider);
          },
        );
      },
    );
  }

  Widget _buildSharedToolsTable(
    BuildContext context,
    List<Tool> tools,
    SupabaseTechnicianProvider technicianProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

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
      fontSize: 11, fontWeight: FontWeight.w600,
      color: onSurface.withValues(alpha: 0.45), letterSpacing: 0.3,
    );
    final cellStyle   = TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6));
    final divColor    = isDark ? AppTheme.darkCardBorder : const Color(0xFFF0F0F0);
    final headerBg    = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFA);

    Widget cell(double w, Widget child, {EdgeInsets? padding}) => SizedBox(
      width: w,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: child,
      ),
    );

    Widget header = Container(
      color: headerBg,
      child: Row(children: [
        cell(colName,     Text('NAME',        style: headerStyle)),
        cell(colCat,      Text('CATEGORY',    style: headerStyle)),
        cell(colBrand,    Text('BRAND',       style: headerStyle)),
        cell(colSerial,   Text('SERIAL #',    style: headerStyle)),
        cell(colStatus,   Text('STATUS',      style: headerStyle)),
        cell(colCond,     Text('CONDITION',   style: headerStyle)),
        cell(colValue,    Text('VALUE',       style: headerStyle)),
        cell(colAssigned, Text('ASSIGNED TO', style: headerStyle)),
        SizedBox(width: colAction),
      ]),
    );

    List<Widget> rows = [];
    for (int i = 0; i < tools.length; i++) {
      final tool    = tools[i];
      final isLast  = i == tools.length - 1;
      final imageUrls = _getToolImageUrls(tool);
      final imageUrl  = imageUrls.isNotEmpty ? imageUrls.first : null;

      rows.add(InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool))),
        onLongPress: () => _showToolActions(tool, technicianProvider),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tool.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
            cell(colCat,    Text(tool.category,          style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            cell(colBrand,  Text(tool.brand ?? '–',      style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            cell(colSerial, Text(tool.serialNumber ?? '–', style: cellStyle.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
            cell(colStatus, _buildStatusPill(tool.status),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            cell(colCond,   Text(tool.condition,         style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            cell(colValue, Text(
              () {
                final v = tool.currentValue ?? tool.purchasePrice;
                return v != null ? 'AED ${v.toStringAsFixed(0)}' : '–';
              }(),
              style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            cell(colAssigned, Text(
              () {
                final uid = tool.assignedTo;
                if (uid == null || uid.isEmpty) return '–';
                return technicianProvider.getTechnicianNameById(uid) ?? '–';
              }(),
              style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            // Action menu
            SizedBox(
              width: colAction,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, size: 18, color: onSurface.withValues(alpha: 0.35)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                elevation: 4,
                onSelected: (v) {
                  if (v == 'view') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)));
                  } else if (v == 'actions') {
                    _showToolActions(tool, technicianProvider);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'view', child: Row(children: [
                    Icon(Icons.visibility_outlined, size: 16, color: onSurface),
                    const SizedBox(width: 10),
                    Text('View', style: TextStyle(fontSize: 13, color: onSurface)),
                  ])),
                  PopupMenuItem(value: 'actions', child: Row(children: [
                    Icon(Icons.more_horiz, size: 16, color: onSurface),
                    const SizedBox(width: 10),
                    Text('More actions', style: TextStyle(fontSize: 13, color: onSurface)),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ));
      if (!isLast) rows.add(Divider(height: 1, thickness: 1, color: divColor));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
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

  Widget _buildSearchAndFilters(List<String> categories) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasActiveFilter = _searchQuery.isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedCategory != 'Category';

    return Padding(
      padding: EdgeInsets.fromLTRB(kIsWeb ? 24 : 16, 12, kIsWeb ? 24 : 16, 12),
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
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search shared tools…',
                      hintStyle: TextStyle(fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Icons.search, size: 17,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor.withValues(alpha: 0.5))),
                    ),
                  ),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDark
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
                          onTap: () => setState(() => _isListView = true)),
                      _viewToggleBtn(
                          icon: Icons.grid_view_rounded,
                          active: !_isListView,
                          onTap: () => setState(() => _isListView = false)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: status + category + clear
          Row(
            children: [
              _filterDropdown(
                value: _selectedStatus,
                items: const ['All', 'Available', 'Assigned', 'In Use', 'Maintenance', 'Retired'],
                hint: 'Status',
                resetLabel: 'All Status',
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterDropdown(
                  value: _selectedCategory,
                  items: categories,
                  hint: 'Category',
                  resetLabel: 'All Categories',
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
              if (hasActiveFilter) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedStatus = 'All';
                      _selectedCategory = 'Category';
                    });
                  },
                  child: Text('Clear',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
                ),
              ],
            ],
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
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active
              ? (theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFF0F0F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 17,
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.35)),
      ),
    );
  }

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
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: hint == 'Category',
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16,
              color: isActive
                  ? AppTheme.primaryColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
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
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(displayText(item),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        )),
                  ))
              .toList(),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(displayText(item),
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToolCard(
      Tool tool, SupabaseTechnicianProvider technicianProvider) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    // Apple/Jobber style: 12px on web, rounded on mobile
    final double cardRadius = ResponsiveHelper.isWeb ? 12.0 : 18.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailScreen(tool: tool),
          ),
        );
      },
      onLongPress: () => _showToolActions(tool, technicianProvider),
      borderRadius: BorderRadius.circular(cardRadius),
      child: isDesktop
        // Web: original layout
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: context.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildToolImage(tool, cardRadius),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12, height: 1.2,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.category,
                      style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 9, height: 1.2,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusPill(tool.status),
                  ],
                ),
              ),
            ],
          )
        // Mobile: image with status pill inside, text outside
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildToolImage(tool, cardRadius),
                      Positioned(
                        left: 6, bottom: 6,
                        child: _buildStatusPill(tool.status),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  tool.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 11, height: 1.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                tool.category,
                style: TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 9, height: 1.2,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
    );
  }

  Widget _buildStatusPill(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.toLowerCase();
    Color textColor;
    Color backgroundColor;

    switch (normalized) {
      case 'available':
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF0FA958);
        backgroundColor = isDark
            ? const Color(0xFF0FA958).withValues(alpha: 0.15)
            : const Color(0xFFE9F8F1);
        break;
      case 'in use':
      case 'assigned':
        textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);
        backgroundColor = isDark
            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
            : const Color(0xFFEFF6FF);
        break;
      case 'maintenance':
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD9534F);
        backgroundColor = isDark
            ? const Color(0xFFD9534F).withValues(alpha: 0.15)
            : const Color(0xFFFCEAEA);
        break;
      default:
        textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
        backgroundColor =
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    }

    final isWebLayout = ResponsiveHelper.isWeb;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWebLayout ? 10 : 5,
        vertical: isWebLayout ? 4 : 1.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isWebLayout ? 8 : 6),
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1,
              )
            : null,
        boxShadow: isDark
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
      child: Text(
        status,
        style: TextStyle(
          fontSize: isWebLayout ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: isWebLayout ? -0.1 : 0,
          shadows: isDark
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
    );
  }

  Widget _buildToolImage(Tool tool, [double cardRadius = 18.0]) {
    final imageUrls = _getToolImageUrls(tool);
    
    if (imageUrls.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: Stack(
        children: [
          _buildImageWidget(imageUrls[0]),
          if (imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${imageUrls.length - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _getToolImageUrls(Tool tool) {
    if (tool.imagePath == null || tool.imagePath!.isEmpty) {
      return [];
    }
    
    // Support both single image (backward compatibility) and multiple images (comma-separated)
    final imagePath = tool.imagePath!;
    
    // Check if it's comma-separated (multiple images)
    if (imagePath.contains(',')) {
      return imagePath.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    return [imagePath];
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderImage(),
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F5F7),
      child: Center(
        child: Icon(
          Icons.build_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'category':
        return Icons.category_outlined;
      case 'carpentry tools':
        return Icons.hardware_outlined;
      case 'electrical tools':
        return Icons.electrical_services_outlined;
      case 'fastening tools':
        return Icons.construction_outlined;
      case 'safety equipment':
        return Icons.shield_outlined;
      case 'testing equipment':
        return Icons.science_outlined;
      case 'hand tools':
        return Icons.build_outlined;
      case 'power tools':
        return Icons.power_outlined;
      case 'measuring tools':
        return Icons.straighten_outlined;
      case 'cutting tools':
        return Icons.content_cut_outlined;
      case 'plumbing tools':
        return Icons.plumbing_outlined;
      case 'automotive tools':
        return Icons.directions_car_outlined;
      case 'garden tools':
        return Icons.yard_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'carpentry tools':
        return Colors.brown;
      case 'electrical tools':
        return Colors.amber;
      case 'fastening tools':
        return Colors.orange;
      case 'safety equipment':
        return Colors.red;
      case 'testing equipment':
        return Colors.purple;
      case 'hand tools':
        return AppTheme.secondaryColor;
      case 'power tools':
        return Colors.blueGrey;
      case 'measuring tools':
        return Colors.teal;
      case 'cutting tools':
        return Colors.deepOrange;
      case 'plumbing tools':
        return Colors.cyan;
      case 'automotive tools':
        return AppTheme.textSecondary;
      case 'garden tools':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  List<Tool> _getFilteredTools(List<Tool> tools) {
    final filtered = tools.where((tool) {
      if (tool.toolType != 'shared') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!tool.name.toLowerCase().contains(query) &&
            !tool.category.toLowerCase().contains(query) &&
            !(tool.brand?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      final matchesCategory = _selectedCategory == 'Category' ||
          tool.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'All' || tool.status == _selectedStatus;

      return matchesCategory && matchesStatus;
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  void _showToolActions(
      Tool tool, SupabaseTechnicianProvider technicianProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                tool.name,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (tool.status == 'Available')
                ListTile(
                  leading: Icon(Icons.person_add, color: AppTheme.primaryColor),
                  title: Text(
                    'Assign to Technician',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/assign-tool', arguments: tool);
                  },
                ),
              if (tool.status == 'In Use') ...[
                // Hide Reassign Tool for technicians
                if (Provider.of<AuthProvider>(context, listen: false).userRole?.name != 'technician')
                  ListTile(
                    leading: Icon(Icons.swap_horiz, color: AppTheme.accentColor),
                    title: Text(
                      'Reassign Tool',
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reassign-tool',
                          arguments: tool);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.keyboard_return, color: Colors.green),
                  title: Text(
                    'Return Tool',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/checkin');
                  },
                ),
              ],
              // Hide Edit Tool for technicians
              if (Provider.of<AuthProvider>(context, listen: false).userRole?.name != 'technician')
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: Text(
                    'Edit Tool',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/edit-tool', arguments: tool);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: Text(
                  'View Details',
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tool-detail', arguments: tool);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendToolRequest(Tool tool, String ownerId) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    final requesterName = auth.userFullName ?? 'Unknown Technician';
    final requesterEmail = auth.user?.email ?? 'unknown@technician';
    
    if (requesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in to request a tool.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (tool.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This tool is missing an identifier.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Get owner email from users table
      String ownerEmail = 'unknown@owner';
      try {
        final userResponse = await SupabaseService.client
            .from('users')
            .select('email')
            .eq('id', ownerId)
            .maybeSingle();
        
        if (userResponse != null && userResponse['email'] != null) {
          ownerEmail = userResponse['email'] as String;
        }
      } catch (e) {
        Logger.debug('Could not fetch owner email: $e');
      }
      
      // Tool requests from holders (badged tools) only go to the tool holder, not admins
      // Create notification in technician_notifications table for the tool owner
      // This will appear in the technician's notification center
      try {
        // Get requester's first name for better message format
        final requesterFirstName = requesterName.split(' ').first;
        
        await SupabaseService.client.from('technician_notifications').insert({
          'user_id': ownerId, // The technician who has the tool
          'title': 'Tool Request: ${tool.name}',
          'message': '$requesterFirstName has requested the ${tool.name}',
          'type': 'tool_request',
          'is_read': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': {
            'tool_id': tool.id,
            'tool_name': tool.name,
            'requester_id': requesterId,
            'requester_name': requesterName,
            'requester_email': requesterEmail,
            'owner_id': ownerId,
          },
        });
        Logger.debug('✅ Created technician notification for tool request');
        Logger.debug('✅ Notification sent to technician: $ownerId');
        
        // Send push notification to the tool owner
        try {
          final pushSuccess = await PushNotificationService.sendToUser(
            userId: ownerId,
            title: 'Tool Request: ${tool.name}',
            body: '$requesterFirstName has requested the ${tool.name}',
            data: {
              'type': 'tool_request',
              'tool_id': tool.id,
              'requester_id': requesterId,
            },
          );
          if (pushSuccess) {
            Logger.debug('✅ Push notification sent successfully to tool owner: $ownerId');
          } else {
            Logger.debug('⚠️ Push notification returned false for tool owner: $ownerId');
          }
        } catch (pushError, stackTrace) {
          Logger.debug('❌ Exception sending push notification to tool owner: $pushError');
          Logger.debug('❌ Stack trace: $stackTrace');
        }
      } catch (e) {
        Logger.debug('❌ Failed to create technician notification: $e');
        Logger.debug('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tool request sent to the tool holder'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Logger.debug('Error sending tool request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _sharedChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _sharedMeBubble(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _sharedOtherBubble(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'In Use':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      case 'Retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
