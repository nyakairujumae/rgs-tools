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
    final categories = ['Category', ...toolProviderWatch.getCategories()];
    final authProvider = context.watch<AuthProvider>();
    final isTechnician = authProvider.userRole == UserRole.technician;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Container(
        color: context.scaffoldBackground,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kIsWeb ? 24 : 16,
                  kIsWeb ? 28 : 20,
                  kIsWeb ? 24 : 16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isTechnician)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                size: 28,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: () => NavigationHelper.safePop(context),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared Tools',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 24 : 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: kIsWeb ? -0.3 : 0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Access and monitor tools that are shared by teams',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 14 : 12,
                                  fontWeight: FontWeight.w400,
                                  color: theme.colorScheme.onSurface.withValues(alpha: kIsWeb ? 0.5 : 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isTechnician)
                          Material(
                            color: Colors.transparent,
                            child: IconButton(
                              onPressed: () async {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ToolsScreen(
                                      isSelectionMode: true,
                                      selectionForShared: true,
                                    ),
                                  ),
                                );
                                if (updated == true && context.mounted) {
                                  await context.read<SupabaseToolProvider>().loadTools();
                                }
                              },
                              icon: const Icon(Icons.add, size: 26, color: Colors.white),
                              tooltip: 'Add shared tool',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
      return const ToolCardGridSkeleton(
        itemCount: 6,
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.75,
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

        int crossAxisCount = 2;
        double crossAxisSpacing = 10.0;
        double mainAxisSpacing = 12.0;
        double childAspectRatio = 0.75;
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

  Widget _buildSearchAndFilters(List<String> categories) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 24 : 16,
        vertical: 12,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: context.chatGPTInputDecoration.copyWith(
              hintText: 'Search shared tools...',
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                      selectedItemBuilder: (context) {
                        return categories.map((category) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 16,
                                  color: category == 'Category'
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35)
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
                      borderRadius: BorderRadius.circular(20),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 16,
                                  color: category == 'Category'
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35)
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
                                          ? theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6)
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                      borderRadius: BorderRadius.circular(20),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'All',
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Available',
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Available'),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'In Use',
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.build_outlined,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text('In Use'),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Maintenance',
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.warning_amber_outlined,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text('Maintenance'),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Retired',
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(width: 8),
                                const Text('Retired'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Section
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
          // Details Section - Clean and organized
          Padding(
            padding: EdgeInsets.only(top: isDesktop ? 4.0 : 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool Name
                Text(
                  tool.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isDesktop ? 12 : 13,
                    height: 1.2,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isDesktop ? 2 : 2),
                // Category
                Text(
                  tool.category,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isDesktop ? 9 : 10,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color statusColor = _getStatusColor(status);
    // Web: slightly larger pill for readability
    final isWebLayout = ResponsiveHelper.isWeb;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWebLayout ? 10 : 8,
        vertical: isWebLayout ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(isWebLayout ? 8 : 10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: isWebLayout ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
          letterSpacing: isWebLayout ? -0.1 : 0,
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
            size: kIsWeb ? 28 : 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ],
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
