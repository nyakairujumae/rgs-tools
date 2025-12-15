import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../services/image_upload_service.dart';
import '../services/tool_id_generator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
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

  // Using theme extensions for all decorations

  Widget _buildCategoryDropdownRow(ThemeData theme, String category) {
    final icon = _categoryIcons[category] ?? Icons.category_outlined;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add New Tool',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Create a new inventory entry',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _saveTool,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: ResponsiveHelper.isDesktop(context)
                  ? _buildDesktopLayout(context, theme)
                  : _buildMobileLayout(context, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                    // Basic Information
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image Selection Section
                    _buildImageSelectionSection(),
                    const SizedBox(height: 24),

                    ThemedTextField(
                      controller: _nameController,
                      label: 'Tool Name *',
                      hint: 'e.g., Digital Multimeter',
                      prefixIcon: Icons.build_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tool name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory.isEmpty
                          ? null
                          : _selectedCategory,
                      decoration: context.chatGPTInputDecoration.copyWith(
                        labelText: 'Category *',
                        hintText: 'Select a category',
                        prefixIcon: Icon(
                          _categoryIcons[_selectedCategory.isEmpty ? 'Other' : _selectedCategory] ?? Icons.category_outlined,
                          size: 22,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 52),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildCategoryDropdownRow(theme, category),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return _categories
                            .map(
                              (category) => Align(
                                alignment: Alignment.centerLeft,
                                child: _buildCategoryDropdownRow(theme, category),
                              ),
                            )
                            .toList();
                      },
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
                      dropdownColor: Theme.of(context).colorScheme.surface,
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
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ThemedTextField(
                            controller: _brandController,
                            label: 'Brand',
                            hint: 'e.g., Fluke',
                            prefixIcon: Icons.branding_watermark_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ThemedTextField(
                            controller: _modelController,
                            label: 'Model Number',
                            hint: 'e.g., 87V',
                            prefixIcon: Icons.tag_outlined,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.auto_awesome,
                                      color: AppTheme.secondaryColor, size: 20),
                                  tooltip: 'Generate Model Number',
                                  onPressed: _generateModelNumber,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner,
                                      color: Colors.green, size: 20),
                                  tooltip: 'Scan Model Number',
                                  onPressed: () => _scanBarcode(
                                      _modelController, 'Model number'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Generate Both Button
                    Center(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _generateBothIds,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                            ),
                            elevation: 0, // No elevation - clean design
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: const Text(
                            'Generate Model & Serial Numbers',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ThemedTextField(
                      controller: _serialNumberController,
                      label: 'Serial Number',
                      hint: 'Scan or enter manually',
                      prefixIcon: Icons.qr_code_outlined,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.auto_awesome,
                                color: Colors.blue, size: 20),
                            tooltip: 'Generate Unique ID',
                            onPressed: _generateToolId,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner,
                                color: Colors.green, size: 20),
                            tooltip: 'Scan Serial Number',
                            onPressed: () => _scanBarcode(
                                _serialNumberController, 'Serial number'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Scan barcode/QR code or generate ID for tools without serial numbers',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      height: 32,
                      thickness: 0.8,
                      color: theme.colorScheme.onSurface.withOpacity(0.12),
                      indent: 4,
                      endIndent: 4,
                    ),
                    const SizedBox(height: 24),

                    // Purchase Information
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Purchase Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ThemedTextField(
                      controller: _purchasePriceController,
                      label: 'Purchase Price',
                      hint: '0.00',
                      prefixIcon: Icons.attach_money_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        // Add currency formatter if needed
                      ],
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _selectPurchaseDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.04),
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 22,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _purchaseDate != null
                                    ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _purchaseDate != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status and Condition
                    Text(
                      'Status & Condition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 16),
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
                    const SizedBox(height: 12),

                    ThemedTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'e.g., Tool Room A, Van 1',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),

                    ThemedTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hint: 'Additional information...',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ThemedButton(
                        onPressed: _isLoading ? null : _saveTool,
                        isLoading: _isLoading,
                        child: const Text(
                          'Add Tool',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Image Selection Section - Full Width
            _buildImageSelectionSection(),
            const SizedBox(height: 16),

            // Two Column Layout for Form Fields
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactTextField(
                        controller: _nameController,
                        label: 'Tool Name *',
                        hint: 'e.g., Digital Multimeter',
                        prefixIcon: Icons.build_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter tool name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCompactDropdown(
                        label: 'Category *',
                        value: _selectedCategory.isEmpty ? null : _selectedCategory,
                        items: _categories,
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
                      const SizedBox(height: 12),
                      _buildCompactTextField(
                        controller: _brandController,
                        label: 'Brand',
                        hint: 'e.g., Fluke',
                        prefixIcon: Icons.branding_watermark_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactTextField(
                        controller: _modelController,
                        label: 'Model Number',
                        hint: 'e.g., 87V',
                        prefixIcon: Icons.tag_outlined,
                        suffixIcons: [
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondaryColor),
                            tooltip: 'Generate Model Number',
                            onPressed: _generateModelNumber,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.green),
                            tooltip: 'Scan Model Number',
                            onPressed: () => _scanBarcode(_modelController, 'Model number'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCompactTextField(
                        controller: _serialNumberController,
                        label: 'Serial Number',
                        hint: 'Scan or enter manually',
                        prefixIcon: Icons.qr_code_outlined,
                        suffixIcons: [
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
                            tooltip: 'Generate Unique ID',
                            onPressed: _generateToolId,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.green),
                            tooltip: 'Scan Serial Number',
                            onPressed: () => _scanBarcode(_serialNumberController, 'Serial number'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _generateBothIds,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                              ),
                              elevation: 0, // No elevation - clean design
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                            ),
                            icon:
                                const Icon(Icons.auto_awesome, size: 18),
                            label: const Text(
                              'Generate Both',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),

            // Purchase Information
            Text(
              'Purchase Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller: _purchasePriceController,
                    label: 'Purchase Price',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePickerField(context, theme),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 20),

            // Status & Condition
            Text(
              'Status & Condition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
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
                const SizedBox(width: 16),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g., Tool Room A, Van 1',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Additional information...',
              prefixIcon: Icons.note_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ThemedButton(
                onPressed: _isLoading ? null : _saveTool,
                isLoading: _isLoading,
                child: const Text(
                  'Add Tool',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<Widget>? suffixIcons,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    final suffixIconWidget = suffixIcons != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: suffixIcons,
          )
        : null;
    return ThemedTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIconWidget,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(
          _categoryIcons[value ?? 'Other'] ?? Icons.category_outlined,
          size: 22,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildCategoryDropdownRow(theme, item),
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: _buildCategoryDropdownRow(theme, item),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
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

  Widget _buildCompactStatusDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final displayIcon = icon ?? (label == 'Condition' ? Icons.star_outline : Icons.info_outline);
    
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: label,
        hintText: 'Select $label',
        prefixIcon: Icon(
          displayIcon,
          size: 22,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
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
      dropdownColor: Colors.white,
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

  Widget _buildDatePickerField(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: _selectPurchaseDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.04),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _purchaseDate != null
                    ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                    : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _purchaseDate != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ),
          ],
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
        List<String> localImagePaths = [];
        
        for (var imageFile in _selectedImages) {
          try {
            final imageUrl = await ImageUploadService.uploadImage(
                imageFile, addedTool.id!);
            if (imageUrl != null) {
              uploadedImageUrls.add(imageUrl);
            }
          } catch (e) {
            // If Supabase upload fails, fall back to local storage
            try {
              final localImagePath =
                  await _saveImageLocally(imageFile, addedTool.id!);
              localImagePaths.add(localImagePath);
            } catch (e2) {
              // Skip this image if both fail
            }
          }
        }
        
        // Combine all image URLs
        final allImageUrls = [...uploadedImageUrls, ...localImagePaths];
        
        if (allImageUrls.isNotEmpty) {
          // Store as JSON array if multiple images, single string if one image
          final imagePathValue = allImageUrls.length > 1
              ? allImageUrls.join(',') // For now, use comma-separated. Later can use JSON
              : allImageUrls.first;
          
          final updatedTool = addedTool.copyWith(imagePath: imagePathValue);
          await context.read<SupabaseToolProvider>().updateTool(updatedTool);
          
          if (mounted && localImagePaths.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Tool saved with ${allImageUrls.length} image(s). Some images saved locally.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Reload tools to refresh all screens
      await context.read<SupabaseToolProvider>().loadTools();

      debugPrint('✅ Admin tool added - ID: ${addedTool.id}');
      debugPrint(
          '✅ Tool type: ${addedTool.toolType}, Status: ${addedTool.status}');
      debugPrint('✅ AssignedTo: ${addedTool.assignedTo}');

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
                    'Tool added successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.pop(context); // Close add tool screen
                    _navigateToAllTools(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
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
        Navigator.pop(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveHelper.isDesktop(context) ? 150 : 180,
            maxHeight: ResponsiveHelper.isDesktop(context) ? 200 : 220,
          ),
          width: double.infinity,
          decoration: context.cardDecoration.copyWith(
            borderRadius: BorderRadius.circular(18), // Match card decoration
          ),
          child: _selectedImages.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18), // Match card decoration
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      if (_selectedImages.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _selectedImages.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedImages.length < 10)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75)),
                                  onPressed: _showImagePickerOptions,
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.75)),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showImagePickerOptions,
                      borderRadius: BorderRadius.circular(18), // Match card decoration
                      splashColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.06),
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo,
                              size: 28,
                              color: AppTheme.secondaryColor.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedImages.isEmpty
                                ? 'Add Tool Images'
                                : 'Add More Images',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedImages.isEmpty
                                ? ResponsiveHelper.isDesktop(context)
                                    ? 'Click to select (Up to 10)'
                                    : 'Tap to select (Up to 10)'
                                : '${_selectedImages.length} image(s) selected',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.55),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
        decoration: context.cardDecoration.copyWith(
          color: AppTheme.secondaryColor.withOpacity(0.08),
        ),
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
