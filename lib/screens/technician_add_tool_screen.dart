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
import '../theme/theme_extensions.dart';
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

  final Map<String, IconData> _categoryIcons = const {
    'Hand Tools': Icons.build_outlined,
    'Power Tools': Icons.power_outlined,
    'Testing Equipment': Icons.science_outlined,
    'Safety Equipment': Icons.shield_outlined,
    'Measuring Tools': Icons.straighten_outlined,
    'Cutting Tools': Icons.cut_outlined,
    'Fastening Tools': Icons.construction_outlined,
    'Electrical Tools': Icons.electrical_services_outlined,
    'Plumbing Tools': Icons.plumbing_outlined,
    'Carpentry Tools': Icons.hardware_outlined,
    'Automotive Tools': Icons.car_repair_outlined,
    'Garden Tools': Icons.yard_outlined,
    'Other': Icons.category_outlined,
  };

  final List<String> _conditions = const ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'];

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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ),
        titleSpacing: 4,
        title: Text(
          'Add New Tool',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Image
                _buildImageSelectionSection(),
                const SizedBox(height: 24),

                // Tool Name
                TextFormField(
                  controller: _nameController,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Tool Name *',
                    hintText: 'e.g., Digital Multimeter',
                    prefixIcon: const Icon(Icons.handyman_outlined, size: 20, color: Color(0xFF6366F1)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter tool name' : null,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  isExpanded: true,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Category *',
                    hintText: 'Select a category',
                    prefixIcon: Icon(
                      _categoryIcons[_selectedCategory.isEmpty ? 'Other' : _selectedCategory] ?? Icons.category_outlined,
                      size: 20,
                    ),
                  ),
                  style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _categories.map((c) {
                    final icon = _categoryIcons[c] ?? Icons.category_outlined;
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: onSurface.withValues(alpha: 0.7)),
                          const SizedBox(width: 10),
                          Text(c, style: TextStyle(color: onSurface, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedCategory = v ?? '';
                    _categoryController.text = v ?? '';
                  }),
                  validator: (_) => _selectedCategory.isEmpty ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),

                // Brand + Model
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: context.dashboardSurfaceInputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g., Fluke',
                          prefixIcon: const Icon(Icons.label_outlined, size: 20, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: context.dashboardSurfaceInputDecoration(
                          labelText: 'Model',
                          hintText: 'e.g., 87V',
                          prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: Color(0xFF0EA5E9)),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondaryColor), onPressed: _generateModelNumber),
                              IconButton(icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppTheme.secondaryColor), onPressed: () => _scanBarcode(_modelController, 'Model number')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Generate button — subtle outlined
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generateBothIds,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate Model & Serial Numbers'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Serial Number
                TextFormField(
                  controller: _serialNumberController,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'Scan or enter manually',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.secondaryColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondaryColor), onPressed: _generateSerialNumber),
                        IconButton(icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppTheme.secondaryColor), onPressed: () => _scanBarcode(_serialNumberController, 'Serial number')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan barcode/QR code or generate ID for tools without serial numbers',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 28),

                // Purchase Information
                Text('Purchase Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface)),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _purchasePriceController,
                  keyboardType: TextInputType.number,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Purchase Price (optional)',
                    hintText: 'AED 0.00',
                    prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 16),

                // Purchase Date
                GestureDetector(
                  onTap: _selectPurchaseDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _purchaseDate != null
                            ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                            : '',
                      ),
                      decoration: context.dashboardSurfaceInputDecoration(
                        labelText: 'Purchase Date (optional)',
                        hintText: 'Select date',
                        prefixIcon: const Icon(Icons.event_outlined, size: 20, color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Status & Condition
                Text('Status & Condition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface)),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  key: ValueKey(_condition),
                  value: _condition,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Condition',
                    prefixIcon: const Icon(Icons.health_and_safety_outlined, size: 20, color: Color(0xFFEF4444)),
                  ),
                  style: TextStyle(color: onSurface, fontSize: 15),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _conditions.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: TextStyle(color: onSurface, fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _condition = v ?? _condition),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Van 2, Warehouse A',
                    prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: context.dashboardSurfaceInputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add extra information about this tool',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Tools you add are visible to admins. Keep "Assigned" if it\'s yours exclusively, or set "Available" to share.',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.45), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveTool,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Tool',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

  Widget _buildImageSelectionSection() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: context.dashboardSurfaceCardDecoration(radius: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 28,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to attach a photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional — camera or gallery',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: context.dashboardSurfaceCardDecoration(radius: 18),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.secondaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
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

  String _orgPrefix() {
    return 'TOOL';
  }

  void _generateModelNumber() {
    setState(() {
      _modelController.text = ToolIdGenerator.generateModelNumber(prefix: _orgPrefix());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated unique model number'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _generateSerialNumber() {
    setState(() {
      _serialNumberController.text = ToolIdGenerator.generateToolId(prefix: _orgPrefix());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated unique serial number'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _generateBothIds() {
    final ids = ToolIdGenerator.generateBoth(prefix: _orgPrefix());
    setState(() {
      _modelController.text = ids['model']!;
      _serialNumberController.text = ids['serial']!;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generated model and serial numbers'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
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

      final name = _capitalizeFirst(_nameController.text.trim());
      final brandInput = _brandController.text.trim();
      final brand =
          brandInput.isEmpty ? null : _capitalizeFirst(brandInput);

      final tool = Tool(
        name: name,
        category: _selectedCategory.trim(),
        brand: brand,
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

  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
