import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';
import 'tool_detail_screen.dart';

class SharedToolsScreen extends StatefulWidget {
  const SharedToolsScreen({super.key});

  @override
  State<SharedToolsScreen> createState() => _SharedToolsScreenState();
}

class _SharedToolsScreenState extends State<SharedToolsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'All',
    'Available',
    'In Use',
    'Maintenance',
    'High Value',
    'Recently Added',
  ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        scrolledUnderElevation: 6,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.safePop(context),
          ),
        ),
        title: Text(
          'Shared Tools',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchSection(),
              _buildFilterChips(),
              Expanded(
                child: Consumer3<SupabaseToolProvider, SupabaseTechnicianProvider, ConnectivityProvider>(
                  builder: (context, toolProvider, technicianProvider, connectivityProvider, child) {
                    final tools = _getFilteredTools(toolProvider.tools);
                    final isOffline = !connectivityProvider.isOnline;

                    if (isOffline && !toolProvider.isLoading) {
                      // Show offline skeleton when offline
                      return OfflineToolGridSkeleton(
                        itemCount: 6,
                        crossAxisCount: 2,
                        message: 'You are offline. Showing cached shared tools.',
                      );
                    }

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
                          final isAdmin =
                              authProvider.userRole == UserRole.admin;
                          return EmptyState(
                            icon: Icons.share,
                            title: _selectedFilter == 'All'
                                ? 'No Shared Tools'
                                : 'No Tools Found',
                            subtitle: _selectedFilter == 'All'
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
                          );
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await toolProvider.loadTools();
                      },
                      color: AppTheme.primaryColor,
                      backgroundColor: Theme.of(context).cardTheme.color,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75, // Adjusted for cleaner layout
                        ),
                        itemCount: tools.length,
                        itemBuilder: (context, index) {
                          final tool = tools[index];
                          return _buildToolCard(tool, technicianProvider);
                        },
                      ),
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

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.cardSurfaceColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search shared tools...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
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
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Theme.of(context).textTheme.bodyLarge?.color,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolCard(
      Tool tool, SupabaseTechnicianProvider technicianProvider) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final assignedToId = tool.assignedTo;
    final assignedTechnicianName =
        assignedToId != null && assignedToId.isNotEmpty
            ? technicianProvider.getTechnicianNameById(assignedToId)
            : null;
    final isOwnedByCurrentUser =
        assignedToId != null && assignedToId == currentUserId;

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
                decoration: BoxDecoration(
                  color: AppTheme.cardSurfaceColor(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildToolImage(tool),
              ),
            ),
          ),
          // Details Section - Clean and organized
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool Name
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
                const SizedBox(height: 2),
                // Category
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
                const SizedBox(height: 5),
                // Status and Request Button Row
                Row(
                  children: [
                    // Status Chip - Compact
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(tool.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getStatusColor(tool.status)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tool.status,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(tool.status),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Request Button - Only if not owned by current user
                    if (!isOwnedByCurrentUser &&
                        assignedToId != null &&
                        assignedToId.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: InkWell(
                          onTap: () => _sendToolRequest(tool, assignedToId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Request',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Owner Information - Very subtle, only if assigned
                if (assignedToId != null && assignedToId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isOwnedByCurrentUser
                            ? Icons.check_circle
                            : Icons.person_outline,
                        size: 10,
                        color: isOwnedByCurrentUser
                            ? Colors.green
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          isOwnedByCurrentUser
                              ? 'You have this'
                              : '${assignedTechnicianName ?? 'Someone'} has this',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: isOwnedByCurrentUser
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
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
    );
  }

  Widget _buildToolImage(Tool tool) {
    if (tool.imagePath == null) {
      return _buildPlaceholderImage();
    }

    if (tool.imagePath!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(
          tool.imagePath!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradientFor(context),
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
        ),
      );
    }

    final file = File(tool.imagePath!);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.file(
          file,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
        ),
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
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

      switch (_selectedFilter) {
        case 'Available':
          return tool.status == 'Available';
        case 'In Use':
          return tool.status == 'In Use';
        case 'Maintenance':
          return tool.status == 'Maintenance';
        case 'High Value':
          return tool.currentValue != null && tool.currentValue! > 500;
        case 'Recently Added':
          if (tool.createdAt == null) return false;
          final createdAt = DateTime.tryParse(tool.createdAt!);
          if (createdAt == null) return false;
          return DateTime.now().difference(createdAt).inDays <= 7;
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  void _showFilterOptions() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._filterOptions.map(
              (filter) => ListTile(
                title: Text(
                  filter,
                  style: TextStyle(
                    color: _selectedFilter == filter
                        ? AppTheme.primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: _selectedFilter == filter
                    ? Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToolActions(
      Tool tool, SupabaseTechnicianProvider technicianProvider) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tool.name,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/assign-tool', arguments: tool);
                },
              ),
            if (tool.status == 'In Use') ...[
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppTheme.accentColor),
                title: Text(
                  'Reassign Tool',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
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
                  'Check In Tool',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/checkin');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: Text(
                'Edit Tool',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tool-detail', arguments: tool);
              },
            ),
          ],
        ),
      ),
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
        debugPrint('Could not fetch owner email: $e');
      }
      
      // Create notification in admin_notifications table for the tool owner
      await SupabaseService.client.from('admin_notifications').insert({
        'title': 'Tool Request: ${tool.name}',
        'message': '$requesterName requested the tool "${tool.name}"',
        'technician_name': requesterName,
        'technician_email': requesterEmail,
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
      debugPrint('Error sending tool request: $e');
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
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
