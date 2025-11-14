import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTools();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Expanded(
                    child: Text(
                      'Tools Under Maintenance',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Maintenance List
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
        final toolsUnderMaintenance = _getToolsUnderMaintenance(toolProvider.tools);

        if (toolsUnderMaintenance.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadTools,
          child: ListView.builder(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            itemCount: toolsUnderMaintenance.length,
            itemBuilder: (context, index) {
              final tool = toolsUnderMaintenance[index];
              return _buildToolCard(tool);
            },
          ),
        );
      },
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

  Widget _buildToolCard(Tool tool) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: AppTheme.subtleBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            child: Row(
              children: [
                // Tool Icon
                Container(
                  width: ResponsiveHelper.getResponsiveIconSize(context, 48),
                  height: ResponsiveHelper.getResponsiveIconSize(context, 48),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    color: AppTheme.primaryColor,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                // Tool Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (tool.brand != null || tool.model != null) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Text(
                          [tool.brand, tool.model].where((e) => e != null && e.isNotEmpty).join(' '),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 10),
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                    ),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Maintenance',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tool Details
          if (tool.serialNumber != null || tool.location != null || tool.category != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Wrap(
                spacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
                runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
                children: [
                  if (tool.serialNumber != null)
                    _buildInfoBadge(
                      Icons.qr_code_outlined,
                      'Serial: ${tool.serialNumber}',
                      AppTheme.primaryColor,
                    ),
                  if (tool.location != null)
                    _buildInfoBadge(
                      Icons.location_on_outlined,
                      tool.location!,
                      Colors.blue,
                    ),
                  if (tool.category != null)
                    _buildInfoBadge(
                      Icons.category_outlined,
                      tool.category,
                      Colors.purple,
                    ),
                ],
              ),
            ),
          
          if (tool.notes != null && tool.notes!.isNotEmpty) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Text(
                tool.notes!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Action Button
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markMaintenanceComplete(tool),
                icon: Icon(
                  Icons.check_circle,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                ),
                label: Text('Mark Maintenance Complete'),
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
                  color: Colors.grey[600],
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
                        foregroundColor: Colors.grey[700],
                        padding: ResponsiveHelper.getResponsiveButtonPadding(context),
                        side: BorderSide(color: AppTheme.subtleBorder),
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
