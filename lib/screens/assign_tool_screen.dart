import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/tool.dart';
import 'tools_screen.dart';

class AssignToolScreen extends StatefulWidget {
  const AssignToolScreen({super.key});

  @override
  State<AssignToolScreen> createState() => _AssignToolScreenState();
}

class _AssignToolScreenState extends State<AssignToolScreen> {
  Set<String> _selectedTools = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Assign Tools'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_selectedTools.isNotEmpty)
            TextButton(
              onPressed: () {
                // Navigate to technicians screen with selected tools
                Navigator.pushNamed(
                  context,
                  '/technicians',
                  arguments: {'selectedTools': _selectedTools.toList()},
                );
              },
              child: Text(
                'Assign ${_selectedTools.length} Tool${_selectedTools.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Consumer<SupabaseToolProvider>(
        builder: (context, toolProvider, child) {
          final tools = toolProvider.tools;
          
          if (tools.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tools available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some tools first to assign them',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select tools to assign to technicians',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap tools to select them, then tap "Assign X Tools" to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Tools Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                    children: tools.map((tool) {
                      return _buildToolCard(context, tool);
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, Tool tool) {
    final isSelected = tool.id != null && _selectedTools.contains(tool.id!);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (tool.id != null) {
            if (isSelected) {
              _selectedTools.remove(tool.id!);
            } else {
              _selectedTools.add(tool.id!);
            }
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardTheme.color,
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: tool.imagePath!.startsWith('http')
                            ? Image.network(
                                tool.imagePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              )
                            : Image.asset(
                                tool.imagePath!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 2),
                    Text(
                      '${tool.brand ?? 'Unknown'} • ${tool.category}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(tool.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getStatusColor(tool.status), width: 0.5),
                            ),
                            child: Text(
                              tool.status,
                              style: TextStyle(
                                color: _getStatusColor(tool.status),
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(tool.condition).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getConditionColor(tool.condition), width: 0.5),
                            ),
                            child: Text(
                              tool.condition,
                              style: TextStyle(
                                color: _getConditionColor(tool.condition),
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Icon(
        Icons.build,
        size: 40,
        color: Colors.grey[400],
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
}