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
          
          return Column(
              children: [
              // Modern Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 40, // Smaller, more modern height
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20), // More rounded for modern look
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                        child: TextField(
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14, // Smaller font for modern look
                    ),
                          decoration: InputDecoration(
                            hintText: 'Search tools...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: 18, // Smaller icon
                      ),
                            border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
              ),
              
              // Content with proper spacing
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                
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
                      SizedBox(height: 16),
                
                      // Simplified Assignment Button
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_ind,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Assign Tools to Technicians',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Select technicians and assign tools to them',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/technicians');
                              },
                              icon: Icon(Icons.people),
                              label: Text('Go to Technicians'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Tools tab is selected
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false, arguments: {'initialTab': 0});
              break;
            case 1:
              // Already on tools screen
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false, arguments: {'initialTab': 2});
              break;
            case 3:
              Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false, arguments: {'initialTab': 3});
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Shared',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Technicians',
          ),
        ],
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
              // Image Section - Reduced height to prevent overflow
              SizedBox(
                height: 120, // Reduced from 150px to 120px
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
              
              // Content Section - Flexible to prevent overflow
              Container(
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
                        fontSize: 12,
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
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 1),
                    
                    // Status and Condition Chips
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusChip(tool.status),
                        ),
                        SizedBox(width: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getStatusColor(status), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _getConditionColor(condition).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getConditionColor(condition), width: 0.5),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: _getConditionColor(condition),
          fontSize: 9,
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