import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';
import '../utils/responsive_helper.dart';
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
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      height: isDesktop ? 32 : 50,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 16),
      child: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(fontSize: 10),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                ),
              ),
            )
          : ListView.builder(
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

    final isDesktop = ResponsiveHelper.isDesktop(context);
    return ListView.builder(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      itemCount: sortedTools.length,
      itemBuilder: (context, index) {
        final tool = sortedTools[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isDesktop ? 8 : 16),
          child: _buildToolCard(tool),
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: isDesktop ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewToolDetails(tool),
        child: Container(
          height: 120, // Fixed height for horizontal cards
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardTheme.color ?? Colors.white,
                (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Row(
            children: [
              // Image Section - Left Side (40% of card width)
              Container(
                width: 120, // Fixed width for image
                height: double.infinity,
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: tool.imagePath!.startsWith('http')
                            ? Image.network(
                                tool.imagePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              )
                            : Image.file(
                                File(tool.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                      )
                    : _buildPlaceholderImage(),
              ),
              
              // Content Section - Right Side (Flexible)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Section - Name and Brand
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${tool.brand ?? 'Unknown'} • ${tool.category}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      // Bottom Section - Status and Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Chip
                          StatusChip(status: tool.status),
                          
                          // Action Button
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 40,
            color: Colors.grey[400],
          ),
          SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
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
      CupertinoPageRoute(
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
