import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../services/image_upload_service.dart';
import '../services/tool_id_generator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../widgets/premium_field_styles.dart';
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

  BoxDecoration _outlineDecoration(
    BuildContext context, {
    double radius = 24,
    bool showBorder = false,
    bool subtleFill = false,
  }) {
    final theme = Theme.of(context);
    final borderColor = context.cardBorder; // ChatGPT-style: #E5E5E5
    final backgroundColor =
        subtleFill ? context.cardBackground : theme.scaffoldBackgroundColor; // ChatGPT-style: #F5F5F5 or white

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder ? Border.all(color: borderColor, width: 1) : null, // ChatGPT-style: 1px border
      boxShadow: showBorder ? context.cardShadows : null, // ChatGPT-style: ultra-soft shadow when bordered
    );
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Add My Tool',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0, // ChatGPT-style: no elevation
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveTool,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                filled: false,
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
                floatingLabelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                  ),
                  borderSide: const BorderSide(
                    color: AppTheme.subtleBorder,
                    width: 1.1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                  ),
                  borderSide: const BorderSide(
                    color: AppTheme.subtleBorder,
                    width: 1.1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                  ),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                contentPadding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              textTheme: theme.textTheme.apply(
                bodyColor: theme.textTheme.bodyLarge?.color,
                displayColor: theme.textTheme.bodyLarge?.color,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                    // Image Selection Section
                    _buildImageSelectionSection(),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tool Name *',
                          hintText: 'e.g., Digital Multimeter',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter tool name';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory.isEmpty ? null : _selectedCategory,
                        isExpanded: true,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          hintText: 'Select a category',
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
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
                        dropdownColor: AppTheme.cardSurfaceColor(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: _outlineDecoration(context, radius: 24),
                            child: TextFormField(
                              controller: _brandController,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                hintText: 'e.g., Fluke',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        Expanded(
                          child: Container(
                            decoration: _outlineDecoration(context, radius: 24),
                            child: TextFormField(
                              controller: _modelController,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Model Number',
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
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Generate Both Button
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.55),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _generateBothIds,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            child: Padding(
                              padding: ResponsiveHelper.getResponsivePadding(
                                context,
                                horizontal: 24,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                                  Text(
                                    'Generate Both Model & Serial Numbers',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: TextFormField(
                        controller: _serialNumberController,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Serial Number',
                          hintText: 'Scan or enter manually',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.auto_awesome, color: Colors.blue),
                                tooltip: 'Generate Unique ID',
                                onPressed: _generateSerialNumber,
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
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Scan barcode/QR code or generate ID for tools without serial numbers',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    Divider(
                      height: 32,
                      thickness: 0.8,
                      color: AppTheme.subtleBorder.withOpacity(0.7),
                      indent: 4,
                      endIndent: 4,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                    // Purchase Information
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Purchase Information',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: TextFormField(
                        controller: _purchasePriceController,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Purchase Price (optional)',
                          hintText: '0.00',
                          prefixText: 'AED ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: InkWell(
                        onTap: _selectPurchaseDate,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Purchase Date (optional)',
                            contentPadding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            _purchaseDate != null
                                ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _purchaseDate != null
                                  ? theme.colorScheme.onSurface
                                  : Colors.grey[500],
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                    // Condition (status is always Assigned - new tools appear in My Tools)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Condition',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_condition),
                        value: _condition,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Condition',
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        items: _conditions.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Text(
                              condition,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _condition = value ?? _condition;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        dropdownColor: AppTheme.cardSurfaceColor(context),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: TextFormField(
                        controller: _locationController,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Van 2, Warehouse A',
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    Container(
                      decoration: _outlineDecoration(context, radius: 24),
                      child: TextFormField(
                        controller: _notesController,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add extra information about this tool',
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Tools you add here are also available to admins. Assign "Available" if the tool is ready for sharing, or keep "Assigned" if it is yours exclusively.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.4,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Tool Image',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardSurfaceColor(context),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 28),
            ),
            border: Border.all(
              color: AppTheme.subtleBorder,
              width: 1.2,
            ),
            boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 28),
                      ),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBackground, // ChatGPT-style: #F5F5F5
                          shape: BoxShape.circle,
                          boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurface.withOpacity(0.75),
                          ),
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
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showImagePickerOptions,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 28),
                    ),
                    splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 36),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Text(
                          'Add Tool Image',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Text(
                          'Tap to select from gallery or camera',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          ),
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
      CupertinoPageRoute(builder: (context) => const BarcodeScannerScreen()),
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
    setState(() {
      _modelController.text = ToolIdGenerator.generateModelNumber();
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
      _serialNumberController.text = ToolIdGenerator.generateToolId();
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
    final ids = ToolIdGenerator.generateBoth();
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
