import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import 'tool_detail_screen.dart';
import 'add_tool_screen.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  
  const ToolsScreen({super.key, this.initialStatusFilter});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Theme.of(context).cardTheme.color,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search tools...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    
                    // Filter Row - Stack vertically to prevent overflow
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredTools.length,
                            itemBuilder: (context, index) {
                              final tool = filteredTools[index];
                              return _buildToolCard(tool);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(tool.status),
          backgroundImage: tool.imagePath != null 
              ? FileImage(File(tool.imagePath!)) 
              : null,
          child: tool.imagePath == null 
              ? Icon(
                  Icons.build,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                )
              : null,
        ),
        title: Text(
          tool.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tool.category} • ${tool.brand ?? 'Unknown'}'),
            if (tool.serialNumber != null)
              Text('SN: ${tool.serialNumber}'),
            Row(
              children: [
                _buildStatusChip(tool.status),
                SizedBox(width: 8),
                _buildConditionChip(tool.condition),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool Type Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getToolTypeColor(tool.toolType),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tool.toolType.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tool.currentValue != null)
                  Text(
                    '\$${tool.currentValue!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        },
        onLongPress: () => _showToolActions(context, tool),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'In Use':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      case 'Retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getToolTypeColor(String toolType) {
    switch (toolType) {
      case 'inventory':
        return Colors.grey;
      case 'shared':
        return Colors.blue;
      case 'assigned':
        return Colors.green;
      default:
        return Colors.grey;
    }
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

