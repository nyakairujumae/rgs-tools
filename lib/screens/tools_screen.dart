import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../models/tool_group.dart';
import 'tool_detail_screen.dart';
import 'tool_instances_screen.dart';
import 'technicians_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/loading_widget.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final bool isSelectionMode;

  const ToolsScreen({
    super.key,
    this.initialStatusFilter,
    this.isSelectionMode = false,
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

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter ?? 'All';
    _searchController.addListener(_onSearchChanged);
    // Load tools to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
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
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        final tools = toolProvider.tools;
        final categories = ['Category', ...toolProvider.getCategories()];

        debugPrint('🔍 Admin Tools Screen - Total tools: ${tools.length}');

        // Filter tools based on search and filters
        final filteredTools = tools.where((tool) {
          final matchesSearch = _matchesSmartSearch(tool);
          final matchesCategory = _selectedCategory == 'Category' ||
              tool.category == _selectedCategory;
          final matchesStatus =
              _selectedStatus == 'All' || tool.status == _selectedStatus;

          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();

        // Group filtered tools by name + category + brand
        final toolGroups = ToolGroup.groupTools(filteredTools);

        debugPrint(
            '🔍 Admin Tools Screen - Filtered tools: ${filteredTools.length}, Groups: ${toolGroups.length}');
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Back button and heading for selection mode
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Select Tools',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Small hint text for selection mode
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tap a tool card to select individual instances, then use Assign below.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  // Section Heading (only show when not in selection mode)
                  if (!widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tools',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      children: [
                        // Compact Search Bar
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurfaceColor(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.subtleBorder,
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search tools...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.45),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.45),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 18,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.45),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.8),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 12),

                        // Professional Filter Row
                        Row(
                          children: [
                            // Category Filter
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardSurfaceColor(context),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppTheme.subtleBorder,
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 20,
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return categories.map((category) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getCategoryIcon(category),
                                                size: 18,
                                                color: category == 'Category'
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.35)
                                                    : _getCategoryIconColor(
                                                        category),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList();
                                    },
                                    dropdownColor:
                                        AppTheme.cardSurfaceColor(context),
                                    menuMaxHeight: 300,
                                    borderRadius: BorderRadius.circular(20),
                                    items: categories.map((category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getCategoryIcon(category),
                                                size: 18,
                                                color: category == 'Category'
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.35)
                                                    : _getCategoryIconColor(
                                                        category),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  category,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        category == 'Category'
                                                            ? FontWeight.normal
                                                            : FontWeight.w500,
                                                    color: category ==
                                                            'Category'
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6)
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Status Filter
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardSurfaceColor(context),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppTheme.subtleBorder,
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedStatus,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 20,
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    dropdownColor:
                                        AppTheme.cardSurfaceColor(context),
                                    menuMaxHeight: 300,
                                    borderRadius: BorderRadius.circular(20),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: 'All',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.filter_list_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.35),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Available',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 18,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 12),
                                              Text('Available'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'In Use',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.build_outlined,
                                                size: 18,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 12),
                                              Text('In Use'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Maintenance',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_outlined,
                                                size: 18,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(width: 12),
                                              Text('Maintenance'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Retired',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.block_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.45),
                                              ),
                                              SizedBox(width: 12),
                                              Text('Retired'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tools List
                  Expanded(
                    child: toolProvider.isLoading
                        ? const ToolCardGridSkeleton(
                            itemCount: 6,
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.75,
                          )
                        : filteredTools.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.build,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.45),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No tools found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.45),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add your first tool to get started',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 12.0,
                                  childAspectRatio:
                                      0.75, // Square image + consistent details below
                                ),
                                itemCount: toolGroups.length,
                                itemBuilder: (context, index) {
                                  final toolGroup = toolGroups[index];
                                  return _buildToolCard(toolGroup);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton:
              widget.isSelectionMode && _selectedTools.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TechniciansScreen(),
                                settings: RouteSettings(
                                  arguments: {
                                    'selectedTools': _selectedTools.toList()
                                  },
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
        );
      },
    );
  }

  Widget _buildToolCard(ToolGroup toolGroup) {
    final representativeTool =
        toolGroup.representativeTool ?? toolGroup.instances.first;
    final isSelected = widget.isSelectionMode &&
        toolGroup.instances
            .any((t) => t.id != null && _selectedTools.contains(t.id!));

    return InkWell(
      onTap: () {
        if (widget.isSelectionMode) {
          // In selection mode, navigate to instances screen for individual selection
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolInstancesScreen(
                toolGroup: toolGroup,
                isSelectionMode: true,
                selectedToolIds: _selectedTools,
                onSelectionChanged: (Set<String> selectedIds) {
                  setState(() {
                    _selectedTools = selectedIds;
                  });
                },
              ),
            ),
          );
        } else {
          // Normal mode: show all instances
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolInstancesScreen(toolGroup: toolGroup),
            ),
          );
        }
      },
      onLongPress: widget.isSelectionMode
          ? () {}
          : () => _showToolActions(context, representativeTool),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Image Card - Square
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: 1.0, // Perfect square
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurfaceColor(context),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: widget.isSelectionMode && isSelected
                            ? AppTheme.primaryColor
                            : widget.isSelectionMode
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : AppTheme.subtleBorder,
                        width: widget.isSelectionMode && isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                        if (widget.isSelectionMode && !isSelected)
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Image content
                        if (representativeTool.imagePath != null)
                          (representativeTool.imagePath!.startsWith('http')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.network(
                                    representativeTool.imagePath!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderImage(),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.file(
                                    File(representativeTool.imagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderImage(),
                                  ),
                                ))
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: _buildPlaceholderImage(),
                          ),
                        // Count badge overlay
                        if (toolGroup.totalCount > 1)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${toolGroup.totalCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Selection Checkbox - Only visible when selected
                  if (widget.isSelectionMode && isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Details Below Card - Clean and simple
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
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
                // Category as subtitle
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    if (fieldTokens.isEmpty) {
      return false;
    }

    return queryTokens.every((token) {
      return fieldTokens.any(
        (fieldToken) => fieldToken.contains(token),
      );
    });
  }

  List<String> _tokenize(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
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
        return Colors.blue;
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardSurfaceColor(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          ),
          SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  void _showToolActions(BuildContext context, Tool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tool Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: AppTheme.primaryColor),
              title: Text(
                tool.toolType == 'inventory'
                    ? 'Make Shared Tool'
                    : 'Already ${tool.toolType}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                tool.toolType == 'inventory'
                    ? 'Make this tool available for checkout'
                    : 'Tool type: ${tool.toolType}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              onTap: tool.toolType == 'inventory'
                  ? () => _convertToSharedTool(context, tool)
                  : null,
            ),
            if (tool.toolType == 'shared')
              ListTile(
                leading: Icon(
                  Icons.inventory,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
                title: Text(
                  'Move to Inventory',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  'Remove from shared tools',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () => _convertToInventoryTool(context, tool),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToSharedTool(BuildContext context, Tool tool) async {
    try {
      final updatedTool = tool.copyWith(toolType: 'shared');
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} is now available as a shared tool'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertToInventoryTool(BuildContext context, Tool tool) async {
    try {
      final updatedTool = tool.copyWith(toolType: 'inventory');
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} moved back to inventory'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
