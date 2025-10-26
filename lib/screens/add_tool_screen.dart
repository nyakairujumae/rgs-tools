import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../services/image_upload_service.dart';
import '../services/tool_id_generator.dart';
import 'barcode_scanner_screen.dart';

class AddToolScreen extends StatefulWidget {
  const AddToolScreen({super.key});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
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
  String _selectedCategory = '';
  DateTime? _purchaseDate;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Hand Tools',
    'Power Tools',
    'Testing Equipment',
    'Safety Equipment',
    'Measuring Tools',
    'Cutting Tools',
    'Fastening Tools',
    'Electrical Tools',
    'Plumbing Tools',
    'Carpentry Tools',
    'Automotive Tools',
    'Garden Tools',
    'Other',
  ];

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

  Future<void> _scanBarcode(TextEditingController controller, String fieldName) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        controller.text = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fieldName scanned: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _generateToolId() {
    setState(() {
      _serialNumberController.text = ToolIdGenerator.generateToolId();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated unique serial number'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _generateModelNumber() {
    setState(() {
      _modelController.text = ToolIdGenerator.generateModelNumber();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated unique model number'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _generateBothIds() {
    final ids = ToolIdGenerator.generateBoth();
    setState(() {
      _modelController.text = ids['model']!;
      _serialNumberController.text = ids['serial']!;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated model and serial numbers'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add New Tool'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            labelStyle: TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            bodyMedium: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              
              // Image Selection Section
              _buildImageSelectionSection(),
              SizedBox(height: 24),
              
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
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Select a category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                    _categoryController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (_selectedCategory.isEmpty) {
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
                      decoration: InputDecoration(
                        labelText: 'Model Number',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., 87V',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                              tooltip: 'Generate Model Number',
                              onPressed: _generateModelNumber,
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                              tooltip: 'Scan Model Number',
                              onPressed: () => _scanBarcode(_modelController, 'Model number'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Generate Both Button
              Center(
                child: OutlinedButton.icon(
                  onPressed: _generateBothIds,
                  icon: const Icon(Icons.flash_on, color: Colors.orange),
                  label: const Text('Generate Both Model & Serial Numbers'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _serialNumberController,
                decoration: InputDecoration(
                  labelText: 'Serial Number',
                  border: const OutlineInputBorder(),
                  hintText: 'Scan or enter manually',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                        tooltip: 'Generate Unique ID',
                        onPressed: _generateToolId,
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                        tooltip: 'Scan Serial Number',
                        onPressed: () => _scanBarcode(_serialNumberController, 'Serial number'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  'Scan barcode/QR code or generate ID for tools without serial numbers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Purchase Information
              Text(
                'Purchase Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
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
                        prefixText: '\$ ',
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
                        prefixText: '\$ ',
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
                      color: _purchaseDate != null ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Status and Condition
              Text(
                'Status & Condition',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_condition),
                      initialValue: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Excellent', child: Text('Excellent', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Good', child: Text('Good', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Fair', child: Text('Fair', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Poor', child: Text('Poor', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
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
                      key: ValueKey(_status),
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Available', child: Text('Available', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'In Use', child: Text('In Use', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        DropdownMenuItem(value: 'Retired', child: Text('Retired', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Theme.of(context).textTheme.bodyLarge?.color)
                      : Text(
                          'Add Tool',
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
      // First, create the tool without image
      final tool = Tool(
        name: _nameController.text.trim(),
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
        toolType: 'inventory', // Explicitly set to inventory for admin tools
        imagePath: null, // Will be set after upload
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Add the tool first to get the ID
      final addedTool = await context.read<SupabaseToolProvider>().addTool(tool);

      // Now upload image if selected and update the tool with image URL
      if (_selectedImage != null && addedTool.id != null) {
        try {
          final imageUrl = await ImageUploadService.uploadImage(_selectedImage!, addedTool.id!);
          if (imageUrl != null) {
            // Update the tool with the image URL
            final updatedTool = addedTool.copyWith(imagePath: imageUrl);
            await context.read<SupabaseToolProvider>().updateTool(updatedTool);
          }
        } catch (e) {
          // If Supabase upload fails, fall back to local storage
          try {
            final localImagePath = await _saveImageLocally(_selectedImage!, addedTool.id!);
            final updatedTool = addedTool.copyWith(imagePath: localImagePath);
            await context.read<SupabaseToolProvider>().updateTool(updatedTool);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tool saved with local image (cloud upload failed: ${e.toString().split(':').last})'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e2) {
            // If both fail, just show the original error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tool saved but image upload failed: ${e.toString().split(':').last}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
      
      // Reload tools to refresh all screens
      await context.read<SupabaseToolProvider>().loadTools();
      
      debugPrint('✅ Admin tool added - ID: ${addedTool.id}');
      debugPrint('✅ Tool type: ${addedTool.toolType}, Status: ${addedTool.status}');
      debugPrint('✅ AssignedTo: ${addedTool.assignedTo}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tool added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View All Tools',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context); // Close add tool screen
                // Navigate to All Tools screen (index 1 in the bottom navigation)
                // Navigate to All Tools screen
                _navigateToAllTools(context);
              },
            ),
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

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tool Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.54),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _showImagePickerOptions,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add Tool Image',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to select from gallery or camera',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _saveImage(File imageFile) async {
    try {
      // For now, save the local path to the image
      // This ensures the image displays correctly
      return imageFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  Future<String> _saveImageLocally(File imageFile, String toolId) async {
    try {
      // Create a unique filename for local storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'tool_${toolId}_$timestamp.$extension';
      
      // For now, just return the original path
      // In a real app, you'd copy to a persistent directory
      return imageFile.path;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  void _navigateToAllTools(BuildContext context) {
    // Navigate back to the admin home screen and set the selected index to 1 (All Tools)
    Navigator.popUntil(context, (route) => route.isFirst);
    
    // Navigate to admin home screen with All Tools tab (index 1) selected
    Navigator.pushNamed(
      context, 
      '/admin',
      arguments: {'initialTab': 1}, // 1 = All Tools tab
    );
  }
}

