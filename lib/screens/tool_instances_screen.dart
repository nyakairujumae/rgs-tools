import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/tool.dart';
import '../models/tool_group.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import 'tool_detail_screen.dart';

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator()),
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              updatedToolGroup.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${instances.length} instance${instances.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: widget.isSelectionMode && _selectedToolIds.isNotEmpty
            ? [
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
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
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
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'In Use',
                      '${updatedToolGroup.inUseCount}',
                      Icons.build,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Instances List
            Expanded(
              child: instances.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No instances found',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          ],
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInstanceCard(Tool tool, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.cardSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: tool.imagePath!.startsWith('http')
                            ? Image.network(
                                tool.imagePath!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              )
                            : Image.file(
                                File(tool.imagePath!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              ),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              // Details
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Selection Checkbox - Only visible when selected
                        if (widget.isSelectionMode && isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tool.serialNumber != null &&
                        tool.serialNumber!.isNotEmpty)
                      _buildInfoRow(
                        Icons.qr_code,
                        'Serial: ${tool.serialNumber}',
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      _getStatusIcon(tool.status),
                      tool.status,
                      _getStatusColor(tool.status),
                    ),
                    if (tool.assignedTo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildInfoRow(
                          Icons.person,
                          'Assigned',
                          AppTheme.secondaryColor,
                        ),
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

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.cardSurfaceColor(context),
      ),
      child: Icon(
        Icons.build,
        size: 32,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
