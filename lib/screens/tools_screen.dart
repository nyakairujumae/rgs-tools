import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import 'tool_detail_screen.dart';
import 'add_tool_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

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
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).cardTheme.color,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search tools...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    
                    // Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        trailing: Column(
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        },
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
}

