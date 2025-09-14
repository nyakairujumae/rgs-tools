import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../models/technician.dart';

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
          backgroundColor: const Color(0xFF000000),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFF1A1A1A),
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
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTechnicians.isEmpty
                        ? const Center(
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
              print('FAB pressed!'); // Debug print
              _showAddTechnicianDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            backgroundColor: Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildTechnicianCard(Technician technician) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: technician.status == 'Active' ? Colors.green : Colors.grey,
          child: Text(
            technician.name.isNotEmpty ? technician.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          technician.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (technician.employeeId != null)
              Text(
                'ID: ${technician.employeeId}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (technician.department != null)
              Text(
                'Department: ${technician.department}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (technician.phone != null)
              Text(
                'Phone: ${technician.phone}',
                style: const TextStyle(color: Colors.grey),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddTechnicianDialog() {
    print('Add technician button pressed!'); // Debug print
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Technician'),
        content: const Text('This is a test dialog'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditTechnicianDialog(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => _TechnicianDialog(technician: technician),
    );
  }

  void _showDeleteConfirmation(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Technician',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${technician.name}?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TechnicianDialog extends StatefulWidget {
  final Technician? technician;

  const _TechnicianDialog({this.technician});

  @override
  State<_TechnicianDialog> createState() => _TechnicianDialogState();
}

class _TechnicianDialogState extends State<_TechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  
  String _status = 'Active';
  DateTime? _hireDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.technician != null) {
      _nameController.text = widget.technician!.name;
      _employeeIdController.text = widget.technician!.employeeId ?? '';
      _phoneController.text = widget.technician!.phone ?? '';
      _emailController.text = widget.technician!.email ?? '';
      _departmentController.text = widget.technician!.department ?? '';
      _status = widget.technician!.status;
      if (widget.technician!.hireDate != null) {
        _hireDate = DateTime.tryParse(widget.technician!.hireDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        widget.technician == null ? 'Add Technician' : 'Edit Technician',
        style: const TextStyle(color: Colors.white),
      ),
      content: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.white70),
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.blue,
            selectionColor: Colors.blue,
            selectionHandleColor: Colors.blue,
          ),
        ),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'Employee ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectHireDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hire Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _hireDate != null
                              ? '${_hireDate!.day}/${_hireDate!.month}/${_hireDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _hireDate != null ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTechnician,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.technician == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _selectHireDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _hireDate = date;
      });
    }
  }

  Future<void> _saveTechnician() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final technician = Technician(
        id: widget.technician?.id,
        name: _nameController.text.trim(),
        employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        hireDate: _hireDate?.toIso8601String().split('T')[0],
        status: _status,
      );

      if (widget.technician == null) {
        await context.read<SupabaseTechnicianProvider>().addTechnician(technician);
      } else {
        await context.read<SupabaseTechnicianProvider>().updateTechnician(technician);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.technician == null 
                ? 'Technician added successfully!' 
                : 'Technician updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

