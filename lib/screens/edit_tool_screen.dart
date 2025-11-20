import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';

class EditToolScreen extends StatefulWidget {
  final Tool tool;

  const EditToolScreen({super.key, required this.tool});

  @override
  State<EditToolScreen> createState() => _EditToolScreenState();
}

class _EditToolScreenState extends State<EditToolScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _condition = 'Good';
  String _status = 'Available';
  DateTime? _purchaseDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'Hand Tools',
    'Power Tools',
    'Testing Equipment',
    'Safety Equipment',
    'Measuring Tools',
    'Cutting Tools',
    'Fastening Tools',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.tool.name;
    _categoryController.text = widget.tool.category;
    _brandController.text = widget.tool.brand ?? '';
    _modelController.text = widget.tool.model ?? '';
    _serialNumberController.text = widget.tool.serialNumber ?? '';
    _purchasePriceController.text = widget.tool.purchasePrice?.toString() ?? '';
    _currentValueController.text = widget.tool.currentValue?.toString() ?? '';
    _locationController.text = widget.tool.location ?? '';
    _notesController.text = widget.tool.notes ?? '';
    _condition = widget.tool.condition;
    _status = widget.tool.status;
    
    if (widget.tool.purchaseDate != null) {
      _purchaseDate = DateTime.tryParse(widget.tool.purchaseDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tool'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTool,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information'),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tool Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Digital Multimeter',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tool name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  _categoryController.text = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Fluke',
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
                        hintText: 'e.g., 87V',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., FL123456789',
                ),
              ),
              SizedBox(height: 16),

              // Purchase Information
              _buildSectionHeader('Purchase Information'),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        border: OutlineInputBorder(),
                        hintText: '0.00',
                        prefixText: 'AED ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currentValueController,
                      decoration: const InputDecoration(
                        labelText: 'Current Value',
                        border: OutlineInputBorder(),
                        hintText: '0.00',
                        prefixText: 'AED ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              InkWell(
                onTap: _selectPurchaseDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Purchase Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _purchaseDate != null
                        ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: _purchaseDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Status and Condition
              _buildSectionHeader('Status & Condition'),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                        DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                        DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
                      ],
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
                      items: const [
                        DropdownMenuItem(value: 'Available', child: Text('Available')),
                        DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
                        DropdownMenuItem(value: 'In Use', child: Text('In Use')),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'Retired', child: Text('Retired')),
                      ],
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

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Tool Room A, Van 1',
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Additional information...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update Tool',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _purchaseDate = date;
      });
    }
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTool = widget.tool.copyWith(
        name: _nameController.text.trim().toUpperCase(),
        category: _categoryController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        purchaseDate: _purchaseDate?.toIso8601String().split('T')[0],
        purchasePrice: _purchasePriceController.text.isEmpty ? null : double.tryParse(_purchasePriceController.text),
        currentValue: _currentValueController.text.isEmpty ? null : double.tryParse(_currentValueController.text),
        condition: _condition,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tool updated successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF047857), // AppTheme.secondaryColor
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
        Navigator.pop(context, updatedTool);
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

