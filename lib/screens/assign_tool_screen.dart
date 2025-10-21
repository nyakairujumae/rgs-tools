import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import 'permanent_assignment_screen.dart';

class AssignToolScreen extends StatefulWidget {
  const AssignToolScreen({super.key});

  @override
  State<AssignToolScreen> createState() => _AssignToolScreenState();
}

class _AssignToolScreenState extends State<AssignToolScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'Available';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Assign Tool'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Consumer<SupabaseToolProvider>(
        builder: (context, toolProvider, child) {
          final tools = toolProvider.tools;
          
          // Filter tools based on search and status
          final filteredTools = tools.where((tool) {
            final matchesSearch = _searchQuery.isEmpty ||
                tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            
            final matchesCategory = _selectedCategory == 'All' || tool.category == _selectedCategory;
            final matchesStatus = _selectedStatus == 'All' || tool.status == _selectedStatus;
            
            return matchesSearch && matchesCategory && matchesStatus;
          }).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Search tools...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedCategory, (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }),
                      SizedBox(width: 8),
                      _buildFilterChip('Available', _selectedStatus, (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }),
                      SizedBox(width: 8),
                      _buildFilterChip('In Use', _selectedStatus, (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Tools Grid
                filteredTools.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(Icons.build, size: 64, color: Colors.grey[600]),
                            SizedBox(height: 16),
                            Text(
                              'No tools found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                        children: filteredTools.map((tool) {
                          return _buildToolCard(context, tool);
                        }).toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue, Function(String) onTap) {
    final isSelected = label == selectedValue;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, Tool tool) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showAssignDialog(context, tool);
        },
        child: Container(
          height: 250, // Same as all tools cards
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section - Same as all tools cards
              SizedBox(
                height: 150, // 60% of 250px = 150px
                width: double.infinity,
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
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
              
              // Content Section - Same as all tools cards
              Container(
                height: 70,
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tool Name
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 1),
                    
                    // Brand and Category
                    Text(
                      '${tool.brand ?? 'Unknown'} • ${tool.category}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 2),
                    
                    // Status and Condition Chips
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusChip(tool.status),
                        ),
                        SizedBox(width: 3),
                        Expanded(
                          child: _buildConditionChip(tool.condition),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 50, // Increased from 40 to 50 for better visibility
            color: Colors.grey[400],
          ),
          SizedBox(height: 6), // Increased spacing
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getConditionColor(condition).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getConditionColor(condition), width: 1),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: _getConditionColor(condition),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in use':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAssignDialog(BuildContext context, Tool tool) {
    // Navigate directly to the assignment form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermanentAssignmentScreen(tool: tool),
      ),
    );
  }
}