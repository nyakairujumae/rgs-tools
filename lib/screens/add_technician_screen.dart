import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../config/app_config.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';

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
        backgroundColor: context.appBarBackground,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 28,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      body: SafeArea(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktopLayout ? 48 : 20,
              vertical: isDesktopLayout ? 10 : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktopLayout ? 640 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle above card
                    Text(
                      widget.technician == null
                          ? 'Add technicians so they can receive assignments and tool access.'
                          : 'Update technician details to keep assignments current.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.spacingLarge * 1.5), // 24px
                    
                    // Card with form
                    Container(
                      padding: EdgeInsets.all(isDesktopLayout ? 32 : context.spacingLarge),
                      decoration: context.cardDecoration, // ChatGPT-style card
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    // Profile Photo Section
                    Center(
                      child: _buildProfilePictureSection(
                        colorScheme,
                        isDarkMode,
                        context,
                        iconColorOverride: fieldIconColor,
                      ),
                    ),

                    SizedBox(height: context.spacingLarge * 1.5), // 24px
                    // Name Field
                    ThemedTextField(
                      controller: _nameController,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      label: 'Full Name',
                      hint: 'Enter full name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter technician\'s name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Employee ID Field
                    ThemedTextField(
                      controller: _employeeIdController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9-]'),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      label: 'Employee ID',
                      hint: 'Enter employee ID (optional)',
                      prefixIcon: Icons.badge_outlined,
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Phone Number Field
                    ThemedTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Email Field
                    ThemedTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: 'Email Address',
                      hint: 'Enter email address',
                      prefixIcon: Icons.email_outlined,
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

                    SizedBox(height: context.spacingMedium), // 12px

                    // Department Field
                    DropdownButtonFormField<String>(
                      value: _departmentController.text.isEmpty ? null : _departmentController.text,
                      isExpanded: true,
                      decoration: context.chatGPTInputDecoration.copyWith(
                        labelText: 'Department',
                        hintText: 'Select department',
                        prefixIcon: Icon(
                          Icons.business_outlined,
                          size: 22,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 52),
                      ),
                      items: [
                        'Repairing',
                        'Maintenance',
                        'Retrofit',
                        'Installation',
                        'Factory',
                      ].map((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              department,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          'Repairing',
                          'Maintenance',
                          'Retrofit',
                          'Installation',
                          'Factory',
                        ].map<Widget>((String department) {
                          return Text(
                            department,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        }).toList();
                      },
                      onChanged: (String? value) {
                        setState(() {
                          _departmentController.text = value ?? '';
                        });
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

                    SizedBox(height: context.spacingMedium), // 12px

                    // Status Field
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                          width: 0.5,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: context.chatGPTInputDecoration.copyWith(
                          labelText: 'Status',
                          hintText: 'Select status',
                          prefixIcon: Icon(
                            Icons.info_outline,
                            size: 22,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 52),
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'Active',
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Inactive',
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() {
                            _status = value;
                          });
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
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Hire Date Field
                    InkWell(
                      onTap: _selectHireDate,
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
                                _hireDate != null
                                    ? '${_hireDate!.day.toString().padLeft(2, '0')}/${_hireDate!.month.toString().padLeft(2, '0')}/${_hireDate!.year}'
                                    : 'Select hire date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _hireDate != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface.withOpacity(0.45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: context.spacingLarge + context.spacingSmall), // 20px

                    // Save Button
                    ThemedButton(
                      onPressed: _isLoading ? null : _saveTechnician,
                      isLoading: _isLoading,
                      child: Text(
                        widget.technician == null
                            ? 'Add Technician'
                            : 'Update Technician',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                        ),
                      ),
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
      if (profilePictureUrl == null && widget.technician?.profilePictureUrl != null && _profileImage == null) {
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
      final authProvider = context.read<AuthProvider>();

      if (widget.technician == null) {
        // For new technicians, create auth account first (if email provided)
        String? userId;
        if (technician.email != null && technician.email!.isNotEmpty) {
          try {
            debugPrint('🔍 Creating auth account for admin-added technician: ${technician.email}');
            userId = await authProvider.createTechnicianAuthAccount(
              email: technician.email!,
              name: technician.name,
              department: technician.department,
            );
            debugPrint('✅ Auth account created with user_id: $userId');
          } catch (e) {
            debugPrint('⚠️ Error creating auth account: $e');
            final errorMessage = e.toString();
            // If email already exists, try to get existing user_id
            if (errorMessage.contains('already registered')) {
              // Try to find existing user
              try {
                final userRecord = await SupabaseService.client
                    .from('users')
                    .select('id')
                    .eq('email', technician.email!)
                    .maybeSingle();
                if (userRecord != null) {
                  userId = userRecord['id'] as String;
                  debugPrint('✅ Found existing user_id: $userId');
                }
              } catch (findError) {
                debugPrint('⚠️ Could not find existing user: $findError');
              }
            } else {
              // Re-throw if it's a different error
              rethrow;
            }
          }
        }
        
        // Add technician record (with user_id if available)
        await technicianProvider.addTechnician(technician, userId: userId);
        
        // Show success message with email info
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician added successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (technician.email != null && technician.email!.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Invite email sent to ${technician.email}\nTechnician should use the invite email to set their password.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Updating existing technician - no auth account creation needed
        await technicianProvider.updateTechnician(technician);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Technician updated successfully!'),
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
      }

      // Refresh list to ensure latest data (including profile urls)
      await technicianProvider.loadTechnicians();
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
            // Plus button overlay
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectProfileImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takeProfileImage();
              },
            ),
            if (_profileImage != null || (widget.technician?.profilePictureUrl != null && widget.technician!.profilePictureUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
          ],
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
      // If editing, we'll need to clear the profilePictureUrl when saving
      // This is handled in _saveTechnician by not preserving the existing URL
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
