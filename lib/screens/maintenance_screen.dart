import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../utils/error_handler.dart';
import '../utils/auth_error_handler.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with ErrorHandlingMixin {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTools();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  Future<void> _loadTools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = Provider.of<SupabaseToolProvider>(context, listen: false);
      if (toolProvider.tools.isEmpty) {
        await toolProvider.loadTools();
      }
    } catch (e) {
      debugPrint('Error loading tools: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Tool> _getToolsUnderMaintenance(List<Tool> allTools) {
    return allTools.where((tool) => tool.status == 'Maintenance').toList();
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: context.appBarBackground,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      foregroundColor: theme.colorScheme.onSurface,
      title: Text(
        'Tools Under Maintenance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: Icon(
              Icons.chevron_left,
              size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => NavigationHelper.safePop(context),
        ),
      ),
      actions: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _buildMaintenanceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        final query = _searchQuery.trim().toLowerCase();
        var toolsUnderMaintenance = _getToolsUnderMaintenance(toolProvider.tools);
        if (query.isNotEmpty) {
          toolsUnderMaintenance = toolsUnderMaintenance.where((tool) {
            final haystack = [
              tool.name,
              tool.category,
              tool.location,
            ].whereType<String>().join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();
        }

        if (toolsUnderMaintenance.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadTools,
          color: AppTheme.secondaryColor,
          backgroundColor: context.scaffoldBackground,
          child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.isDesktop(context) ? 24 : 16,
                ResponsiveHelper.isDesktop(context) ? 16 : 12,
                ResponsiveHelper.isDesktop(context) ? 24 : 16,
                120,
              ),
              itemCount: toolsUnderMaintenance.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tool = toolsUnderMaintenance[index];
                return _buildMaintenanceCard(tool);
              },
            ),
          );
        },
      );
  }

  Widget _buildMaintenanceCard(Tool tool) {
    final theme = Theme.of(context);
    final initial = tool.name.isNotEmpty ? tool.name[0].toUpperCase() : '?';
    final details = [
      tool.category,
      tool.location ?? 'Unknown location',
    ].join(' • ');

    return Container(
      decoration: context.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildConditionPill(tool.condition),
              _buildStatusOutlineChip(tool.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Serial: ${tool.serialNumber ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brand: ${tool.brand ?? 'Unknown'}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markMaintenanceComplete(tool),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Mark Maintenance Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'No Tools Under Maintenance',
      subtitle: 'All tools are currently available',
      icon: Icons.build_circle_outlined,
      actionText: null,
      onAction: null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: context.cardDecoration,
        child: TextField(
          controller: _searchController,
          decoration: context.chatGPTInputDecoration.copyWith(
            hintText: 'Search tools, models, or locations...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 10),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 8),
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionPill(String condition) {
    return FilterChip(
      label: Text(
        condition,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: false,
      onSelected: (_) {},
      showCheckmark: false,
      backgroundColor: context.cardBackground,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      side: BorderSide(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelStyle: TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    return FilterChip(
      label: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: false,
      onSelected: (_) {},
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.secondaryColor.withValues(alpha: 0.08),
      side: BorderSide(
        color: AppTheme.secondaryColor,
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelStyle: TextStyle(
        color: AppTheme.secondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _markMaintenanceComplete(Tool tool) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mark Maintenance Complete?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will mark ${tool.name} as available and remove it from maintenance.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final toolProvider = Provider.of<SupabaseToolProvider>(context, listen: false);
      
      // Update tool status to Available
      final updatedTool = tool.copyWith(status: 'Available');
      await toolProvider.updateTool(updatedTool);

      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          '${tool.name} marked as available',
        );
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
