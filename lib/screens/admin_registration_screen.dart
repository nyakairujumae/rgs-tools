import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'admin_home_screen.dart';
import 'role_selection_screen.dart';
import 'auth/login_screen.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() =>
      _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _positionController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    final Color desktopBackground = const Color(0xFF05070B);
    final Color desktopCardColor = const Color(0xFF090D14);
    final Color fieldIconColor = isDesktopLayout
        ? Colors.white.withOpacity(0.75)
        : colorScheme.onSurface.withValues(alpha: 0.7);
    final hintStyle = TextStyle(
      color: isDesktopLayout
          ? Colors.white.withOpacity(0.55)
          : colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
      fontWeight: FontWeight.w400,
    );
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.2);

    OutlineInputBorder buildBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1),
      );
    }

    InputDecoration buildInputDecoration({
      required String label,
      required String hint,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: fieldIconColor,
          size: 22,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: hintStyle,
        filled: true,
        fillColor: isDarkMode
            ? colorScheme.surface.withOpacity(isDesktopLayout ? 0.4 : 0.6)
            : Colors.white,
        border: buildBorder(borderColor),
        enabledBorder: buildBorder(borderColor),
        focusedBorder: buildBorder(AppTheme.primaryColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDesktopLayout ? desktopBackground : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: isDesktopLayout
            ? null
            : const Text(
                'Admin Registration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
        backgroundColor:
            isDesktopLayout ? Colors.transparent : colorScheme.surface,
        foregroundColor: isDesktopLayout ? Colors.white : colorScheme.onSurface,
        elevation: isDesktopLayout ? 0 : 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDesktopLayout ? Colors.white : colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
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
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktopLayout ? 32 : 0,
                    vertical: isDesktopLayout ? 24 : 0,
                  ),
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
                      : null,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isDesktopLayout) ...[
                          Text(
                            'Admin Registration',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context, 28),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                              height: ResponsiveHelper.getResponsiveSpacing(
                                  context, 24)),
                        ],
                    // Onboarding hint
                    Text(
                      'Register as an administrator for RGS HVAC Services',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: isDesktopLayout
                            ? Colors.white.withOpacity(0.78)
                            : colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: buildInputDecoration(
                        label: 'Full Name',
                        hint: 'Enter full name',
                        icon: Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: buildInputDecoration(
                        label: 'Email Address',
                        hint: 'Enter company email',
                        icon: Icons.email,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!value.contains('@royalgulf.ae') &&
                            !value.contains('@mekar.ae')) {
                          return 'Invalid email domain for admin registration';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Position Field
                    TextFormField(
                      controller: _positionController,
                      decoration: buildInputDecoration(
                        label: 'Position/Title',
                        hint: 'e.g., Operations Manager, Director',
                        icon: Icons.work,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your position';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: buildInputDecoration(
                        label: 'Password',
                        hint: 'Minimum 6 characters',
                        icon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: fieldIconColor,
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

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: buildInputDecoration(
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: fieldIconColor,
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

                    const SizedBox(height: 20),

                    // Register Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600] ?? Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isDesktopLayout ? 32 : 28),
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
                                'Register as Admin',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      debugPrint('🔍 Starting admin registration...');
      await authProvider.registerAdmin(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _positionController.text.trim(),
      );

      debugPrint('✅ Admin registration method completed successfully');

      if (mounted) {
        // Check if user was actually created
        final userCreated = authProvider.user != null;
        final hasSession = authProvider.isAuthenticated;
        
        debugPrint('🔍 Registration check - User created: $userCreated, hasSession: $hasSession');
        
        if (!userCreated) {
          throw Exception('Registration failed: User was not created. Please try again.');
        }
        
        if (hasSession) {
          // Email was auto-confirmed or confirmation is disabled
          debugPrint('✅ Admin has session, navigating to home screen');
          AuthErrorHandler.showSuccessSnackBar(
            context,
            '🎉 Admin account created successfully! Welcome to RGS HVAC Services.',
          );

          // Navigate to admin home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminHomeScreen(),
            ),
            (route) => false,
          );
        } else {
          // Email confirmation required for admin
          debugPrint('⚠️ No session - email confirmation required');
          AuthErrorHandler.showInfoSnackBar(
            context,
            '📧 Admin account created! Please check your email to verify your account. '
            'You must confirm your email before you can log in.',
          );

          // Navigate back to login screen
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
        debugPrint('❌ Admin registration error: $e');
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
}
