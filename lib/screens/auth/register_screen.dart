import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/responsive_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.technician;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      if (_selectedRole == UserRole.technician) {
        await _registerTechnician(authProvider);
      } else {
        await _registerAdmin(authProvider);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = AuthErrorHandler.getErrorMessage(e);
      AuthErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }

  Future<void> _registerTechnician(AuthProvider authProvider) async {
    await authProvider.registerTechnician(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      null,
      _phoneController.text.trim(),
      _departmentController.text.trim(),
      null,
      null,
    );

    if (!mounted) return;
    if (authProvider.user == null) {
      throw Exception('Registration failed');
    }

    await Future.delayed(const Duration(milliseconds: 800));
    debugPrint(
      '🔍 Technician registration complete - Role: ${authProvider.userRole.value}, '
      'isPendingApproval: ${authProvider.isPendingApproval}',
    );
    
    // Show email confirmation dialog for all new technicians
    await _showEmailConfirmationDialog();
    
    _showPendingApprovalMessage();
  }

  Future<void> _registerAdmin(AuthProvider authProvider) async {
    final response = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted || response.user == null) {
      throw Exception('Registration failed');
    }

    final hasSession =
        response.session != null || response.user?.emailConfirmedAt != null;
    if (!hasSession) {
      AuthErrorHandler.showInfoSnackBar(
        context,
        '📧 Account created! Please verify your email. After confirmation, your account will await admin approval.',
      );
      Navigator.of(context).pop();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    debugPrint(
      '🔍 Registration complete - Role: ${authProvider.userRole.value}, '
      'isPendingApproval: ${authProvider.isPendingApproval}',
    );

    if (authProvider.isAdmin) {
      AuthErrorHandler.showSuccessSnackBar(
        context,
        '🎉 Account created successfully! Welcome to RGS HVAC Services.',
      );
      Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
      return;
    }

    final isApproved = await authProvider.checkApprovalStatus();
    debugPrint(
      '🔍 Approval status check: isApproved=$isApproved, '
      'isPendingApproval=${authProvider.isPendingApproval}, '
      'userRole=${authProvider.userRole.value}',
    );

    final shouldShowPending = _selectedRole == UserRole.technician ||
        authProvider.isPendingApproval ||
        authProvider.userRole == UserRole.pending ||
        isApproved == null ||
        isApproved == false;

    if (shouldShowPending) {
      _showPendingApprovalMessage();
    } else {
      AuthErrorHandler.showSuccessSnackBar(
        context,
        '🎉 Account created successfully! Welcome to RGS HVAC Services.',
      );
      Navigator.pushNamedAndRemoveUntil(context, '/technician', (route) => false);
    }
  }

  Future<void> _showEmailConfirmationDialog() async {
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

  void _showPendingApprovalMessage() {
    if (!mounted) return;
    AuthErrorHandler.showInfoSnackBar(
      context,
      '📋 Your account is pending admin approval. You will be notified once approved.',
    );
    Navigator.pushNamedAndRemoveUntil(context, '/pending-approval', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final maxWidth = isDesktop ? 720.0 : double.infinity;
    final cardColor = isDarkMode ? colorScheme.surface : Colors.white;
    final cardShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.1),
      blurRadius: 24,
      offset: const Offset(0, 20),
    );
    final isTechnician = _selectedRole == UserRole.technician;

    TextStyle buildFieldTextStyle(double fontSize) => TextStyle(
          color: colorScheme.onSurface,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, fontSize),
        );

    InputDecoration buildDecoration({
      required String label,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      final borderRadius = BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 20),
      );

      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: AppTheme.secondaryColor,
            width: 2,
          ),
        ),
        contentPadding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 20,
          vertical: 16,
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: isDesktop ? 64 : 24,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  boxShadow: isDesktop ? [cardShadow] : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 40 : 24),
                  child: Column(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'RGS',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 48),
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            'HVAC SERVICES',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          Text(
                            'Create your account to get started.',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      style: buildFieldTextStyle(16),
                      decoration: buildDecoration(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: buildFieldTextStyle(16),
                      decoration: buildDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Use AppConfig for consistent email validation
                        if (!AppConfig.isValidEmailFormat(value)) {
                          return 'Please enter a valid email address (e.g., name@example.com)';
                        }
                        if (!AppConfig.isEmailDomainAllowed(value)) {
                          return 'Email domain not allowed. Use @mekar.ae or other approved domains';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: buildFieldTextStyle(16),
                      decoration: buildDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: buildFieldTextStyle(16),
                      decoration: buildDecoration(
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Phone Number Field (Required for technicians)
                    if (isTechnician)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: buildFieldTextStyle(16),
                        decoration: buildDecoration(
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (!isTechnician) return null;
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    
                    if (isTechnician)
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Department Field (Required for technicians)
                    if (isTechnician)
                      TextFormField(
                        controller: _departmentController,
                        style: buildFieldTextStyle(16),
                        decoration: buildDecoration(
                          label: 'Department',
                          icon: Icons.business_outlined,
                        ),
                        validator: (value) {
                          if (!isTechnician) return null;
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Please enter your department';
                          }
                          return null;
                        },
                      ),
                    
                    if (isTechnician)
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Role Selection Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                        ),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        style: buildFieldTextStyle(16),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        dropdownColor: isDarkMode ? colorScheme.surface : Colors.white,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  role == UserRole.admin ? Icons.admin_panel_settings : Icons.person,
                                  color: role == UserRole.admin ? Colors.blue : Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  role.displayName,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (UserRole? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Register Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: ResponsiveHelper.getResponsiveListItemHeight(context, 56),
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                              ),
                              elevation: 0,
                              padding: ResponsiveHelper.getResponsiveButtonPadding(context),
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                    width: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Sign In Link
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Back to Role Selection
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        '← Back to Role Selection',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ), // Form
            ],
          ),
        ), // Padding
      ), // DecoratedBox
    ), // ConstrainedBox
        ),
      ),
    ),
  );
}

}
