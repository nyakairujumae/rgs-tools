import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../providers/auth_provider.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../models/tool.dart';
import '../services/image_upload_service.dart';
import '../services/tool_id_generator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'barcode_scanner_screen.dart';

class AddToolScreen extends StatefulWidget {
  final bool isFromMyTools;
  
  const AddToolScreen({super.key, this.isFromMyTools = false});

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
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _condition = 'Good';
  String _status = 'Available';
  String _selectedCategory = '';
  DateTime? _purchaseDate;
  bool _isLoading = false;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  late PageController _imagePageController;

  // Tool categories.
  static const List<String> _fallbackCategories = [
    'Hand Tools', 'Power Tools', 'Testing Equipment', 'Safety Equipment',
    'Measuring Tools', 'Other',
  ];

  List<String> _getCategories(BuildContext context) => _fallbackCategories;

  final Map<String, IconData> _categoryIcons = {
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

  Widget _buildCategoryDropdownRow(ThemeData theme, String category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  TextStyle get fieldTextStyle {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
  }

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _purchasePriceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(
      TextEditingController controller, String fieldName) async {
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

  String _orgPrefix() => 'TOOL';

  void _generateToolId() {
    setState(() {
      _serialNumberController.text = ToolIdGenerator.generateToolId(prefix: _orgPrefix());
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
      _modelController.text = ToolIdGenerator.generateModelNumber(prefix: _orgPrefix());
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
    final ids = ToolIdGenerator.generateBoth(prefix: _orgPrefix());
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: theme.colorScheme.onSurface),
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
        foregroundColor: theme.colorScheme.onSurface,
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
                  child: _buildMobileLayout(context, theme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveTool,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Tool', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return Column(
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
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Please enter tool name' : null,
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
              color: const Color(0xFF6366F1),
            ),
          ),
          style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500),
          dropdownColor: context.dashboardSurfaceFill,
          borderRadius: BorderRadius.circular(20),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _getCategories(context).map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: _buildCategoryDropdownRow(theme, category),
            );
          }).toList(),
          onChanged: (value) => setState(() {
            _selectedCategory = value ?? '';
            _categoryController.text = value ?? '';
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
                  labelText: 'Model Number',
                  hintText: 'e.g., 87V',
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: Color(0xFF0EA5E9)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 18),
                        onPressed: _generateModelNumber,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondaryColor, size: 18),
                        onPressed: () => _scanBarcode(_modelController, 'Model number'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Generate Both button
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _generateBothIds,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: context.dashboardSurfaceCardDecoration(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Model & Serial Numbers',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.secondaryColor, size: 18),
                  onPressed: _generateToolId,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondaryColor, size: 18),
                  onPressed: () => _scanBarcode(_serialNumberController, 'Serial number'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
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
            hintText: '0.00',
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

        Row(
          children: [
            Expanded(
              child: _buildCompactStatusDropdown(
                label: 'Condition',
                value: _condition,
                items: ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'],
                onChanged: (value) => setState(() => _condition = value ?? _condition),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatusDropdown(
                label: 'Status',
                value: _status,
                items: ['Available', 'In Use', 'Maintenance', 'Retired'],
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _locationController,
          decoration: context.dashboardSurfaceInputDecoration(
            labelText: 'Location',
            hintText: 'e.g., Tool Room A, Van 1',
            prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFFEF4444)),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: context.dashboardSurfaceInputDecoration(
            labelText: 'Notes',
            hintText: 'Additional information...',
            prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildCompactStatusDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isCondition = label == 'Condition';
    final displayIcon = icon ?? (isCondition ? Icons.health_and_safety_outlined : Icons.toggle_on_outlined);
    final displayColor = isCondition ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: context.dashboardSurfaceInputDecoration(
        labelText: label,
        hintText: 'Select $label',
        prefixIcon: Icon(displayIcon, size: 20, color: displayColor),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
      dropdownColor: context.dashboardSurfaceFill,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(20),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        size: 18,
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
      // Get current user ID if adding from My Tools
      final authProvider = context.read<AuthProvider>();
      final currentUserId = widget.isFromMyTools ? authProvider.userId : null;

      // First, create the tool without image
      final tool = Tool(
        name: _nameController.text.trim().toUpperCase(),
        category: _categoryController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty
            ? null
            : _serialNumberController.text.trim(),
        purchaseDate: _purchaseDate?.toIso8601String().split('T')[0],
        purchasePrice: _purchasePriceController.text.isEmpty
            ? null
            : double.tryParse(_purchasePriceController.text),
        condition: _condition,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        status: _status,
        toolType: 'inventory', // Explicitly set to inventory for admin tools
        assignedTo: widget.isFromMyTools ? currentUserId : null, // Assign to current user if from My Tools
        imagePath: null, // Will be set after upload
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Add the tool first to get the ID
      final addedTool =
          await context.read<SupabaseToolProvider>().addTool(tool);

      // Now upload images if selected and update the tool with image URLs
      if (_selectedImages.isNotEmpty && addedTool.id != null) {
        List<String> uploadedImageUrls = [];
        
        for (var imageFile in _selectedImages) {
          try {
            final imageUrl = await ImageUploadService.uploadImage(
                imageFile, addedTool.id!);
            if (imageUrl != null) {
              uploadedImageUrls.add(imageUrl);
            }
          } catch (e) {
            debugPrint('⚠️ Image upload failed: $e');
          }
        }
        
        if (uploadedImageUrls.isNotEmpty) {
          final imagePathValue = uploadedImageUrls.length > 1
              ? uploadedImageUrls.join(',')
              : uploadedImageUrls.first;
          
          final updatedTool = addedTool.copyWith(imagePath: imagePathValue);
          await context.read<SupabaseToolProvider>().updateTool(updatedTool);
        }
      }

      // Reload tools to refresh all screens
      await context.read<SupabaseToolProvider>().loadTools();

      debugPrint('✅ Admin tool added - ID: ${addedTool.id}');
      debugPrint(
          '✅ Tool type: ${addedTool.toolType}, Status: ${addedTool.status}');
      debugPrint('✅ AssignedTo: ${addedTool.assignedTo}');

      // Save admin notification for the tool added event
      if (mounted) {
        final adminName = context.read<AuthProvider>().userFullName ?? 'Admin';
        final adminEmail = context.read<AuthProvider>().userEmail ?? '';
        try {
          await context.read<AdminNotificationProvider>().createNotification(
            technicianName: adminName,
            technicianEmail: adminEmail,
            type: NotificationType.general,
            title: 'New Tool Added',
            message: '$adminName added "${_nameController.text.trim().toUpperCase()}" to inventory.',
            data: {
              'tool_id': addedTool.id,
              'tool_name': addedTool.name,
              'category': addedTool.category,
              'action': 'tool_added',
            },
          );
        } catch (e) {
          debugPrint('⚠️ Failed to create tool-added notification: $e');
        }
      }

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
                    '${_nameController.text.trim().toUpperCase()} added successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
        // Navigate to the Tools tab
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin',
          (route) => false,
          arguments: {'initialTab': 1},
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _handleSave: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (mounted) {
        // Show detailed error message
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error adding tool',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_selectedImages.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _imagePageController,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) => Image.file(
                  _selectedImages[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_selectedImages.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _selectedImages.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImages.length < 10)
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedImages.clear()),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 28, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 10),
            const Text('Tap to attach photos',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryColor)),
            const SizedBox(height: 4),
            Text('Optional — up to 10 images',
                style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.45))),
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
            const SizedBox(height: 20),
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
              style: TextStyle(
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
      if (_selectedImages.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 10 images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
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
