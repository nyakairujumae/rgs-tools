import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/tool.dart';
import '../models/user_role.dart';

class TechnicianAddToolScreen extends StatefulWidget {
  const TechnicianAddToolScreen({super.key});

  @override
  State<TechnicianAddToolScreen> createState() => _TechnicianAddToolScreenState();
}

class _TechnicianAddToolScreenState extends State<TechnicianAddToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _condition = 'Good';
  String _status = 'Available';
  bool _isLoading = false;

  final List<String> _conditions = ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'];
  final List<String> _statuses = ['Available', 'In Use', 'Maintenance', 'Retired'];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tool'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Important notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is for initial setup only. After setup, only admins can add tools.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Tool name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tool Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter tool name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Power Tools, Hand Tools, Electrical',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Brand and Model row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Serial number
              TextFormField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Condition and Status row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: _conditions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _condition = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Warehouse A, Truck 1',
                ),
              ),
              
              SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Additional information about the tool',
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Tool',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tool = Tool(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        condition: _condition,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        status: _status,
        toolType: 'inventory', // Set as inventory tool
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await context.read<SupabaseToolProvider>().addTool(tool);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tool added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding tool: $e'),
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
