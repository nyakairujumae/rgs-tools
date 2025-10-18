import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../../providers/supabase_tool_provider.dart";
import '../../providers/auth_provider.dart';
import '../../models/tool.dart';
import '../tool_detail_screen.dart';
import 'checkin_screen_web.dart';
import 'checkout_screen_web.dart';

class WebMyToolsScreen extends StatefulWidget {
  const WebMyToolsScreen({super.key});

  @override
  State<WebMyToolsScreen> createState() => _WebMyToolsScreenState();
}

class _WebMyToolsScreenState extends State<WebMyToolsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load tools to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseToolProvider, AuthProvider>(
      builder: (context, toolProvider, authProvider, child) {
        final tools = toolProvider.tools;
        final userId = authProvider.user?.id;
        
        // Get tools assigned to this technician
        final myTools = tools.where((tool) => tool.assignedTo == userId).toList();
        
        // Get unique categories for filter
        final categories = ['All', ...myTools.map((t) => t.category).toSet().toList()];
        
        // Filter tools based on search and filters
        final filteredTools = myTools.where((tool) {
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
                      colors: [Color(0xFF10B981), Color(0xFF059669)], // Green gradient for technicians
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                              'My Assigned Tools',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage and view your assigned tools',
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
                              builder: (context) => const CheckoutScreenWeb(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Check Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                      'My Tools (${filteredTools.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    if (filteredTools.isNotEmpty)
                      Text(
                        'Showing ${filteredTools.length} of ${myTools.length} tools',
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
            color: Colors.black.withValues(alpha: 0.05),
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
              hintText: 'Search your tools by name or brand...',
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
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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
                  items: ['All', 'Available', 'In Use', 'Maintenance'],
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
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your tools...',
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
            Icons.build_circle_outlined,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16),
          Text(
            'No tools assigned yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Contact your supervisor to get tools assigned to you',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
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
            childAspectRatio: 0.75, // Bigger cards for images and descriptions
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailScreen(tool: tool),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
            
            // Content Section
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
                    const SizedBox(height: 8),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Check In',
                            Icons.login,
                            const Color(0xFF10B981),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckinScreenWeb(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            'Details',
                            Icons.info,
                            const Color(0xFF3B82F6),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ToolDetailScreen(tool: tool),
                                ),
                              );
                            },
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
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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
        color: color.withValues(alpha: 0.1),
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
        color: color.withValues(alpha: 0.1),
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
