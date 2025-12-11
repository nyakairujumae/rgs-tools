import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../config/app_config.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import 'auth/login_screen.dart';

class TechnicianRegistrationScreen extends StatefulWidget {
  const TechnicianRegistrationScreen({super.key});

  @override
  State<TechnicianRegistrationScreen> createState() =>
      _TechnicianRegistrationScreenState();
}

class _TechnicianRegistrationScreenState
    extends State<TechnicianRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedDepartment;
  
  final List<String> _departments = [
    'Repairing',
    'Maintenance',
    'Retrofit',
    'Installation',
    'Factory',
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color desktopBackground = const Color(0xFF05070B);
    final Color desktopCardColor = const Color(0xFF090D14);

    return Scaffold(
      backgroundColor:
          isDesktopLayout ? desktopBackground : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: isDesktopLayout
            ? null
            : const Text(
                'Technician Registration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
        backgroundColor:
            isDesktopLayout ? Colors.transparent : Colors.white,
        foregroundColor: isDesktopLayout ? Colors.white : Colors.black87,
        elevation: isDesktopLayout ? 0 : 0,
        surfaceTintColor: Colors.transparent,
        leading: isDesktopLayout
            ? IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                splashRadius: 24,
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: context.cardDecoration,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Container(
          decoration: isDesktopLayout
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF05070B),
                      Color(0xFF0F1725),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : null,
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
                      'Register as a technician for RGS HVAC Services',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: isDesktopLayout
                            ? Colors.white.withOpacity(0.78)
                            : colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.spacingLarge * 1.5), // 24px
                    
                    // Card with form
                    Container(
                      padding: EdgeInsets.all(isDesktopLayout ? 32 : context.spacingLarge),
                      decoration: isDesktopLayout
                          ? BoxDecoration(
                              color: desktopCardColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 30,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            )
                          : context.cardDecoration, // ChatGPT-style card for mobile
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
                          return 'Please enter your full name';
                        }
                        return null;
                      },
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
                          return 'Please enter your email address';
                        }
                        if (!AppConfig.isValidEmailFormat(value)) {
                          return 'Please enter a valid email address (e.g., name@example.com)';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Phone Number Field
                    ThemedTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Department Field
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
                        value: _selectedDepartment,
                        decoration: context.chatGPTInputDecoration.copyWith(
                          labelText: 'Department',
                          hintText: 'Select department',
                          prefixIcon: Icon(
                            Icons.business_outlined,
                            size: 22,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 52),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        items: _departments.map((String department) {
                          return DropdownMenuItem<String>(
                            value: department,
                            child: Text(
                              department,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your department';
                          }
                          return null;
                        },
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
                      ),
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Password Field
                    ThemedTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      label: 'Password',
                      hint: 'Minimum 6 characters',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.spacingMedium), // 12px

                    // Confirm Password Field
                    ThemedTextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: context.spacingLarge + context.spacingSmall), // 20px

                    // Register Button
                    ThemedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      isLoading: _isLoading,
                      child: const Text(
                        'Register as Technician',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDesktopLayout
                                  ? Colors.white.withOpacity(0.75)
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: avatarBackground,
            backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
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
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: ListView(
                    controller: scrollController,
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.photo_library_outlined,
                            color: AppTheme.secondaryColor,
                            size: 22,
                          ),
                        ),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _selectProfileImage();
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: AppTheme.secondaryColor,
                            size: 22,
                          ),
                        ),
                        title: const Text('Take Photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _takeProfileImage();
                        },
                      ),
                      if (_profileImage != null)
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          title: const Text(
                            'Remove Photo',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _removeProfileImage();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      AuthErrorHandler.showErrorSnackBar(context, 'Error selecting image: $e');
    }
  }

  Future<void> _takeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      AuthErrorHandler.showErrorSnackBar(context, 'Error taking photo: $e');
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      debugPrint('🔍 Starting technician registration...');
      // Phone and department are required - validators ensure they're not empty
      await authProvider.registerTechnician(
        _nameController.text.trim().toUpperCase(),
        _emailController.text.trim(),
        _passwordController.text,
        _employeeIdController.text.trim().isEmpty
            ? null
            : _employeeIdController.text.trim(),
        _phoneController.text.trim(), // Required - validator ensures not empty
        _selectedDepartment ?? '', // Required - validator ensures not empty
        null, // hireDate - will be set by admin
        _profileImage,
      );

      if (mounted) {
        // Check if user was created (even if no session due to email confirmation)
        final userCreated = authProvider.user != null;
        final hasSession = authProvider.isAuthenticated;

        debugPrint(
          '🔍 Technician registration complete - '
          'User created: $userCreated, '
          'hasSession: $hasSession, '
          'Role: ${authProvider.userRole.value}, '
          'isPendingApproval: ${authProvider.isPendingApproval}',
        );

        // Check if user is authenticated (has a session)
        if (hasSession && userCreated) {
          // Show email confirmation dialog for all new technicians (even if email confirmation is disabled)
          // This ensures users know to check their email if it gets enabled later
          await _showEmailConfirmationDialog(context);
          
          // User has a session - navigate to pending approval screen
          AuthErrorHandler.showInfoSnackBar(
            context,
            '📋 Your account is pending admin approval. '
            'You will be notified once approved.',
          );

          debugPrint('🔍 Navigating to pending approval screen');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pending-approval',
            (route) => false,
          );
        } else if (userCreated) {
          // User created but no session (email confirmation required) - this is expected
          // Show email confirmation dialog
          await _showEmailConfirmationDialog(context);
          
          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        } else {
          // User was not created - this is an actual error
          throw Exception('Registration failed - user was not created');
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Technician registration error: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
        debugPrint('❌ Error string: ${e.toString()}');
        
        String errorMessage = AuthErrorHandler.getErrorMessage(e);
        
        // Provide more specific error messages
        if (e.toString().contains('connection') || e.toString().contains('network') || e.toString().contains('timeout')) {
          errorMessage = 'Connection error: Please check your internet connection and try again.';
        } else if (e.toString().contains('email already registered') || e.toString().contains('already exists')) {
          errorMessage = 'This email is already registered. Please use a different email or try logging in.';
        } else if (e.toString().contains('invalid email')) {
          errorMessage = 'Invalid email address. Please check and try again.';
        } else if (e.toString().contains('weak password') || e.toString().contains('password')) {
          errorMessage = 'Password is too weak. Please use a stronger password.';
        }
        
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEmailConfirmationDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissing by back button
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: AppTheme.secondaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check Your Email',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'ve sent a confirmation email to:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.04),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _emailController.text.trim(),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your email and click the confirmation link to verify your account. After verification, your account will be pending admin approval.',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can proceed to the waiting screen. We\'ll check your email confirmation status automatically.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
