import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';

class AssignToolScreen extends StatefulWidget {
  const AssignToolScreen({super.key});

  @override
  State<AssignToolScreen> createState() => _AssignToolScreenState();
}

class _AssignToolScreenState extends State<AssignToolScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'Available';
  Set<String> _selectedTools = <String>{};

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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tools...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
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
                      _buildFilterChip('Electrical', _selectedCategory, (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }),
                      SizedBox(width: 8),
                      _buildFilterChip('Plumbing', _selectedCategory, (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }),
                      SizedBox(width: 8),
                      _buildFilterChip('Testing Equipment', _selectedCategory, (value) {
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
                        childAspectRatio: 0.8,
                        children: filteredTools.map((tool) {
                          return _buildToolCard(context, tool);
                        }).toList(),
                      ),
                SizedBox(height: 20),
                
                // Assign To Button
                if (_selectedTools.isNotEmpty)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/technicians');
                      },
                      icon: Icon(Icons.people),
                      label: Text('Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''} to Technicians'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
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

  Widget _buildToolCard(BuildContext context, Tool tool) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            if (tool.id != null) {
              if (_selectedTools.contains(tool.id!)) {
                _selectedTools.remove(tool.id!);
              } else {
                _selectedTools.add(tool.id!);
              }
            }
          });
        },
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (tool.id != null && _selectedTools.contains(tool.id!)) 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.withValues(alpha: 0.3),
              width: (tool.id != null && _selectedTools.contains(tool.id!)) ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tool.id != null && _selectedTools.contains(tool.id!))
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Theme.of(context).cardTheme.color ?? Colors.white,
                (tool.id != null && _selectedTools.contains(tool.id!))
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                    : (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              SizedBox(
                height: 120,
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
              
              // Content Section - Fixed height to prevent overflow
              Container(
                height: 50, // Further reduced height to account for selection border
                padding: const EdgeInsets.all(3.0), // Further reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tool Name
                    Flexible(
                      child: Text(
                        tool.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10, // Further reduced from 11
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: 1),
                    
                    // Brand and Category
                    Flexible(
                      child: Text(
                        '${tool.brand ?? 'Unknown'} • ${tool.category}',
                        style: TextStyle(
                          fontSize: 8, // Further reduced from 9
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: 2),
                    
                    // Status and Condition Chips
                    Flexible(
                      child: Row(
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Icon(
        Icons.build,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue, Function(String) onSelected) {
    final isSelected = selectedValue == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(label);
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
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
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
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
}