import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'technician_home_screen.dart';
import 'role_selection_screen.dart';
import 'auth/login_screen.dart';
import 'pending_approval_screen.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? colorScheme.surface : Colors.white;
    final cardShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.1),
      blurRadius: 22,
      offset: const Offset(0, 10),
    );
    final hintStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Technician Sign Up',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 24,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Onboarding hint
                    Text(
                      'Create your technician account to access tool tracking, assignments, and maintenance workflows.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    // Profile Photo Section
                    Center(
                      child: _buildProfilePictureSection(cardColor, cardShadow, isDarkMode, colorScheme, context),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
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
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.person,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter full name',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.email,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter email address',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Phone Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
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
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.phone,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter phone number',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Department Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
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
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.apartment,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Enter department',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your department';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
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
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.lock,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Minimum 6 characters',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 20,
                            vertical: 16,
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

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                        ),
                        boxShadow: [cardShadow],
                        border: isDarkMode
                            ? Border.all(
                                color:
                                    colorScheme.onSurface.withValues(alpha: 0.12),
                              )
                            : null,
                      ),
                      child: TextFormField(
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
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'Re-enter password',
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 24),
                            ),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 2),
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
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

                    // Register Button
                    Container(
                      height: ResponsiveHelper.getResponsiveCardHeight(context, 56),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.9)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleRegister,
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 28),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    'Register as Technician',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
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
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
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

  Widget _buildProfilePictureSection(Color cardColor, BoxShadow cardShadow, bool isDarkMode, ColorScheme colorScheme, BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 24),
        ),
        boxShadow: [cardShadow],
        border: isDarkMode
            ? Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              )
            : null,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                ),
                child: CircleAvatar(
                  radius: ResponsiveHelper.getResponsiveIconSize(context, 50),
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.account_circle_rounded,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 60),
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _selectProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF22D3EE),
                          Color(0xFF0EA5E9),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          Wrap(
            spacing: ResponsiveHelper.getResponsiveSpacing(context, 10),
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
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  onTap: _removeProfileImage,
                  isDestructive: true,
                  colorScheme: colorScheme,
                  context: context,
                ),
            ],
          ),
        ],
      ),
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

      // Phone and department are required - validators ensure they're not empty
      await authProvider.registerTechnician(
        _nameController.text.trim(),
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
        // Wait for role to be set and ensure user is authenticated
        await Future.delayed(const Duration(milliseconds: 800));

        // Don't call initialize() as it resets state - just check current role

        // Wait a bit more for the role to be fully set
        await Future.delayed(const Duration(milliseconds: 300));

        debugPrint(
          '🔍 Technician registration complete - '
          'Role: ${authProvider.userRole.value}, '
          'isPendingApproval: ${authProvider.isPendingApproval}, '
          'isAuthenticated: ${authProvider.isAuthenticated}',
        );

        // Check if user is authenticated (has a session)
        if (authProvider.isAuthenticated) {
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
        } else {
          // No session (email confirmation required) - navigate to login
          AuthErrorHandler.showInfoSnackBar(
            context,
            '📧 Registration submitted! Please check your email to verify '
            'your account. After verification, your account will be pending '
            'admin approval.',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
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
}
