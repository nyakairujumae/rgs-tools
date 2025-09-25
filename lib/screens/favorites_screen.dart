import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';
import 'tool_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Recently Added';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSortDialog,
            icon: Icon(Icons.sort),
            tooltip: 'Sort Favorites',
          ),
        ],
      ),
      body: Consumer<SupabaseToolProvider>(
        builder: (context, toolProvider, child) {
          final favoriteTools = _getFavoriteTools(toolProvider.tools);
          
          if (favoriteTools.isEmpty) {
            return const EmptyState(
              title: 'No Favorites Yet',
              subtitle: 'Add tools to your favorites for quick access',
              icon: Icons.favorite_border,
            );
          }

          return Column(
            children: [
              // Category Filter
              _buildCategoryFilter(favoriteTools),
              
              // Tools List
              Expanded(
                child: _buildToolsList(favoriteTools),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(List<Tool> tools) {
    final categories = ['All', ..._getUniqueCategories(tools)];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolsList(List<Tool> tools) {
    final filteredTools = _filterToolsByCategory(tools);
    final sortedTools = _sortTools(filteredTools);

    if (sortedTools.isEmpty) {
      return const EmptyState(
        title: 'No Tools in This Category',
        subtitle: 'Try selecting a different category',
        icon: Icons.category,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTools.length,
      itemBuilder: (context, index) {
        final tool = sortedTools[index];
        return _buildToolCard(tool);
      },
    );
  }

  Widget _buildToolCard(Tool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.build,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          tool.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tool.category} • ${tool.brand ?? 'Unknown'}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                StatusChip(status: tool.status),
                SizedBox(width: 8),
                Text(
                  'AED ${(tool.currentValue ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, tool),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove from Favorites'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewToolDetails(tool),
      ),
    );
  }

  List<Tool> _getFavoriteTools(List<Tool> tools) {
    // Mock favorite tools - in real app, this would come from user preferences
    return tools.where((tool) => tool.id != null && _isFavorite(tool.id!)).toList();
  }

  bool _isFavorite(String toolId) {
    // Mock favorite IDs - in real app, this would come from user preferences
    final favoriteIds = ['1', '3', '5', '7', '9'];
    return favoriteIds.contains(toolId);
  }

  List<String> _getUniqueCategories(List<Tool> tools) {
    return tools.map((tool) => tool.category).toSet().toList();
  }

  List<Tool> _filterToolsByCategory(List<Tool> tools) {
    if (_selectedCategory == 'All') {
      return tools;
    }
    return tools.where((tool) => tool.category == _selectedCategory).toList();
  }

  List<Tool> _sortTools(List<Tool> tools) {
    switch (_sortBy) {
      case 'Recently Added':
        return tools.reversed.toList();
      case 'Name A-Z':
        return tools..sort((a, b) => a.name.compareTo(b.name));
      case 'Name Z-A':
        return tools..sort((a, b) => b.name.compareTo(a.name));
      case 'Value High-Low':
        return tools..sort((a, b) => (b.currentValue ?? 0.0).compareTo(a.currentValue ?? 0.0));
      case 'Value Low-High':
        return tools..sort((a, b) => (a.currentValue ?? 0.0).compareTo(b.currentValue ?? 0.0));
      case 'Status':
        return tools..sort((a, b) => a.status.compareTo(b.status));
      default:
        return tools;
    }
  }

  void _viewToolDetails(Tool tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolDetailScreen(tool: tool),
      ),
    );
  }

  void _handleMenuAction(String action, Tool tool) {
    switch (action) {
      case 'view':
        _viewToolDetails(tool);
        break;
      case 'remove':
        _removeFromFavorites(tool);
        break;
    }
  }

  void _removeFromFavorites(Tool tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Favorites'),
        content: Text('Are you sure you want to remove "${tool.name}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tool.name} removed from favorites'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sort Favorites'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Recently Added', 'Most recently added first'),
            _buildSortOption('Name A-Z', 'Alphabetical order'),
            _buildSortOption('Name Z-A', 'Reverse alphabetical order'),
            _buildSortOption('Value High-Low', 'Highest value first'),
            _buildSortOption('Value Low-High', 'Lowest value first'),
            _buildSortOption('Status', 'Group by status'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String sortBy, String description) {
    return ListTile(
      title: Text(sortBy),
      subtitle: Text(description),
      trailing: _sortBy == sortBy ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = sortBy;
        });
        Navigator.pop(context);
      },
    );
  }
}
