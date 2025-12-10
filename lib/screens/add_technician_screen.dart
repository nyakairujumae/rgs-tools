import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/supabase_technician_provider.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../config/app_config.dart';
import '../widgets/premium_field_styles.dart';

class AddTechnicianScreen extends StatefulWidget {
  final Technician? technician;

  const AddTechnicianScreen({super.key, this.technician});

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends State<AddTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  
  String _status = 'Active';
  DateTime? _hireDate;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
        _hireDate = DateTime.parse(widget.technician!.hireDate!);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final fieldIconColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.technician == null ? 'Add Technician' : 'Edit Technician',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktopLayout ? 760 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 16),
                    ),
                    Text(
                      widget.technician == null
                          ? 'Add technicians so they can receive assignments and tool access.'
                          : 'Update technician details to keep assignments current.',
                      style: TextStyle(
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 28),
                    ),
                    Center(
                      child: _buildProfilePictureSection(
                        colorScheme,
                        isDarkMode,
                        context,
                        iconColorOverride: fieldIconColor,
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 32),
                    ),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Full Name',
                      child: TextFormField(
                        controller: _nameController,
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            );
                          }),
                        ],
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Enter full name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter technician\'s name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Employee ID',
                      child: TextFormField(
                        controller: _employeeIdController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9-]'),
                          ),
                        ],
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Enter employee ID (optional)',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Phone Number',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Enter phone number',
                          prefixIcon: const Icon(Icons.phone_android),
                        ),
                      ),
                    ),
                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Email Address',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Enter email address',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!AppConfig.isValidEmailFormat(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Department',
                      child: TextFormField(
                        controller: _departmentController,
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Enter department',
                          prefixIcon: const Icon(Icons.apartment_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 16),
                    ),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Status',
                      child: Container(
                        decoration:
                            PremiumFieldStyles.dropdownContainerDecoration(
                                context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            style: PremiumFieldStyles.fieldTextStyle(context),
                            icon: PremiumFieldStyles.dropdownIcon(context),
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'Active',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text('Active'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Inactive',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text('Inactive'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _status = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),
                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Hire Date',
                      child: InkWell(
                        onTap: _selectHireDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration:
                              PremiumFieldStyles.dropdownContainerDecoration(
                                  context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: colorScheme.onSurface
                                    .withOpacity(0.55),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _hireDate != null
                                      ? '${_hireDate!.day.toString().padLeft(2, '0')}/${_hireDate!.month.toString().padLeft(2, '0')}/${_hireDate!.year}'
                                      : 'Select date',
                                  style: PremiumFieldStyles.fieldTextStyle(
                                          context)
                                      .copyWith(
                                    color: _hireDate != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface
                                            .withOpacity(0.45),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 32),
                    ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTechnician,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                  context, isDesktopLayout ? 32 : 28),
                            ),
                          ),
                          elevation: isDesktopLayout ? 6 : 2,
                          shadowColor: Colors.black.withOpacity(0.2),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                widget.technician == null
                                    ? 'Add Technician'
                                    : 'Update Technician',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveHelper.getResponsiveSpacing(context, 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
      String? profilePictureUrl;
      if (_profileImage != null) {
        // Upload image to Supabase storage
        profilePictureUrl = await _uploadProfileImage();
      }

      // Preserve existing profile picture when editing and no new picture selected
      if (profilePictureUrl == null && widget.technician?.profilePictureUrl != null) {
        profilePictureUrl = widget.technician!.profilePictureUrl;
      }

      final technician = Technician(
        id: widget.technician?.id,
        name: _nameController.text.trim().toUpperCase(),
        employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        hireDate: _hireDate?.toIso8601String().split('T')[0],
        status: _status,
        profilePictureUrl: profilePictureUrl,
      );

      final technicianProvider = context.read<SupabaseTechnicianProvider>();

      if (widget.technician == null) {
        await technicianProvider.addTechnician(technician);
      } else {
        await technicianProvider.updateTechnician(technician);
      }

      // Refresh list to ensure latest data (including profile urls)
      await technicianProvider.loadTechnicians();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.technician == null 
                  ? 'Technician added successfully!' 
                  : 'Technician updated successfully!'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops! Something went wrong. Please try again.'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
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

  Widget _buildProfilePictureSection(
    ColorScheme colorScheme,
    bool isDarkMode,
    BuildContext context, {
    Color? iconColorOverride,
  }) {
    final iconColor =
        iconColorOverride ?? colorScheme.onSurface.withValues(alpha: 0.55);
    final avatarRadius = ResponsiveHelper.getResponsiveIconSize(context, 58);
    final avatarBackground = isDarkMode
        ? colorScheme.onSurface.withValues(alpha: 0.35)
        : colorScheme.onSurface.withValues(alpha: 0.08);

    ImageProvider? avatarImage;
    if (_profileImage != null) {
      avatarImage = FileImage(_profileImage!);
    } else if (widget.technician?.profilePictureUrl != null &&
        widget.technician!.profilePictureUrl!.isNotEmpty) {
      avatarImage = NetworkImage(widget.technician!.profilePictureUrl!);
    }

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: avatarBackground,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Icon(
                      Icons.person_outline,
                      size: avatarRadius,
                      color: iconColor,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _selectProfileImage,
                child: Container(
                  width: ResponsiveHelper.getResponsiveIconSize(context, 32),
                  height: ResponsiveHelper.getResponsiveIconSize(context, 32),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: ResponsiveHelper.getResponsiveSpacing(context, 14),
          runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 10),
          alignment: WrapAlignment.center,
          children: [
            _buildProfileActionChip(
              icon: Icons.photo_library_outlined,
              label: 'Choose Photo',
              onTap: _selectProfileImage,
              colorScheme: colorScheme,
              context: context,
            ),
            _buildProfileActionChip(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: _takeProfileImage,
              colorScheme: colorScheme,
              context: context,
            ),
            if (_profileImage != null)
              _buildProfileActionChip(
                icon: Icons.close,
                label: 'Remove',
                onTap: _removeProfileImage,
                colorScheme: colorScheme,
                context: context,
                isDestructive: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required BuildContext context,
    bool isDestructive = false,
  }) {
    final Color bgColor = isDestructive
        ? Colors.red.withValues(alpha: 0.12)
        : AppTheme.primaryColor.withValues(alpha: 0.12);
    final Color fgColor =
        isDestructive ? Colors.red : AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
            ),
            border: Border.all(color: fgColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                color: fgColor,
              ),
              SizedBox(
                width: ResponsiveHelper.getResponsiveSpacing(context, 6),
              ),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _takeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  Future<String?> _uploadProfileImage() async {
    try {
      if (_profileImage == null) return null;

      // Generate unique filename
      final fileName = 'technician_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile-pictures/$fileName';

      // Upload to Supabase storage
      final response = await SupabaseService.client.storage
          .from('technician-images')
          .upload(filePath, _profileImage!);

      if (response.isNotEmpty) {
        // Get public URL
        final publicUrl = SupabaseService.client.storage
            .from('technician-images')
            .getPublicUrl(filePath);
        return publicUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }
}
