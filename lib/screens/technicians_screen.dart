import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../models/technician.dart';
import 'add_technician_screen.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseTechnicianProvider>(
      builder: (context, technicianProvider, child) {
        final technicians = technicianProvider.technicians;
        
        // Filter technicians based on search
        final filteredTechnicians = technicians.where((tech) {
          return _searchQuery.isEmpty ||
              tech.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tech.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (tech.department?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
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
          floatingActionButton: FloatingActionButton.extended(
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Theme.of(context).cardTheme.color,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: technician.status == 'Active' ? Colors.green : Colors.grey,
          child: Text(
            technician.name.isNotEmpty ? technician.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          technician.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
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
        trailing: PopupMenuButton(
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
}


