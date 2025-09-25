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
    return GestureDetector(
      onTap: () {
        _showAssignDialog(context, tool);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tool Image Card
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Stack(
              children: [
                // Tool Image
                Center(
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: tool.imagePath != null
                          ? Image.file(
                              File(tool.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.build,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.build,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tool.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tool.status,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tool Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${tool.category} • ${tool.brand ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                if (tool.purchasePrice != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Value: AED ${tool.purchasePrice?.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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