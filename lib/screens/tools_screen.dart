import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import 'tool_detail_screen.dart';
import 'technicians_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final bool isSelectionMode;
  
  const ToolsScreen({
    super.key, 
    this.initialStatusFilter,
    this.isSelectionMode = false,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCategory = 'Category';
  late String _selectedStatus;
  String _searchQuery = '';
  Set<String> _selectedTools = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter ?? 'All';
    // Load tools to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        final tools = toolProvider.tools;
        final categories = ['Category', ...toolProvider.getCategories()];
        
        debugPrint('🔍 Admin Tools Screen - Total tools: ${tools.length}');

        
        // Filter tools based on search and filters
        final filteredTools = tools.where((tool) {
          final matchesSearch = _searchQuery.isEmpty ||
              tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final matchesCategory = _selectedCategory == 'Category' || tool.category == _selectedCategory;
          final matchesStatus = _selectedStatus == 'All' || tool.status == _selectedStatus;
          
          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();
        
        debugPrint('🔍 Admin Tools Screen - Filtered tools: ${filteredTools.length}');

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: Column(
            children: [
              if (widget.isSelectionMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTools.isEmpty
                                  ? 'Select tools to assign'
                                  : '${_selectedTools.length} tool${_selectedTools.length > 1 ? 's' : ''} selected',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap a tool card to toggle selection, then use Assign below.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTools.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTools.clear();
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              // Section Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tools',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Compact Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(24), // Fully rounded pill shape
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: TextField(
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search tools...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Professional Filter Row
                    Row(
                      children: [
                        // Category Filter
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return categories.map((category) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(category),
                                            size: 18,
                                            color: category == 'Category' 
                                                ? Colors.grey[400] 
                                                : _getCategoryIconColor(category),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                dropdownColor: AppTheme.cardGradientStart,
                                menuMaxHeight: 300,
                                borderRadius: BorderRadius.circular(20),
                                items: categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(category),
                                            size: 18,
                                            color: category == 'Category' 
                                                ? Colors.grey[400] 
                                                : _getCategoryIconColor(category),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              category,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: category == 'Category' 
                                                    ? FontWeight.normal 
                                                    : FontWeight.w500,
                                                color: category == 'Category' 
                                                    ? Colors.grey[600] 
                                                    : Theme.of(context).textTheme.bodyLarge?.color,
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
                        SizedBox(width: 12),
                        // Status Filter
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: AppTheme.cardGradientStart,
                                menuMaxHeight: 300,
                                borderRadius: BorderRadius.circular(20),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: 'All',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.filter_list_outlined,
                                            size: 18,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Available',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Available'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'In Use',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.build_outlined,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 12),
                                          Text('In Use'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Maintenance',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_outlined,
                                            size: 18,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Maintenance'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Retired',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Retired'),
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
              ),
              
              // Tools List
              Expanded(
                child: toolProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredTools.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.build,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tools found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add your first tool to get started',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 12.0,
                              childAspectRatio: 0.75, // Square image + compact details below
                            ),
                            itemCount: filteredTools.length,
                            itemBuilder: (context, index) {
                              final tool = filteredTools[index];
                              return _buildToolCard(tool);
                            },
                          ),
              ),
            ],
          ),
        ),
          ),
          floatingActionButton: widget.isSelectionMode && _selectedTools.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechniciansScreen(),
                            settings: RouteSettings(
                              arguments: {'selectedTools': _selectedTools.toList()},
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool) {
    final isSelected = widget.isSelectionMode && tool.id != null && _selectedTools.contains(tool.id!);
    
    return InkWell(
      onTap: () {
        if (widget.isSelectionMode) {
          setState(() {
            if (tool.id != null) {
              if (isSelected) {
                _selectedTools.remove(tool.id!);
              } else {
                _selectedTools.add(tool.id!);
              }
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        }
      },
      onLongPress: widget.isSelectionMode ? () {} : () => _showToolActions(context, tool),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Image Card - Square
          AspectRatio(
            aspectRatio: 1.0, // Perfect square
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: widget.isSelectionMode && isSelected
                        ? Border.all(
                            color: Colors.blue,
                            width: 3,
                          )
                        : null,
                  ),
              clipBehavior: Clip.antiAlias,
              child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              tool.imagePath!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.file(
                              File(tool.imagePath!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            ),
                          ))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _buildPlaceholderImage(),
                      ),
                ),
                // Selection Checkbox
                if (widget.isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          
          // Details Below Card
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool Name and Type in one line
                Text(
                  '${tool.name} • ${tool.category}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                // Status and Condition Pills
                Row(
                  children: [
                    StatusChip(
                      status: tool.status,
                      showIcon: false,
                    ),
                    SizedBox(width: 6),
                    ConditionChip(condition: tool.condition),
                  ],
                ),
              ],
            ),
          ),
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
        return Colors.blue;
      case 'power tools':
        return Colors.blueGrey;
      case 'measuring tools':
        return Colors.teal;
      case 'cutting tools':
        return Colors.deepOrange;
      case 'plumbing tools':
        return Colors.cyan;
      case 'automotive tools':
        return Colors.grey;
      case 'garden tools':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Available':
        color = Colors.green;
        break;
      case 'In Use':
        color = Colors.blue;
        break;
      case 'Maintenance':
        color = Colors.orange;
        break;
      case 'Retired':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    Color color;
    switch (condition) {
      case 'Excellent':
        color = Colors.green;
        break;
      case 'Good':
        color = Colors.blue;
        break;
      case 'Fair':
        color = Colors.yellow;
        break;
      case 'Poor':
        color = Colors.orange;
        break;
      case 'Needs Repair':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


  void _showToolActions(BuildContext context, Tool tool) {
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
            Text(
              'Tool Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue),
              title: Text(
                tool.toolType == 'inventory' 
                    ? 'Make Shared Tool' 
                    : 'Already ${tool.toolType}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                tool.toolType == 'inventory'
                    ? 'Make this tool available for checkout'
                    : 'Tool type: ${tool.toolType}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              onTap: tool.toolType == 'inventory' 
                  ? () => _convertToSharedTool(context, tool)
                  : null,
            ),
            if (tool.toolType == 'shared')
              ListTile(
                leading: Icon(Icons.inventory, color: Colors.grey),
                title: Text(
                  'Move to Inventory',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  'Remove from shared tools',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () => _convertToInventoryTool(context, tool),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToSharedTool(BuildContext context, Tool tool) async {
    try {
      final updatedTool = tool.copyWith(toolType: 'shared');
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);
      
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} is now available as a shared tool'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertToInventoryTool(BuildContext context, Tool tool) async {
    try {
      final updatedTool = tool.copyWith(toolType: 'inventory');
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);
      
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name} moved back to inventory'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

