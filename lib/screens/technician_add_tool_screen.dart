import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../services/image_upload_service.dart';
import '../services/tool_id_generator.dart';
import '../theme/app_theme.dart';
import 'barcode_scanner_screen.dart';

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
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = '';
  String _condition = 'Good';
  String _status = 'Assigned';
  DateTime? _purchaseDate;
  File? _selectedImage;
  bool _isSaving = false;

  final List<String> _categories = const [
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

  final List<String> _conditions = const ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'];
  final List<String> _statuses = const ['Assigned', 'Available', 'In Use', 'Maintenance', 'Retired'];

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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradientFor(context)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Add My Tool'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          body: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppTheme.cardSurfaceColor(context),
                labelStyle: TextStyle(color: Colors.grey[700]),
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Tool Details'),
                    const SizedBox(height: 16),
                    _buildCardField(
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tool Name *',
                          hintText: 'e.g., Digital Multimeter',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter the tool name' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                hintText: 'e.g., Fluke',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCardField(
                            TextFormField(
                              controller: _modelController,
                              decoration: InputDecoration(
                                labelText: 'Model Number',
                                hintText: 'e.g., 87V',
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                                      tooltip: 'Generate',
                                      onPressed: _generateModelNumber,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                                      tooltip: 'Scan',
                                      onPressed: () => _scanBarcode(_modelController, 'Model number'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _buildGradientButton(
                        icon: Icons.auto_awesome,
                        label: 'Generate Model & Serial',
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                        onTap: _generateBothIds,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardField(
                      TextFormField(
                        controller: _serialNumberController,
                        decoration: InputDecoration(
                          labelText: 'Serial Number',
                          hintText: 'Scan or enter manually',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                                tooltip: 'Generate',
                                onPressed: _generateSerialNumber,
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                                tooltip: 'Scan',
                                onPressed: () => _scanBarcode(_serialNumberController, 'Serial number'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Purchase Information'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            TextFormField(
                              controller: _purchasePriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Price',
                                prefixText: 'AED ',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCardField(
                            TextFormField(
                              controller: _currentValueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Value',
                                prefixText: 'AED ',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCardField(
                      InkWell(
                        onTap: _selectPurchaseDate,
                        borderRadius: BorderRadius.circular(24),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Purchase Date'),
                          child: Text(
                            _purchaseDate != null
                                ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _purchaseDate != null ? Colors.black87 : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Condition & Status'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            DropdownButtonFormField<String>(
                              value: _condition,
                              items: _conditions
                                  .map((condition) => DropdownMenuItem(
                                        value: condition,
                                        child: Text(condition),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _condition = value ?? 'Good'),
                              decoration: const InputDecoration(labelText: 'Condition'),
                              dropdownColor: AppTheme.cardSurfaceColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCardField(
                            DropdownButtonFormField<String>(
                              value: _status,
                              items: _statuses
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _status = value ?? 'Assigned'),
                              decoration: const InputDecoration(labelText: 'Status'),
                              dropdownColor: AppTheme.cardSurfaceColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCardField(
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Van 2, Warehouse A',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardField(
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add extra information about this tool',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildGradientButton(
                      icon: Icons.save,
                      label: _isSaving ? 'Saving...' : 'Save Tool',
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                      onTap: _isSaving ? null : _saveTool,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tools you add here are also available to admins. Assign "Available" if the tool is ready for sharing, or keep "Assigned" if it is yours exclusively.',
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCardField(Widget child) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDisabled ? [Colors.grey, Colors.grey] : colors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: colors.last.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return _buildCardField(
      DropdownButtonFormField<String>(
        value: _selectedCategory.isEmpty ? null : _selectedCategory,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Category *', hintText: 'Select a category'),
        items: _categories
            .map(
              (category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value ?? '';
            _categoryController.text = value ?? '';
          });
        },
        validator: (value) =>
            _selectedCategory.isEmpty ? 'Please select a category' : null,
        dropdownColor: AppTheme.cardSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tool Image'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradientFor(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black87),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ),
                    ),
                  ],
                )
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _showImagePickerOptions,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_a_photo, color: Colors.blue.shade600, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add Tool Image',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to choose from gallery or camera',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
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
      builder: (context) => Padding(
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
            const SizedBox(height: 20),
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
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
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _scanBarcode(TextEditingController controller, String fieldName) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      setState(() => controller.text = result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fieldName scanned: $result'), backgroundColor: Colors.green),
      );
    }
  }

  void _generateModelNumber() {
    setState(() => _modelController.text = ToolIdGenerator.generateModelNumber());
  }

  void _generateSerialNumber() {
    setState(() => _serialNumberController.text = ToolIdGenerator.generateToolId());
  }

  void _generateBothIds() {
    final ids = ToolIdGenerator.generateBoth();
    setState(() {
      _modelController.text = ids['model']!;
      _serialNumberController.text = ids['serial']!;
    });
  }

  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final technicianId = authProvider.userId;

    if (technicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine technician account. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await ImageUploadService.uploadImage(_selectedImage!, tempId);
      }

      final tool = Tool(
        name: _nameController.text.trim(),
        category: _selectedCategory.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        purchaseDate: _purchaseDate?.toIso8601String().split('T').first,
        purchasePrice: _purchasePriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_purchasePriceController.text.trim()),
        currentValue: _currentValueController.text.trim().isEmpty
            ? null
            : double.tryParse(_currentValueController.text.trim()),
        condition: _condition,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        status: _status,
        toolType: 'inventory',
        assignedTo: _status == 'Assigned' || _status == 'In Use' ? technicianId : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        imagePath: imageUrl,
      );

      await context.read<SupabaseToolProvider>().addTool(tool);
      await context.read<SupabaseToolProvider>().loadTools();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tool "${tool.name}" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding tool: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
