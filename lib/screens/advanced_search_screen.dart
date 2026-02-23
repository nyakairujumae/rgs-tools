import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';
import '../utils/responsive_helper.dart';
import 'tool_detail_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedCondition = 'All';
  String _selectedLocation = 'All';
  double _minValue = 0.0;
  double _maxValue = 10000.0;
  DateTime? _purchaseDateFrom;
  DateTime? _purchaseDateTo;
  bool _showOnlyFavorites = false;
  bool _showOnlyAssigned = false;
  
  List<Tool> _searchResults = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Search'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearFilters,
            icon: Icon(Icons.clear_all),
            tooltip: 'Clear All Filters',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = ResponsiveHelper.isDesktop(context);
            
            if (isDesktop) {
              return Row(
                children: [
                  // Search Form - Left Side
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text Search
                              _buildTextSearch(),
                              SizedBox(height: 16),

                              // Category Filter
                              _buildCategoryFilter(),
                              SizedBox(height: 16),

                              // Status and Condition Filters
                              Row(
                                children: [
                                  Expanded(child: _buildStatusFilter()),
                                  SizedBox(width: 12),
                                  Expanded(child: _buildConditionFilter()),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Location Filter
                              _buildLocationFilter(),
                              SizedBox(height: 16),

                              // Value Range
                              _buildValueRange(),
                              SizedBox(height: 16),

                              // Date Range
                              _buildDateRange(),
                              SizedBox(height: 16),

                              // Additional Filters
                              _buildAdditionalFilters(),
                              SizedBox(height: 16),

                              // Search Button
                              _buildSearchButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  
                  // Search Results - Right Side
                  Expanded(
                    flex: 1,
                    child: _buildSearchResults(),
                  ),
                ],
              );
            }
            
            // Mobile Layout
            return Column(
              children: [
                // Search Form
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text Search
                        _buildTextSearch(),
                        SizedBox(height: 24),

                        // Category Filter
                        _buildCategoryFilter(),
                        SizedBox(height: 24),

                        // Status and Condition Filters
                        Row(
                          children: [
                            Expanded(child: _buildStatusFilter()),
                            SizedBox(width: 16),
                            Expanded(child: _buildConditionFilter()),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Location Filter
                        _buildLocationFilter(),
                        SizedBox(height: 24),

                        // Value Range
                        _buildValueRange(),
                        SizedBox(height: 24),

                        // Date Range
                        _buildDateRange(),
                        SizedBox(height: 24),

                        // Additional Filters
                        _buildAdditionalFilters(),
                        SizedBox(height: 24),

                        // Search Button
                        _buildSearchButton(),
                      ],
                    ),
                  ),
                ),
                
                // Search Results
                Expanded(
                  flex: 3,
                  child: _buildSearchResults(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextSearch() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Text',
          style: TextStyle(
            fontSize: isDesktop ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 12),
        TextField(
          controller: _searchController,
          style: TextStyle(fontSize: isDesktop ? 13 : 14),
          decoration: InputDecoration(
            labelText: 'Search by name, brand, model, or serial number',
            labelStyle: TextStyle(fontSize: isDesktop ? 12 : 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 16,
              vertical: isDesktop ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.search, size: isDesktop ? 18 : 20),
            suffixIcon: Icon(Icons.clear, size: isDesktop ? 18 : 20),
          ),
          onChanged: (value) {
            if (value.isEmpty && _hasSearched) {
              _search();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: isDesktop ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 8 : 12),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          style: TextStyle(fontSize: isDesktop ? 13 : 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 16,
              vertical: isDesktop ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.category, size: isDesktop ? 18 : 20),
          ),
          items: _getCategoryOptions(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: isDesktop ? 13 : 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 6 : 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          style: TextStyle(fontSize: isDesktop ? 13 : 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 16,
              vertical: isDesktop ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.info, size: isDesktop ? 18 : 20),
          ),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Status')),
            DropdownMenuItem(value: 'Available', child: Text('Available')),
            DropdownMenuItem(value: 'In Use', child: Text('In Use')),
            DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
            DropdownMenuItem(value: 'Retired', child: Text('Retired')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildConditionFilter() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: TextStyle(
            fontSize: isDesktop ? 13 : 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 6 : 8),
        DropdownButtonFormField<String>(
          value: _selectedCondition,
          style: TextStyle(fontSize: isDesktop ? 13 : 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 16,
              vertical: isDesktop ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.construction, size: isDesktop ? 18 : 20),
          ),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Conditions')),
            DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
            DropdownMenuItem(value: 'Good', child: Text('Good')),
            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
            DropdownMenuItem(value: 'Poor', child: Text('Poor')),
            DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCondition = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLocation,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Locations')),
            DropdownMenuItem(value: 'Main Office', child: Text('Main Office')),
            DropdownMenuItem(value: 'Site A - Downtown', child: Text('Site A - Downtown')),
            DropdownMenuItem(value: 'Site B - Marina', child: Text('Site B - Marina')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLocation = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildValueRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Value Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _minValue.toString(),
                decoration: const InputDecoration(
                  labelText: 'Min Value',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minValue = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _maxValue.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max Value',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxValue = double.tryParse(value) ?? 10000.0;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Date Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectFromDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _purchaseDateFrom != null
                        ? '${_purchaseDateFrom!.day}/${_purchaseDateFrom!.month}/${_purchaseDateFrom!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: _purchaseDateFrom != null ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectToDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'To Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _purchaseDateTo != null
                        ? '${_purchaseDateTo!.day}/${_purchaseDateTo!.month}/${_purchaseDateTo!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: _purchaseDateTo != null ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        CheckboxListTile(
          title: Text('Show only favorites'),
          subtitle: Text('Filter to show only favorite tools'),
          value: _showOnlyFavorites,
          onChanged: (value) {
            setState(() {
              _showOnlyFavorites = value!;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Show only assigned tools'),
          subtitle: Text('Filter to show only tools currently assigned'),
          value: _showOnlyAssigned,
          onChanged: (value) {
            setState(() {
              _showOnlyAssigned = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _search,
        icon: Icon(Icons.search, size: isDesktop ? 18 : 20),
        label: Text(
          'Search Tools',
          style: TextStyle(fontSize: isDesktop ? 13 : 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 12 : 16,
            horizontal: isDesktop ? 16 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return Center(
        child: Text(
          'Enter search criteria and click "Search Tools" to find tools',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const EmptyState(
        title: 'No Tools Found',
        subtitle: 'Try adjusting your search criteria',
        icon: Icons.search_off,
      );
    }

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Found ${_searchResults.length} tool${_searchResults.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        // Results List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final tool = _searchResults[index];
              return _buildToolCard(tool);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(Tool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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

  List<String> _getToolImageUrls(Tool tool) {
    if (tool.imagePath == null || tool.imagePath!.isEmpty) {
      return [];
    }
    
    // Support both single image (backward compatibility) and multiple images (comma-separated)
    final imagePath = tool.imagePath!;
    
    // Check if it's comma-separated (multiple images)
    if (imagePath.contains(',')) {
      return imagePath.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    return [imagePath];
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

  List<DropdownMenuItem<String>> _getCategoryOptions() {
    return [
      const DropdownMenuItem(value: 'All', child: Text('All Categories')),
      const DropdownMenuItem(value: 'Testing Equipment', child: Text('Testing Equipment')),
      const DropdownMenuItem(value: 'HVAC Tools', child: Text('HVAC Tools')),
      const DropdownMenuItem(value: 'Power Tools', child: Text('Power Tools')),
      const DropdownMenuItem(value: 'Safety Equipment', child: Text('Safety Equipment')),
      const DropdownMenuItem(value: 'Measuring Tools', child: Text('Measuring Tools')),
    ];
  }

  Future<void> _selectFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDateFrom ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _purchaseDateFrom = date;
      });
    }
  }

  Future<void> _selectToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDateTo ?? DateTime.now(),
      firstDate: _purchaseDateFrom ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _purchaseDateTo = date;
      });
    }
  }

  void _search() {
    setState(() {
      _hasSearched = true;
      _searchResults = _performSearch();
    });
  }

  List<Tool> _performSearch() {
    return context.read<SupabaseToolProvider>().tools.where((tool) {
      // Text search
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        final matchesText = tool.name.toLowerCase().contains(searchText) ||
            (tool.brand?.toLowerCase().contains(searchText) ?? false) ||
            (tool.model?.toLowerCase().contains(searchText) ?? false) ||
            (tool.serialNumber?.toLowerCase().contains(searchText) ?? false);
        if (!matchesText) return false;
      }

      // Category filter
      if (_selectedCategory != 'All' && tool.category != _selectedCategory) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'All' && tool.status != _selectedStatus) {
        return false;
      }

      // Condition filter
      if (_selectedCondition != 'All' && tool.condition != _selectedCondition) {
        return false;
      }

      // Location filter
      if (_selectedLocation != 'All' && tool.location != _selectedLocation) {
        return false;
      }

      // Value range filter
      if ((tool.currentValue ?? 0.0) < _minValue || (tool.currentValue ?? 0.0) > _maxValue) {
        return false;
      }

      // Date range filter
      if (_purchaseDateFrom != null || _purchaseDateTo != null) {
        if (tool.purchaseDate != null) {
          final purchaseDate = DateTime.parse(tool.purchaseDate!);
          if (_purchaseDateFrom != null && purchaseDate.isBefore(_purchaseDateFrom!)) {
            return false;
          }
          if (_purchaseDateTo != null && purchaseDate.isAfter(_purchaseDateTo!)) {
            return false;
          }
        } else {
          return false;
        }
      }

      // Additional filters
      if (_showOnlyFavorites && tool.id != null && !_isFavorite(tool.id!)) {
        return false;
      }

      if (_showOnlyAssigned && tool.assignedTo == null) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _isFavorite(String toolId) {
    // Mock favorite IDs - in real app, this would come from user preferences
    final favoriteIds = ['1', '3', '5', '7', '9'];
    return favoriteIds.contains(toolId);
  }

  void _viewToolDetails(Tool tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolDetailScreen(tool: tool),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedCondition = 'All';
      _selectedLocation = 'All';
      _minValue = 0.0;
      _maxValue = 10000.0;
      _purchaseDateFrom = null;
      _purchaseDateTo = null;
      _showOnlyFavorites = false;
      _showOnlyAssigned = false;
      _searchResults.clear();
      _hasSearched = false;
    });
  }
}
