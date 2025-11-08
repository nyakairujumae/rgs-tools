import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import '../models/tool.dart';
import '../models/user_role.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
        child: Column(
          children: [
              // Section Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shared Tools',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
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
                  // Check if user is admin to show "Go to Tools" button
                  return Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isAdmin = authProvider.userRole == UserRole.admin;
                      
                      return EmptyState(
                        icon: Icons.share,
                        title: _selectedFilter == 'All' ? 'No Shared Tools' : 'No Tools Found',
                        subtitle: _selectedFilter == 'All' 
                            ? (isAdmin 
                                ? 'Go to All Tools to mark tools as "Shared" so they appear here'
                                : 'No shared tools available. Contact your admin to share tools.')
                            : 'Try adjusting your filters or search terms',
                        actionText: isAdmin ? 'Go to Tools' : null,
                        onAction: isAdmin ? () {
                          // Navigate to Admin Home with Tools tab selected
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/admin',
                            (route) => false,
                            arguments: {'initialTab': 1}, // Tools tab
                          );
                        } : null,
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.75, // Square image + compact details below
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
          controller: _searchController,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search shared tools...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
                  color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
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
          // Full Image Card - Square
          AspectRatio(
            aspectRatio: 1.0, // Perfect square
            child: Container(
                decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(28), // More rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow( // Second shadow for depth
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cardGradient,
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
                              )
                            : File(tool.imagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.file(
                                    File(tool.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                    fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                            )
                          : _buildPlaceholderImage())
                  : _buildPlaceholderImage(),
            ),
          ),
          
          // Details Below Card
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
                  children: [
                // Tool Name and Category in one line
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
                // Status and Value Pills
                    Row(
                      children: [
                        StatusChip(
                          status: tool.status,
                      showIcon: false,
                        ),
                    if (tool.currentValue != null) ...[
                      SizedBox(width: 6),
                          Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'AED ${tool.currentValue!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green,
                            fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                  ],
                ),
              ],
                      ),
                    ),
                ],
              ),
    );
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

  List<Tool> _getFilteredTools(List<Tool> tools) {
    debugPrint('🔍 Shared Tools Filter - Total tools: ${tools.length}');
    
    var filteredTools = tools.where((tool) {
      // Only show tools that are marked as 'shared' (available for checkout by any technician)
      // Do NOT show 'assigned' tools (technician's personal tools) or 'inventory' tools
      if (tool.toolType != 'shared') {
        return false;
      }

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
