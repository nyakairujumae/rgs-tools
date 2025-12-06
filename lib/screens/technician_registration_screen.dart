import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../config/app_config.dart';
import '../widgets/premium_field_styles.dart';
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
  final _departmentController = TextEditingController();

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
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color fieldIconColor =
        colorScheme.onSurface.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Technician Sign Up',
          style: TextStyle(fontWeight: FontWeight.w600),
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
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 24)),
                        Text(
                          'Create your technician account to access tool tracking, assignments, and maintenance workflows.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context, 16),
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.75),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 28)),
                    // Profile Photo Section
                    Center(
                      child: _buildProfilePictureSection(
                        colorScheme,
                        isDarkMode,
                        context,
                        iconColorOverride: fieldIconColor,
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

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
                            return 'Please enter your full name';
                          }
                          return null;
                        },
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
                            return 'Please enter your email address';
                          }
                          if (!AppConfig.isValidEmailFormat(value)) {
                            return 'Please enter a valid email address (e.g., name@example.com)';
                          }
                          return null;
                        },
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
                          prefixIcon: const Icon(Icons.phone_iphone),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your department';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),

                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Password',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
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
                    ),

                    const SizedBox(height: PremiumFieldStyles.fieldSpacing),

                    PremiumFieldStyles.labeledField(
                      context: context,
                      label: 'Confirm Password',
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: PremiumFieldStyles.fieldTextStyle(context),
                        decoration: PremiumFieldStyles.inputDecoration(
                          context,
                          hintText: 'Re-enter password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
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
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

                    // Register Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600] ?? Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                  context, isDesktopLayout ? 32 : 28),
                            ),
                          ),
                          elevation: isDesktopLayout ? 6 : 2,
                          shadowColor: Colors.black.withOpacity(0.25),
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Register as Technician',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

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
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          vertical: 8,
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize:
                                  ResponsiveHelper.getResponsiveFontSize(context, 15),
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
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

    return Column(
      children: [
        Center(
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
            ],
          ),
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
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
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
        _departmentController.text.trim(), // Required - validator ensures not empty
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
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
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
                    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
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
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      width: 1,
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
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'I\'ll check later',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it, continue',
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
