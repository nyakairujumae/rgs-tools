import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../../providers/supabase_tool_provider.dart";
import '../../models/tool.dart';
import 'tool_detail_screen.dart';
import 'web_add_tool_screen.dart';

class WebToolsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  
  const WebToolsScreen({super.key, this.initialStatusFilter});

  @override
  State<WebToolsScreen> createState() => _WebToolsScreenState();
}

class _WebToolsScreenState extends State<WebToolsScreen> {
  String _selectedCategory = 'All';
  late String _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseToolProvider>(
      builder: (context, toolProvider, child) {
        final tools = toolProvider.tools;
        final categories = ['All', ...toolProvider.getCategories()];
        
        // Filter tools based on search and filters
        final filteredTools = tools.where((tool) {
          final matchesSearch = _searchQuery.isEmpty ||
              tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final matchesCategory = _selectedCategory == 'All' || tool.category == _selectedCategory;
          final matchesStatus = _selectedStatus == 'All' || tool.status == _selectedStatus;
          
          return matchesSearch && matchesCategory && matchesStatus;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.build,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tools Management',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage and view all your tools',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WebAddToolScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add Tool',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Filters Section
                _buildFiltersSection(categories),

                const SizedBox(height: 24),

                // Tools Grid
                Row(
                  children: [
                    Text(
                      'Tools (${filteredTools.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    if (filteredTools.isNotEmpty)
                      Text(
                        'Showing ${filteredTools.length} of ${tools.length} tools',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (toolProvider.isLoading)
                  _buildLoadingState()
                else if (filteredTools.isEmpty)
                  _buildEmptyState()
                else
                  _buildToolsGrid(filteredTools),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(List<String> categories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextFormField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search tools by name or brand...',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Category',
                  value: _selectedCategory,
                  items: categories,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'All';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: ['All', 'Available', 'In Use', 'Maintenance', 'Retired'],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'All';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading tools...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.build,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16),
          Text(
            'No tools found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first tool to get started',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(List<Tool> tools) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        final crossAxisCount = isDesktop ? 3 : 2;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.65, // Adjusted for details below cards
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            return _buildToolCard(tools[index]);
          },
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool) {
    return MouseRegion(
      onEnter: (_) {
        // Show tooltip or additional details on hover
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: tool.imagePath != null && tool.imagePath!.isNotEmpty
                            ? tool.imagePath!.startsWith('http')
                                ? Image.network(
                                    tool.imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                  )
                                : Image.file(
                                    File(tool.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                  )
                            : _buildPlaceholderImage(),
                      ),
                    ),
                  ),
                  
                  // Content Section - Clean and minimal
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tool Name
                          Text(
                            tool.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Brand and Category
                          Text(
                            '${tool.brand ?? 'Unknown'} • ${tool.category}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Status and Condition
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusChip(tool.status),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildConditionChip(tool.condition),
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
            
            // Details below card (appear on hover or always visible)
            const SizedBox(height: 8),
            _buildToolDetailsBelow(tool),
          ],
        ),
      ),
    );
  }

  Widget _buildToolDetailsBelow(Tool tool) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Price
          if (tool.currentValue != null)
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 14,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  tool.currentValue?.toStringAsFixed(0) ?? '0',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          
          // Location
          if (tool.location != null)
            Flexible(
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tool.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      color: const Color(0xFFF3F4F6),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = const Color(0xFF10B981);
        break;
      case 'in use':
        color = const Color(0xFF3B82F6);
        break;
      case 'maintenance':
        color = const Color(0xFFF59E0B);
        break;
      case 'retired':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    Color color;
    switch (condition.toLowerCase()) {
      case 'excellent':
        color = const Color(0xFF10B981);
        break;
      case 'good':
        color = const Color(0xFF3B82F6);
        break;
      case 'fair':
        color = const Color(0xFFF59E0B);
        break;
      case 'poor':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        condition,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
