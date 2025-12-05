import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';
import '../utils/error_handler.dart';
import '../utils/responsive_helper.dart';

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
    return AppBar(
      backgroundColor: context.appBarBackground,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: const Text(
        'Tools Under Maintenance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
        onPressed: () => Navigator.pop(context),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                  borderRadius: BorderRadius.circular(16),
                ),
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
        height: 52,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search tools, models, or locations...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(Tool tool) {
    final theme = Theme.of(context);
    final initial = tool.name.isNotEmpty ? tool.name[0].toUpperCase() : '?';
    final details = [
      tool.category,
      tool.location ?? 'Unknown location',
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        condition,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryColor, width: 1.1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: AppTheme.secondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _markMaintenanceComplete(Tool tool) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
          ),
        ),
        child: Container(
          constraints: ResponsiveHelper.getResponsiveDialogConstraints(context),
          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveIconSize(context, 64),
                height: ResponsiveHelper.getResponsiveIconSize(context, 64),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.secondaryColor,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              Text(
                'Mark Maintenance Complete?',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'This will mark ${tool.name} as available and remove it from maintenance.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        padding: ResponsiveHelper.getResponsiveButtonPadding(context),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: ResponsiveHelper.getResponsiveButtonPadding(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                        ),
                      ),
                      child: Text('Complete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} marked as available'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
