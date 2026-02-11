import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/tool.dart';
import '../models/tool_group.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'tool_detail_screen.dart';
import 'technicians_screen.dart';

class ToolInstancesScreen extends StatefulWidget {
  final ToolGroup toolGroup;
  final bool isSelectionMode;
  final Set<String> selectedToolIds;
  final Function(Set<String>)? onSelectionChanged;

  const ToolInstancesScreen({
    super.key,
    required this.toolGroup,
    this.isSelectionMode = false,
    this.selectedToolIds = const {},
    this.onSelectionChanged,
  });

  @override
  State<ToolInstancesScreen> createState() => _ToolInstancesScreenState();
}

class _ToolInstancesScreenState extends State<ToolInstancesScreen> {
  late Set<String> _selectedToolIds;

  @override
  void initState() {
    super.initState();
    _selectedToolIds = Set<String>.from(widget.selectedToolIds);
  }

  void _toggleSelection(String? toolId) {
    if (toolId == null) return;
    setState(() {
      if (_selectedToolIds.contains(toolId)) {
        _selectedToolIds.remove(toolId);
      } else {
        _selectedToolIds.add(toolId);
      }
      widget.onSelectionChanged?.call(_selectedToolIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        // Rebuild tool group from current tools to reflect deletions
        final currentTools = toolProvider.tools.where((tool) =>
          tool.name == widget.toolGroup.name &&
          tool.category == widget.toolGroup.category &&
          (widget.toolGroup.brand == null || tool.brand == widget.toolGroup.brand)
        ).toList();
        
        // If no tools match, navigate back (tool group was deleted)
        if (currentTools.isEmpty) {
          // Use a delayed navigation to avoid build errors
          Future.microtask(() {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return Scaffold(
            backgroundColor: context.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: context.scaffoldBackground,
              elevation: 0,
              foregroundColor: theme.colorScheme.onSurface,
              title: Text(
                widget.toolGroup.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No instances found',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Create updated tool group from current tools
        final updatedToolGroup = ToolGroup(
          name: widget.toolGroup.name,
          category: widget.toolGroup.category,
          brand: widget.toolGroup.brand,
          instances: currentTools,
        );
        
        final instances = updatedToolGroup.instances;

        return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              kIsWeb ? 24 : 16,
              kIsWeb ? 20 : 16,
              kIsWeb ? 24 : 16,
              8,
            ),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        updatedToolGroup.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${instances.length} instance${instances.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelectionMode && _selectedToolIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedToolIds.clear();
                        widget.onSelectionChanged?.call(_selectedToolIds);
                      });
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 900 : double.infinity,
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: context.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
                    ),
                    child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      '${updatedToolGroup.totalCount}',
                      Icons.inventory_2,
                      AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 40,
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Available',
                      '${updatedToolGroup.availableCount}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 40,
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'In Use',
                      '${updatedToolGroup.inUseCount}',
                      Icons.build,
                      AppTheme.secondaryColor,
                    ),
                  ),
                ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: instances.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No instances found',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : kIsWeb
                      ? GridView.builder(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: widget.isSelectionMode ? 80 : 24,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: instances.length,
                          itemBuilder: (context, index) {
                            final tool = instances[index];
                            final isSelected = widget.isSelectionMode &&
                                tool.id != null &&
                                _selectedToolIds.contains(tool.id!);
                            return _buildInstanceCard(tool, isSelected);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: widget.isSelectionMode ? 80 : 16,
                          ),
                          itemCount: instances.length,
                          itemBuilder: (context, index) {
                            final tool = instances[index];
                            final isSelected = widget.isSelectionMode &&
                                tool.id != null &&
                                _selectedToolIds.contains(tool.id!);
                            return _buildInstanceCard(tool, isSelected);
                          },
                        ),
                ),
            // Assign Button - Only show in selection mode
                if (widget.isSelectionMode && _selectedToolIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.scaffoldBackground,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechniciansScreen(),
                            settings: RouteSettings(
                              arguments: {
                                'selectedTools': _selectedToolIds.toList()
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Assign ${_selectedToolIds.length} Tool${_selectedToolIds.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInstanceCard(Tool tool, bool isSelected) {
    final theme = Theme.of(context);
    final cardRadius = kIsWeb ? 12.0 : 18.0;
    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 0 : 12),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(cardRadius),
        border: isSelected
            ? Border.all(
                color: AppTheme.secondaryColor,
                width: 2,
              )
            : context.cardDecoration.border,
      ),
      child: InkWell(
        onTap: widget.isSelectionMode
            ? () => _toggleSelection(tool.id)
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToolDetailScreen(tool: tool),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(cardRadius),
        child: Padding(
          padding: EdgeInsets.all(kIsWeb ? 12 : 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: tool.imagePath != null && tool.imagePath!.isNotEmpty
                      ? (tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(width: 80, height: 80),
                            )
                          : Image.file(
                              File(tool.imagePath!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(width: 80, height: 80),
                            ))
                      : _buildPlaceholderImage(width: 80, height: 80),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (widget.isSelectionMode && isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              // No shadows - clean design
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (tool.serialNumber != null &&
                        tool.serialNumber!.isNotEmpty)
                      Text(
                        'Serial: ${tool.serialNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Status pill: Show "Assigned" if assigned, otherwise show status
                        if (tool.assignedTo != null)
                          _buildInfoRow(
                            Icons.person,
                            'Assigned',
                            AppTheme.secondaryColor,
                            isPill: true,
                          )
                        else
                          _buildInfoRow(
                            _getStatusIcon(tool.status),
                            tool.status,
                            _getStatusColor(tool.status),
                            isPill: true,
                          ),
                        // Condition pill: Good, Maintenance, Retired
                        _buildInfoRow(
                          _getConditionIcon(tool.condition),
                          tool.condition,
                          _getConditionColor(tool.condition),
                          isPill: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color,
      {bool isPill = false}) {
    if (!isPill) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final tintedBackground = color.withValues(
      alpha: color.opacity < 1 ? color.opacity : 0.12,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tintedBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage({double width = 80, double height = 80}) {
    return Container(
      width: width,
      height: height,
      color: context.cardBackground,
      alignment: Alignment.center,
      child: Icon(
        Icons.build,
        size: 32,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return Icons.check_circle;
      case 'In Use':
        return Icons.build;
      case 'Maintenance':
        return Icons.warning;
      case 'Retired':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'In Use':
        return AppTheme.secondaryColor;
      case 'Maintenance':
        return Colors.orange;
      case 'Retired':
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

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Colors.green;
      case 'fair':
      case 'maintenance':
        return Colors.orange;
      case 'poor':
      case 'needs repair':
      case 'retired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
