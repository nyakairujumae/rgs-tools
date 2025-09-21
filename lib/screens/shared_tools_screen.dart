import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import '../models/tool.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Shared Tools'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          _buildSearchSection(),
          
          // Filter Chips
          _buildFilterChips(),
          
          // Tools List
          Expanded(
            child: Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
              builder: (context, toolProvider, technicianProvider, child) {
                final tools = _getFilteredTools(toolProvider.tools);
                
                if (toolProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (tools.isEmpty) {
                  return EmptyState(
                    icon: Icons.share,
                    title: _selectedFilter == 'All' ? 'No Shared Tools' : 'No Tools Found',
                    subtitle: _selectedFilter == 'All' 
                        ? 'Add tools to make them available for sharing'
                        : 'Try adjusting your filters or search terms',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await toolProvider.loadTools();
                  },
                  color: AppTheme.primaryColor,
                  backgroundColor: Theme.of(context).cardTheme.color,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'Search shared tools...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Theme.of(context).textTheme.bodyLarge?.color,
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolCard(Tool tool, SupabaseTechnicianProvider technicianProvider) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tool-detail',
            arguments: tool,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tool Image/Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                ),
                child: tool.imagePath != null && File(tool.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(tool.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.build,
                              color: Colors.grey[400],
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.build,
                        color: Colors.grey[400],
                        size: 30,
                      ),
              ),
              
              SizedBox(width: 16),
              
              // Tool Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${tool.category} • ${tool.brand ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(
                          status: tool.status,
                        ),
                        SizedBox(width: 8),
                        if (tool.currentValue != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '\$${tool.currentValue!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      _showToolActions(tool, technicianProvider);
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  if (tool.status == 'Available')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Shareable',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Tool> _getFilteredTools(List<Tool> tools) {
    var filteredTools = tools.where((tool) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!tool.name.toLowerCase().contains(query) &&
            !tool.category.toLowerCase().contains(query) &&
            !(tool.brand?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Category filter
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
          // Show tools added in the last 7 days
          if (tool.createdAt == null) return false;
          final createdAt = DateTime.tryParse(tool.createdAt!);
          if (createdAt == null) return false;
          final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
          return daysSinceCreated <= 7;
        default:
          return true;
      }
    }).toList();

    // Sort by name
    filteredTools.sort((a, b) => a.name.compareTo(b.name));
    
    return filteredTools;
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
            SizedBox(height: 16),
            ..._filterOptions.map((filter) => ListTile(
              title: Text(
                filter,
                style: TextStyle(
                  color: _selectedFilter == filter ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
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
            )),
          ],
        ),
      ),
    );
  }

  void _showToolActions(Tool tool, SupabaseTechnicianProvider technicianProvider) {
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              tool.name,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (tool.status == 'Available') ...[
              ListTile(
                leading: Icon(Icons.person_add, color: AppTheme.primaryColor),
                title: Text('Assign to Technician', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/assign-tool', arguments: tool);
                },
              ),
            ],
            if (tool.status == 'In Use') ...[
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppTheme.accentColor),
                title: Text('Reassign Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reassign-tool', arguments: tool);
                },
              ),
              ListTile(
                leading: Icon(Icons.keyboard_return, color: Colors.green),
                title: Text('Check In Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/checkin');
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.edit, color: Colors.orange),
              title: Text('Edit Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/edit-tool', arguments: tool);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text('View Details', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
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
}
