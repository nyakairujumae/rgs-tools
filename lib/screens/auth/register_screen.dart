import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../config/app_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 24,
            vertical: 40,
          ),
          child: Column(
            children: [
              // Branding Section
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
              
              // Registration Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.secondaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 20,
                          vertical: 16,
                        ),
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
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.secondaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 20,
                          vertical: 16,
                        ),
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
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.secondaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 20,
                          vertical: 16,
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
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: AppTheme.secondaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 20,
                          vertical: 16,
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
                    if (_selectedRole == UserRole.technician)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (_selectedRole == UserRole.technician) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                          }
                          return null;
                        },
                      ),
                    
                    if (_selectedRole == UserRole.technician)
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Department Field (Required for technicians)
                    if (_selectedRole == UserRole.technician)
                      TextFormField(
                        controller: _departmentController,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Department',
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                          prefixIcon: Icon(
                            Icons.business_outlined,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                            ),
                            borderSide: BorderSide(
                              color: AppTheme.secondaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (_selectedRole == UserRole.technician) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your department';
                            }
                          }
                          return null;
                        },
                      ),
                    
                    if (_selectedRole == UserRole.technician)
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
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
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
                      onPressed: () => Navigator.pop(context),
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
                        Navigator.pop(context);
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    try {
      // For technicians, use registerTechnician to include phone and department
      if (_selectedRole == UserRole.technician) {
        await authProvider.registerTechnician(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          null, // employeeId
          _phoneController.text.trim(),
          _departmentController.text.trim(),
          null, // hireDate
          null, // profileImage
        );
        
        // Get the response from the auth provider
        final response = authProvider.user != null 
          ? AuthResponse(
              user: authProvider.user,
              session: SupabaseService.client.auth.currentSession,
            )
          : throw Exception('Registration failed');
        
        if (mounted && response.user != null) {
          // Wait a moment for pending approval to be created in database
          await Future.delayed(Duration(milliseconds: 800));
          
          debugPrint('🔍 Technician registration complete - Role: ${authProvider.userRole.value}, isPendingApproval: ${authProvider.isPendingApproval}');
          
          // Technicians always go to pending approval screen
          AuthErrorHandler.showInfoSnackBar(
            context, 
            '📋 Your account is pending admin approval. You will be notified once approved.'
          );
          Navigator.pushNamedAndRemoveUntil(context, '/pending-approval', (route) => false);
        }
        return;
      }
      
      // For admins, use regular signUp
      final response = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );
      
      if (mounted && response.user != null) {
        // User was created - check if we have a session (email confirmation might be disabled)
        // If no session, user needs to confirm email first
        final hasSession = response.session != null || response.user?.emailConfirmedAt != null;
        
        if (hasSession) {
          // Wait a moment for pending approval to be created in database
          await Future.delayed(Duration(milliseconds: 800));
          
          // For technicians, ensure role is set to pending (signUp should have done this)
          if (_selectedRole == UserRole.technician && !authProvider.isPendingApproval) {
            // Force set to pending if not already set
            debugPrint('⚠️ Role not set to pending, forcing it...');
            // The role should already be set by signUp, but just in case
          }
          
          // Refresh the role from the provider (signUp already set it to pending for technicians)
          // Don't call initialize() as it resets state - just check the current role
          debugPrint('🔍 Registration complete - Role: ${authProvider.userRole.value}, isPendingApproval: ${authProvider.isPendingApproval}');
          debugPrint('🔍 Selected role during registration: ${_selectedRole.value}');
          
          // Navigate based on role and approval status
          if (authProvider.isAdmin) {
            AuthErrorHandler.showSuccessSnackBar(
              context, 
              '🎉 Account created successfully! Welcome to RGS HVAC Services.'
            );
            Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
          } else {
            // For technicians, check if they have pending approval
            // signUp() should have already set role to pending and created pending approval record
            final isApproved = await authProvider.checkApprovalStatus();
            
            debugPrint('🔍 Approval status check: isApproved=$isApproved, isPendingApproval=${authProvider.isPendingApproval}, userRole=${authProvider.userRole.value}');
            
            // If pending approval role is set OR not approved, show pending screen
            // Default to pending screen for technicians unless explicitly approved
            if (_selectedRole == UserRole.technician || 
                authProvider.isPendingApproval || 
                authProvider.userRole == UserRole.pending ||
                isApproved == false || 
                isApproved == null) {
              // Technician with pending approval - always show pending screen
              debugPrint('🔍 Navigating to pending approval screen');
              AuthErrorHandler.showInfoSnackBar(
                context, 
                '📋 Your account is pending admin approval. You will be notified once approved.'
              );
              Navigator.pushNamedAndRemoveUntil(context, '/pending-approval', (route) => false);
            } else {
              // Approved (shouldn't happen for new registrations)
              debugPrint('🔍 Technician already approved, navigating to home');
              AuthErrorHandler.showSuccessSnackBar(
                context, 
                '🎉 Account created successfully! Welcome to RGS HVAC Services.'
              );
              Navigator.pushNamedAndRemoveUntil(context, '/technician', (route) => false);
            }
          }
        } else {
          // Email confirmation required - but we still created the pending approval
          // User needs to confirm email first, then they'll see pending approval on login
          AuthErrorHandler.showInfoSnackBar(
            context, 
            '📧 Account created! Please check your email to verify your account. After verification, your account will be pending admin approval.'
          );
          
          // Go back to login screen
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }
}
