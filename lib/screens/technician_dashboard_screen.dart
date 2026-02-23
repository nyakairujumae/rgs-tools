import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/technician_notification_provider.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_name_service.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../utils/auth_error_handler.dart';
import '../utils/logger.dart';
import '../widgets/common/loading_widget.dart';
import 'add_tool_screen.dart';
import 'shared_tools_screen.dart';
import 'technician_add_tool_screen.dart';
import 'technician_my_tools_screen.dart';

// Technician Dashboard Screen - New Design
class TechnicianDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const TechnicianDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'All Tools',
    'Shared Tools',
    'My Tools',
    'Available',
    'In Use'
  ];
  late final PageController _sharedToolsController;
  Timer? _autoSlideTimer;
  List<Tool> _lastFeaturedTools = [];

  void _navigateToTab(int index, BuildContext context) {
    widget.onNavigateToTab(index);
  }

  Future<void> _openAddTool(
    BuildContext context,
    AuthProvider authProvider,
    SupabaseToolProvider toolProvider,
  ) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => authProvider.isAdmin
            ? const AddToolScreen(isFromMyTools: true)
            : const TechnicianAddToolScreen(),
      ),
    );
    if (added == true && mounted) {
      await toolProvider.loadTools();
    }
  }

  @override
  void initState() {
    super.initState();
    _sharedToolsController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _sharedToolsController.dispose();
    super.dispose();
  }

  void _setupAutoSlide(List<Tool> featuredTools) {
    // Don't setup auto-slide if there's only one or no tools
    if (featuredTools.length <= 1) {
      Logger.debug('⏸️ Auto-slide disabled: ${featuredTools.length} tool(s)');
      _autoSlideTimer?.cancel();
      _autoSlideTimer = null;
      return;
    }
    
    // Only setup if the list actually changed OR timer is not running
    final toolsChanged = _lastFeaturedTools.length != featuredTools.length ||
        !_lastFeaturedTools.every((tool) => featuredTools.any((t) => t.id == tool.id));
    
    // Check if timer is actually active (not just exists)
    final timerIsActive = _autoSlideTimer != null && _autoSlideTimer!.isActive;
    
    if (!toolsChanged && timerIsActive) {
      Logger.debug('✅ Auto-slide already running, skipping setup');
      return; // List hasn't changed and timer is active, don't reset
    }
    
    _lastFeaturedTools = List.from(featuredTools);
    
    // Cancel existing timer if any
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    
    // Wait for next frame to ensure PageController is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || featuredTools.isEmpty) return;
      
      // Double-check controller is ready
      if (!_sharedToolsController.hasClients) {
        Logger.debug('⏳ PageController not ready, retrying...');
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _sharedToolsController.hasClients) {
            _startAutoSlideTimer(featuredTools);
          } else {
            // If still not ready, try again after another delay
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted && _sharedToolsController.hasClients) {
                _startAutoSlideTimer(featuredTools);
              }
            });
          }
        });
        return;
      }
      
      _startAutoSlideTimer(featuredTools);
    });
  }

  void _startAutoSlideTimer(List<Tool> featuredTools) {
    if (!mounted || featuredTools.isEmpty) return;
    
    // Cancel any existing timer first
    _autoSlideTimer?.cancel();
    
    // Setup new timer - start immediately, then repeat every 4 seconds
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _performAutoSlide(featuredTools, timer);
    });
    
    // Also trigger the first slide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _autoSlideTimer != null) {
        _performAutoSlide(featuredTools, null);
      }
    });
    
    Logger.debug('✅ Auto-slide timer started for ${featuredTools.length} tools');
  }

  void _performAutoSlide(List<Tool> featuredTools, Timer? timer) {
    if (!mounted || featuredTools.isEmpty) {
      timer?.cancel();
      _autoSlideTimer = null;
      Logger.debug('🛑 Auto-slide timer cancelled: widget disposed or no tools');
      return;
    }
    
    // Check if controller is attached
    if (!_sharedToolsController.hasClients) {
      Logger.debug('⏸️ PageController not attached, will retry setup...');
      // Try to restart the timer setup if controller becomes available
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _sharedToolsController.hasClients && _autoSlideTimer == null) {
          Logger.debug('🔄 PageController now available, restarting auto-slide...');
          _startAutoSlideTimer(featuredTools);
        }
      });
      return; // Skip this iteration, try again next time
    }
    
    try {
      final currentPage = _sharedToolsController.page ?? 0;
      final nextPage = (currentPage.round() + 1) % featuredTools.length;
      
      Logger.debug('🔄 Auto-sliding from page ${currentPage.round()} to $nextPage (of ${featuredTools.length})');
      
      _sharedToolsController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } catch (e) {
      Logger.debug('❌ Error in auto-slide: $e');
      // If there's an error, try to restart the timer
      if (mounted && _autoSlideTimer != null) {
        _autoSlideTimer?.cancel();
        _autoSlideTimer = null;
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && _sharedToolsController.hasClients) {
            _startAutoSlideTimer(featuredTools);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseToolProvider, AuthProvider,
        SupabaseTechnicianProvider>(
      builder:
          (context, toolProvider, authProvider, technicianProvider, child) {
        // Filter tools based on selected category
        List<Tool> filteredTools = toolProvider.tools;

        final currentUserId = authProvider.userId;
        
        if (_selectedCategoryIndex == 1) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.toolType == 'shared')
              .toList();
        } else if (_selectedCategoryIndex == 2) {
          if (currentUserId == null) {
            filteredTools = [];
          } else {
            filteredTools = toolProvider.tools
                .where((tool) =>
                    tool.assignedTo == currentUserId &&
                    (tool.status == 'Assigned' || tool.status == 'In Use'))
                .toList();
          }
        } else if (_selectedCategoryIndex == 3) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.status == 'Available')
              .toList();
        } else if (_selectedCategoryIndex == 4) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.status == 'In Use')
              .toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredTools = filteredTools
              .where((tool) =>
                  tool.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (tool.brand
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false) ||
                  tool.category
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Featured tools (all shared tools, regardless of status or assignment)
        final featuredTools = toolProvider.tools
            .where((tool) => tool.toolType == 'shared')
            .take(10)
            .toList();

        // Latest tools (my tools or all tools if none assigned)
        final myTools = currentUserId == null
            ? <Tool>[]
            : toolProvider.tools
                .where((tool) =>
                    tool.assignedTo == currentUserId &&
                    (tool.status == 'Assigned' || tool.status == 'In Use'))
                .toList();
        final latestTools = myTools;

        if (toolProvider.isLoading) {
          return _buildSkeletonDashboard(context);
        }

        if (toolProvider.tools.isEmpty) {
          final theme = Theme.of(context);
          return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                Text('No tools available',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Text('You have no assigned tools. You can add your first tool or request tool assignment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                ElevatedButton(
                  onPressed: () => _openAddTool(context, authProvider, toolProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          );
        }

        // Initialize auto-slide when data is available
        _setupAutoSlide(featuredTools);

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        
        return Container(
          color: context.scaffoldBackground,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Welcome banner
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                ),
                      child: Container(
                width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(18),
                ),
                  child: Row(
                      children: [
                        Container(
                        width: ResponsiveHelper.getResponsiveIconSize(context, 72),
                        height: ResponsiveHelper.getResponsiveIconSize(context, 72),
                          decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surfaceVariant
                            : context.cardBackground, // ChatGPT-style: #F5F5F5 instead of grey
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                          ),
                          ),
                          child: Icon(
                          Icons.inventory_2,
                          color: AppTheme.secondaryColor,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 36),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              _greeting(_resolveDisplayName(authProvider)),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                              Text(
                                'Manage your tools and access shared resources',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Shared Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                      'Shared Tools',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SharedToolsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 8,
                          vertical: 4,
                        ),
                          ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppTheme.secondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Shared Tools Carousel (auto sliding)
              SizedBox(
                height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
                child: featuredTools.isEmpty
                    ? Center(
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                          child: Text(
                            'No shared tools available',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ),
                      )
                    : PageView.builder(
                        controller: _sharedToolsController,
                        itemCount: featuredTools.length,
                        padEnds: false,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 16,
                            ),
                              child: _buildFeaturedCard(
                                  featuredTools[index],
                                  context,
                                  authProvider.user?.id,
                                  technicianProvider.technicians),
                          );
                        },
                      ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // My Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Tools',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                              fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TechnicianMyToolsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppTheme.secondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Latest Tools Vertical List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: latestTools.isEmpty
                    ? Container(
                        height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
                        child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.badge_outlined,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Text(
                              'No tools assigned yet',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                            ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Text(
                                'Add or badge tools you currently have to see them here.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Column(
                          children: latestTools
                              .map((tool) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    ),
                                    child: _buildLatestCard(tool, context,
                                        technicianProvider.technicians, authProvider.user?.id),
                                  ))
                              .toList(),
                      ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildFeaturedCard(Tool tool, BuildContext context,
      String? currentUserId, List<dynamic> technicians) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 180),
        padding: const EdgeInsets.all(12),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left thumbnail
            Container(
              width: 130,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                        ? Image.network(
                            tool.imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(true),
                          )
                        : (() {
                            try {
                              final file = File(tool.imagePath!);
                              if (file.existsSync()) {
                                return Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              }
                            } catch (e) {
                              // File doesn't exist or can't be accessed
                            }
                            return _buildPlaceholderImage(true);
                          })())
                    : _buildPlaceholderImage(true),
              ),
            ),
            const SizedBox(width: 12),
            // Right content
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // Tool name with shared badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  tool.name,
                                  style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                          'SHARED',
                                      style: TextStyle(
                            fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  const SizedBox(height: 8),
                  // Status chips
                          Wrap(
                    spacing: 6,
                    runSpacing: 4,
                            children: [
                              _buildPillChip(
                                _getStatusIcon(tool.status),
                                _getStatusLabel(tool.status),
                                _getStatusColor(tool.status),
                              ),
                              _buildPillChip(
                                _getConditionIcon(tool.condition),
                                _getConditionLabel(tool.condition),
                                _getConditionColor(tool.condition),
                              ),
                            ],
                          ),
                  const SizedBox(height: 8),
                  // Category row
                              Row(
                                children: [
                                  Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                      const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tool.category.toUpperCase(),
                                      style: TextStyle(
                            fontSize: 11,
                                        color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                  // Brand (if available)
                  if (tool.brand != null && tool.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tool.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Holder line and request button
                  const SizedBox(height: 6),
                  Row(
                                children: [
                      Expanded(
                                    child: _holderLine(context, tool, technicians, currentUserId),
                                  ),
                                  // Show Request button for shared tools that have a holder (badged to someone else)
                                  if (tool.assignedTo != null &&
                                      tool.assignedTo!.isNotEmpty &&
                          (currentUserId == null || currentUserId != tool.assignedTo))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: TextButton(
                            onPressed: () => _sendToolRequest(context, tool),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                            child: const Text(
                                            'Request',
                                            style: TextStyle(
                                fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                            ),
                        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToolRequest(BuildContext context, Tool tool) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    final requesterName = auth.userFullName ?? 'Unknown Technician';
    final requesterEmail = auth.user?.email ?? 'unknown@technician';
    
    if (requesterId == null) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'You need to be signed in to request a tool.',
      );
      return;
    }
    
    final ownerId = tool.assignedTo;
    if (ownerId == null || ownerId.isEmpty) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'This tool is not assigned to anyone.',
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
        
        // Send push notification to the tool holder
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
            Logger.debug('✅ Push notification sent successfully to tool holder: $ownerId');
          } else {
            Logger.debug('⚠️ Push notification returned false for tool holder: $ownerId');
          }
        } catch (pushError, stackTrace) {
          Logger.debug('❌ Exception sending push notification to tool holder: $pushError');
          Logger.debug('❌ Stack trace: $stackTrace');
          // Don't fail the whole operation if push fails
        }
        
        // Note: The realtime subscription should automatically pick up the new notification
        // But we can't refresh the provider here because we don't have access to the tool holder's context
        // The realtime subscription in TechnicianNotificationProvider will handle this
        Logger.debug('✅ Notification created - realtime subscription should update the UI');
      } catch (e) {
        Logger.debug('❌ Failed to create technician notification: $e');
        Logger.debug('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Tool request sent to ${tool.assignedTo == requesterId ? 'the owner' : 'the tool holder'}',
        );
      }
    } catch (e) {
      Logger.debug('Error sending tool request: $e');
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to send request: $e',
        );
      }
    }
  }


  Widget _buildLatestCard(
      Tool tool, BuildContext context, List<dynamic> technicians, String? currentUserId) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 160),
        padding: const EdgeInsets.all(12),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left thumbnail
            Container(
              width: 120,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(false),
                            )
                          : (() {
                              try {
                                final file = File(tool.imagePath!);
                                if (file.existsSync()) {
                                  return Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                }
                              } catch (e) {
                                // File doesn't exist or can't be accessed
                              }
                              return _buildPlaceholderImage(false);
                            })())
                    : _buildPlaceholderImage(false),
              ),
            ),
            const SizedBox(width: 12),
            // Right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  // Tool name with optional shared badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tool.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tool.toolType == 'shared')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SHARED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                  const SizedBox(height: 8),
                  // Status chips
                    Wrap(
                    spacing: 6,
                    runSpacing: 4,
                      children: [
                        _buildPillChip(
                          _getStatusIcon(tool.status),
                          _getStatusLabel(tool.status),
                          _getStatusColor(tool.status),
                        ),
                        _buildPillChip(
                          _getConditionIcon(tool.condition),
                          _getConditionLabel(tool.condition),
                          _getConditionColor(tool.condition),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Category row
                        Row(
                          children: [
                            Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                      const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tool.category.toUpperCase(),
                                style: TextStyle(
                            fontSize: 11,
                                  color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                  // Brand (if available)
                  if (tool.brand != null && tool.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tool.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  ],
              ),
          ),
        ],
      ),
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

  Widget _buildPlaceholderImage(bool isFeatured) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
        decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surfaceVariant
            : context.cardBackground, // ChatGPT-style: #F5F5F5 instead of grey
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
          right: isFeatured
              ? Radius.zero
              : Radius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                ),
        ),
      ),
      child: Icon(
        Icons.build,
        color: theme.colorScheme.onSurface.withOpacity(0.55),
        size: ResponsiveHelper.getResponsiveIconSize(context, 32),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildPillChip(IconData icon, String text, Color color) {
    final tintedBackground = color.withOpacity(
      color.opacity < 1 ? color.opacity : 0.12,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: tintedBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveIconSize(context, 14),
            color: color,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _holderLine(
      BuildContext context, Tool tool, List<dynamic> technicians, String? currentUserId) {
    final theme = Theme.of(context);

    if (tool.assignedTo == null || tool.assignedTo!.isEmpty) {
      return Text(
        'No current holder',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Try in-memory technicians first (assignedTo = auth user ID when badged; match by user_id or id)
    final techProvider = context.read<SupabaseTechnicianProvider>();
    final nameFromProvider = techProvider.getTechnicianNameById(tool.assignedTo!);
    if (nameFromProvider != null && nameFromProvider.isNotEmpty) {
      final displayName = UserNameService.getFirstName(nameFromProvider);
      return Text(
        '$displayName has this tool',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Fallback: fetch from UserNameService (technicians table by user_id, then users table)
    return FutureBuilder<String>(
      future: UserNameService.getUserName(tool.assignedTo!),
      builder: (context, snapshot) {
        String name = 'Unknown';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          final fullName = snapshot.data!;
          if (fullName != 'Unknown') {
            name = UserNameService.getFirstName(fullName);
          }
        }
        return Text(
          '$name has this tool',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  IconData _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return Icons.apps;
      case 1:
        return Icons.share;
      case 2:
        return Icons.person;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.build;
      default:
        return Icons.apps;
    }
  }


  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'in use':
        return Icons.build;
      case 'maintenance':
        return Icons.warning;
      case 'retired':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'assigned':
        return 'Assigned';
      case 'in use':
        return 'In Use';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'assigned':
      case 'in use':
        return AppTheme.secondaryColor;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Icons.check_circle;
      case 'fair':
      case 'maintenance':
        return Icons.warning;
      case 'poor':
      case 'needs repair':
      case 'retired':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getConditionLabel(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return 'Faulty';
    return condition;
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
      case 'needs repair':
        return Colors.red;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _greeting(String? fullName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    if (fullName == null || fullName.trim().isEmpty) {
      return '$salutation!';
    }
    final name = fullName.split(RegExp(r"\s+")).first;
    return '$salutation, $name!';
  }

  String? _resolveDisplayName(AuthProvider authProvider) {
    final fullName = authProvider.userFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final email = authProvider.userEmail;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return null;
  }

  Widget _buildSkeletonDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode 
        ? Colors.grey[800]!.withValues(alpha: 0.3)
        : Colors.grey[300]!;
    final highlightColor = isDarkMode 
        ? Colors.grey[700]!.withValues(alpha: 0.5)
        : Colors.grey[400]!;

    return Container(
      color: context.scaffoldBackground,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner skeleton
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    SkeletonLoader(
                      width: ResponsiveHelper.getResponsiveIconSize(context, 72),
                      height: ResponsiveHelper.getResponsiveIconSize(context, 72),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                      ),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: double.infinity,
                            height: ResponsiveHelper.getResponsiveFontSize(context, 22),
                            borderRadius: BorderRadius.circular(4),
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                          SkeletonLoader(
                            width: double.infinity * 0.7,
                            height: ResponsiveHelper.getResponsiveFontSize(context, 15),
                            borderRadius: BorderRadius.circular(4),
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // Shared Tools Section skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SkeletonLoader(
                    width: 80,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // Shared Tools Carousel skeleton
            SizedBox(
              height: ResponsiveHelper.getResponsiveListItemHeight(context, 212),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: _buildFeaturedCardSkeleton(context, baseColor, highlightColor),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // My Tools Section skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SkeletonLoader(
                    width: 80,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // My Tools List skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(2, (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.getResponsiveSpacing(context, 12),
                  ),
                  child: _buildLatestCardSkeleton(context, baseColor, highlightColor),
                )),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCardSkeleton(BuildContext context, Color baseColor, Color highlightColor) {
    return Container(
      height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: ResponsiveHelper.getResponsiveIconSize(context, 140),
            height: double.infinity,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
            ),
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: ResponsiveHelper.getResponsiveSpacing(context, 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title skeleton
                  SkeletonLoader(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Chips skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      SkeletonLoader(
                        width: 70,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Serial number skeleton
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Location skeleton
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Category skeleton
                  SkeletonLoader(
                    width: 90,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Brand/Model skeleton
                  SkeletonLoader(
                    width: 150,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestCardSkeleton(BuildContext context, Color baseColor, Color highlightColor) {
    return Container(
      height: ResponsiveHelper.getResponsiveListItemHeight(context, 172),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 6,
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: ResponsiveHelper.getResponsiveIconSize(context, 140),
            height: double.infinity,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
            ),
            baseColor: baseColor,
            highlightColor: highlightColor,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: ResponsiveHelper.getResponsiveSpacing(context, 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title skeleton
                  SkeletonLoader(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Chips skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      SkeletonLoader(
                        width: 70,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Serial number skeleton
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Location skeleton
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Category skeleton
                  SkeletonLoader(
                    width: 90,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Brand/Model skeleton
                  SkeletonLoader(
                    width: 150,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
