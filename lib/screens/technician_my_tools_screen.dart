import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import 'technician_add_tool_screen.dart';
import 'add_tool_screen.dart';
import 'tool_detail_screen.dart';

class TechnicianMyToolsScreen extends StatefulWidget {
  const TechnicianMyToolsScreen({super.key});

  @override
  State<TechnicianMyToolsScreen> createState() => _TechnicianMyToolsScreenState();
}

class _TechnicianMyToolsScreenState extends State<TechnicianMyToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Category';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _openAddTool() async {
    final authProvider = context.read<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => isAdmin
            ? const AddToolScreen(isFromMyTools: true)
            : const TechnicianAddToolScreen(),
      ),
    );
    if (added == true && mounted) {
      await context.read<SupabaseToolProvider>().loadTools();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Consumer3<SupabaseToolProvider, AuthProvider, ConnectivityProvider>(
            builder: (context, toolProvider, authProvider, connectivityProvider, child) {
              final currentUserId = authProvider.userId;
              final isOffline = !connectivityProvider.isOnline;
              final allMyTools = currentUserId == null
                  ? <Tool>[]
                  : toolProvider.tools
                      .where((tool) => tool.assignedTo == currentUserId)
                      .toList();

              final categories = ['Category', ...toolProvider.getCategories()];

              // Filter tools based on search and filters
              final filteredTools = allMyTools.where((tool) {
                final matchesSearch = _matchesSmartSearch(tool);
                final matchesCategory = _selectedCategory == 'Category' ||
                    tool.category == _selectedCategory;
                final matchesStatus =
                    _selectedStatus == 'All' || tool.status == _selectedStatus;

                return matchesSearch && matchesCategory && matchesStatus;
              }).toList();

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            size: 28,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Tools',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tools currently assigned to you',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      children: [
                        // Compact Search Bar
                        TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: context.chatGPTInputDecoration.copyWith(
                            hintText: 'Search tools...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.45),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: theme.colorScheme.onSurface.withOpacity(0.45),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Filter Row
                        Row(
                          children: [
                            // Category Filter
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: context.cardDecoration.copyWith(
                                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                                  color: context.cardBackground,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    selectedItemBuilder: (BuildContext context) {
                                      return categories.map((category) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getCategoryIcon(category),
                                                size: 16,
                                                color: category == 'Category'
                                                    ? theme.colorScheme.onSurface.withOpacity(0.35)
                                                    : _getCategoryIconColor(category),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList();
                                    },
                                    dropdownColor: context.cardBackground,
                                    menuMaxHeight: 300,
                                    borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                                    items: categories.map((category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getCategoryIcon(category),
                                                size: 16,
                                                color: category == 'Category'
                                                    ? theme.colorScheme.onSurface.withOpacity(0.35)
                                                    : _getCategoryIconColor(category),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  category,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: category == 'Category'
                                                        ? FontWeight.normal
                                                        : FontWeight.w500,
                                                    color: category == 'Category'
                                                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                                                        : theme.colorScheme.onSurface,
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
                            const SizedBox(width: 12),
                            // Status Filter
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: context.cardDecoration.copyWith(
                                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                                  color: context.cardBackground,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedStatus,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    dropdownColor: context.cardBackground,
                                    menuMaxHeight: 300,
                                    borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: 'All',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.filter_list_outlined,
                                                size: 16,
                                                color: theme.colorScheme.onSurface.withOpacity(0.35),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Available',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                              const SizedBox(width: 8),
                                              const Text('Available'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Assigned',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.build_outlined, size: 16, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              const Text('Assigned'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'In Use',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.build_outlined, size: 16, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              const Text('In Use'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Maintenance',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              const Text('Maintenance'),
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

                  // Offline banner
                  if (isOffline)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Offline — showing cached data',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  // Tools Grid
                  Expanded(
                    child: isOffline && !toolProvider.isLoading
                        ? OfflineToolGridSkeleton(
                            itemCount: 6,
                            crossAxisCount: 2,
                            message: 'You are offline. Showing cached data.',
                          )
                        : toolProvider.isLoading
                            ? const ToolCardGridSkeleton(
                                itemCount: 6,
                                crossAxisCount: 2,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 12.0,
                                childAspectRatio: 0.75,
                              )
                            : filteredTools.isEmpty
                                ? RefreshIndicator(
                                    onRefresh: () async {
                                      await toolProvider.loadTools();
                                    },
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      child: Container(
                                        height: MediaQuery.of(context).size.height * 0.6,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.build_rounded,
                                              size: 64,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No tools found',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tools assigned to you will appear here',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () async {
                                      await toolProvider.loadTools();
                                    },
                                    child: GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10.0,
                                        mainAxisSpacing: 12.0,
                                        childAspectRatio: 0.75,
                                      ),
                                      itemCount: filteredTools.length,
                                      itemBuilder: (context, index) {
                                        final tool = filteredTools[index];
                                        return _buildToolCard(tool);
                                      },
                                    ),
                                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTool,
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Tool'),
      ),
    );
  }

  Widget _buildToolCard(Tool tool) {
    final cardRadius = context.borderRadiusLarge;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ToolDetailScreen(tool: tool)),
        );
      },
      borderRadius: BorderRadius.circular(cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Image Card - Square
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (tool.imagePath != null && tool.imagePath!.isNotEmpty)
                      tool.imagePath!.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(cardRadius),
                              child: Image.network(
                                tool.imagePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(cardRadius),
                              child: Image.file(
                                File(tool.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              ),
                            )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius),
                        child: _buildPlaceholderImage(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Details Below Card
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tool.name,
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
                  tool.category,
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
                _buildStatusPill(tool.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final normalized = status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor;
    Color backgroundColor;

    switch (normalized) {
      case 'available':
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF0FA958);
        backgroundColor = isDark ? const Color(0xFF0FA958).withValues(alpha: 0.15) : const Color(0xFFE9F8F1);
        break;
      case 'in use':
      case 'assigned':
        textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);
        backgroundColor = isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFFEFF6FF);
        break;
      case 'maintenance':
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD9534F);
        backgroundColor = isDark ? const Color(0xFFD9534F).withValues(alpha: 0.15) : const Color(0xFFFCEAEA);
        break;
      default:
        textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
        backgroundColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF5F5F7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
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
        return Icons.grass_outlined;
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
        return Colors.blueGrey;
      case 'safety equipment':
        return Colors.red;
      case 'testing equipment':
        return Colors.purple;
      case 'hand tools':
        return Colors.blue;
      case 'power tools':
        return Colors.orange;
      case 'measuring tools':
        return Colors.teal;
      case 'cutting tools':
        return Colors.pink;
      case 'plumbing tools':
        return Colors.cyan;
      case 'automotive tools':
        return Colors.grey;
      case 'garden tools':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }
}
