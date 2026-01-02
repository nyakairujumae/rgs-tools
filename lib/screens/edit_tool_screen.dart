import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _category = '';
  String _condition = 'Good';
  String _status = 'Available';
  DateTime? _purchaseDate;
  bool _isLoading = false;
  String? _imagePath;
  File? _selectedImageFile;

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
    // Ensure category is in the list, otherwise set to empty
    final toolCategory = widget.tool.category;
    _category = _categories.contains(toolCategory) ? toolCategory : '';
    _brandController.text = widget.tool.brand ?? '';
    _modelController.text = widget.tool.model ?? '';
    _serialNumberController.text = widget.tool.serialNumber ?? '';
    _purchasePriceController.text = widget.tool.purchasePrice?.toString() ?? '';
    _currentValueController.text = widget.tool.currentValue?.toString() ?? '';
    _locationController.text = widget.tool.location ?? '';
    _notesController.text = widget.tool.notes ?? '';
    
    // Ensure condition and status are valid values
    const validConditions = ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'];
    final toolCondition = widget.tool.condition;
    _condition = validConditions.contains(toolCondition) ? toolCondition : 'Good';
    
    const validStatuses = ['Available', 'Assigned', 'In Use', 'Maintenance', 'Retired'];
    final toolStatus = widget.tool.status;
    _status = validStatuses.contains(toolStatus) ? toolStatus : 'Available';
    
    if (widget.tool.purchaseDate != null) {
      _purchaseDate = DateTime.tryParse(widget.tool.purchaseDate!);
    }
    _imagePath = widget.tool.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          'Edit Tool',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveTool,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tool Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tool name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _category.isEmpty ? null : (_categories.contains(_category) ? _category : null),
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
                      setState(() {
                        _category = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _currentValueController,
                          decoration: const InputDecoration(
                            labelText: 'Current Value',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                          color: _purchaseDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Tool Image',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      try {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt_outlined),
                                    title: const Text('Camera'),
                                    onTap: () => Navigator.pop(context, ImageSource.camera),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_outlined),
                                    title: const Text('Gallery'),
                                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (source == null) {
                          return;
                        }
                        final XFile? image = await _picker.pickImage(
                          source: source,
                          imageQuality: 85,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null) {
                          setState(() {
                            _selectedImageFile = File(image.path);
                            _imagePath = image.path;
                          });
                        }
                      } catch (e) {
                        handleError(e);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: _selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImageFile!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (_imagePath != null && _imagePath!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _imagePath!.startsWith('http')
                                      ? Image.network(
                                          _imagePath!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 180,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.image_outlined, size: 40, color: theme.hintColor),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Tap to add or change image',
                                                    style: TextStyle(color: theme.hintColor),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(_imagePath!),
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : Container(
                                  height: 180,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image_outlined, size: 40, color: theme.hintColor),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add or change image',
                                        style: TextStyle(color: theme.hintColor),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
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
        category: _category.trim(),
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
        imagePath: (_imagePath == null || _imagePath!.isEmpty) ? widget.tool.imagePath : _imagePath,
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
