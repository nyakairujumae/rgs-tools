import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/technician.dart';
import 'add_technician_screen.dart';
import 'technician_detail_screen.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  String _searchQuery = '';
  Set<String> _selectedTechnicians = <String>{};
  List<String>? _selectedTools;

  @override
  void initState() {
    super.initState();
    // Check if we're coming from assign tool screen with selected tools
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedTools'] != null) {
        setState(() {
          _selectedTools = List<String>.from(args['selectedTools']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseTechnicianProvider>(
      builder: (context, technicianProvider, child) {
        final technicians = technicianProvider.technicians;
        
        // Filter technicians based on search and status
        // When assigning tools, only show Active technicians
        final filteredTechnicians = technicians.where((tech) {
          // Filter by status if in assignment mode
          if (_selectedTools != null && tech.status != 'Active') {
            return false;
          }
          // Filter by search query
          return _searchQuery.isEmpty ||
              tech.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tech.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (tech.department?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(_selectedTools != null ? 'Select Technicians' : 'Technicians'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            elevation: 0,
            actions: [],
          ),
          body: Column(
            children: [
              // Assignment Instructions (only show when assigning tools)
              if (_selectedTools != null)
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
                        'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to Technicians',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select one or more technicians to assign the tools to',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).cardTheme.color,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search technicians...',
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
              ),
              
              // Technicians List
              Expanded(
                child: technicianProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredTechnicians.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No technicians found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add your first technician to get started',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredTechnicians.length,
                            itemBuilder: (context, index) {
                              final technician = filteredTechnicians[index];
                              return _buildTechnicianCard(technician);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: _selectedTools != null 
              ? FloatingActionButton.extended(
                  onPressed: _selectedTechnicians.isNotEmpty ? () {
                    _assignToolsToTechnicians();
                  } : null,
                  icon: Icon(Icons.assignment_turned_in),
                  label: Text(_selectedTechnicians.isNotEmpty 
                      ? 'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} Technician${_selectedTechnicians.length > 1 ? 's' : ''}'
                      : 'Select Technicians First'),
                  backgroundColor: _selectedTechnicians.isNotEmpty 
                      ? Colors.green 
                      : Colors.grey,
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    _showAddTechnicianDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  backgroundColor: Colors.blue,
                ),
        );
      },
    );
  }

  Widget _buildTechnicianCard(Technician technician) {
    final isSelected = technician.id != null && _selectedTechnicians.contains(technician.id!);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isSelected 
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : Theme.of(context).cardTheme.color,
      child: ListTile(
        leading: _buildProfilePicture(technician),
        title: Text(
          technician.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        onTap: () {
          if (_selectedTools != null) {
            // Assignment mode - toggle selection
            setState(() {
              if (technician.id != null) {
                if (isSelected) {
                  _selectedTechnicians.remove(technician.id!);
                } else {
                  _selectedTechnicians.add(technician.id!);
                }
              }
            });
          } else {
            // Normal mode - navigate to detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TechnicianDetailScreen(technician: technician),
              ),
            );
          }
        },
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (technician.employeeId != null)
              Text(
                'ID: ${technician.employeeId}',
                style: TextStyle(color: Colors.grey),
              ),
            if (technician.department != null)
              Text(
                'Department: ${technician.department}',
                style: TextStyle(color: Colors.grey),
              ),
            if (technician.phone != null)
              Text(
                'Phone: ${technician.phone}',
                style: TextStyle(color: Colors.grey),
              ),
            Row(
              children: [
                _buildStatusChip(technician.status),
              ],
            ),
          ],
        ),
        trailing: _selectedTools != null 
            ? Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 24,
              )
            : PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditTechnicianDialog(technician);
            } else if (value == 'delete') {
              _showDeleteConfirmation(technician);
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfilePicture(Technician technician) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: technician.status == 'Active' ? Colors.green : Colors.grey,
      backgroundImage: technician.profilePictureUrl != null
          ? NetworkImage(technician.profilePictureUrl!)
          : null,
      child: technician.profilePictureUrl == null
          ? Text(
              technician.name.isNotEmpty ? technician.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Active' ? Colors.green : Colors.grey;
    
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

  void _showAddTechnicianDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTechnicianScreen(),
      ),
    );
  }

  void _showEditTechnicianDialog(Technician technician) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTechnicianScreen(technician: technician),
      ),
    );
  }

  void _showDeleteConfirmation(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Delete Technician',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete ${technician.name}?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<SupabaseTechnicianProvider>().deleteTechnician(technician.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${technician.name} deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _assignToolsToTechnicians() async {
    if (_selectedTools == null || _selectedTechnicians.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Assigning tools...'),
            ],
          ),
        ),
      );

      // Get technician provider and tool provider
      final technicianProvider = context.read<SupabaseTechnicianProvider>();
      final toolProvider = context.read<SupabaseToolProvider>();
      
      // Get technician details for each selected technician
      final technicians = technicianProvider.technicians.where((tech) => 
        tech.id != null && _selectedTechnicians.contains(tech.id!)
      ).toList();

      // Assign each tool to each selected technician
      for (final toolId in _selectedTools!) {
        for (final technician in technicians) {
          if (technician.id != null) {
            // Use technician UUID as the assigned_to value
            await toolProvider.assignTool(
              toolId,
              technician.id!,
              'Permanent',
            );
          }
        }
      }

      // Refresh tools to get updated data
      await toolProvider.loadTools();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully assigned ${_selectedTools!.length} tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} technician${_selectedTechnicians.length > 1 ? 's' : ''}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to admin dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning tools: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}


