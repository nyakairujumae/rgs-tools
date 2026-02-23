import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import '../utils/responsive_helper.dart';
import '../services/admin_position_service.dart';
import 'admin_home_screen.dart';
import 'role_selection_screen.dart';
import 'auth/login_screen.dart';
import '../utils/logger.dart';

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
  String? _superAdminPositionId;
  bool _isLoadingPosition = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadSuperAdminPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBootstrapAccess();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSuperAdminPosition() async {
    setState(() {
      _isLoadingPosition = true;
    });

    try {
      final superAdmin = await AdminPositionService.getPositionByName('Super Admin');
      final fallbackAdmin = superAdmin ?? await AdminPositionService.getPositionByName('CEO');
      setState(() {
        _superAdminPositionId = fallbackAdmin?.id;
      });
      if (_superAdminPositionId == null) {
        Logger.debug('❌ Super Admin position not found');
      }
    } catch (e) {
      Logger.debug('❌ Error loading Super Admin position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading Super Admin position: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPosition = false;
      });
    }
  }

  Future<void> _checkBootstrapAccess() async {
    final authProvider = context.read<AuthProvider>();
    final allowed = await authProvider.canBootstrapAdmin();
    if (!mounted) return;
    if (!allowed) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'Admin registration is closed. Please request an admin invite.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/role-selection',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Pure white
      appBar: AppBar(
        title: const Text(
          'Admin Registration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktopLayout ? 48 : context.spacingLarge,
            vertical: context.spacingLarge,
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
                    'Register as an administrator for RGS HVAC Services',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.secondaryTextColor,
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
                          // Name Field
                      ThemedTextField(
                        controller: _nameController,
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
                        hint: 'Enter company email',
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!AppConfig.isAdminEmailDomain(value)) {
                            return 'Invalid email domain for admin registration. Use ${AppConfig.adminDomainsDisplay}';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.spacingMedium), // 12px

                      if (_isLoadingPosition) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.secondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading admin role...',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.spacingMedium),
                      ] else if (_superAdminPositionId == null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Super Admin position not configured. Please run the admin positions migration.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.spacingMedium),
                      ],

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
                              _obscureConfirmPassword = !_obscureConfirmPassword;
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
                          'Register as Admin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.secondaryTextColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                        ],
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
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      if (_superAdminPositionId == null) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Super Admin position is not configured yet.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Logger.debug('🔍 Starting admin registration...');
      final response = await authProvider.registerAdmin(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _superAdminPositionId!,
      );

      Logger.debug('✅ Admin registration method completed successfully');

      if (mounted) {
        // Check if user was actually created
        final userCreated = response.user != null;
        final hasSession = response.session != null;
        
        Logger.debug('🔍 Registration check - User created: $userCreated, hasSession: $hasSession');
        Logger.debug('🔍 Email confirmed: ${response.user?.emailConfirmedAt != null}');
        
        if (!userCreated) {
          throw Exception('Registration failed: User was not created. Please try again.');
        }
        
        if (hasSession) {
          // Email was auto-confirmed or confirmation is disabled
          Logger.debug('✅ Admin has session, navigating to home screen');
          AuthErrorHandler.showSuccessSnackBar(
            context,
            '🎉 Admin account created successfully! Welcome to RGS HVAC Services.',
          );

          // Navigate to admin home screen
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(
              builder: (context) => const AdminHomeScreen(),
            ),
            (route) => false,
          );
        } else {
          // Email confirmation required for admin
          Logger.debug('⚠️ No session - email confirmation required');
          
          // Show email confirmation dialog
          await _showEmailConfirmationDialog();

          // Navigate back to login screen
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Logger.debug('❌ Admin registration error: $e');
        Logger.debug('❌ Error type: ${e.runtimeType}');
        Logger.debug('❌ Error string: ${e.toString()}');
        
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

  Future<void> _showEmailConfirmationDialog() async {
    final theme = Theme.of(context);
    
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
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                      fontSize: 20,
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
                    fontSize: 14,
                    color: context.secondaryTextColor,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your email and click the confirmation link to verify your admin account. '
                  'You must confirm your email before you can log in.',
                  style: TextStyle(
                    fontSize: 14,
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
                          'After confirming your email, you can log in with your admin credentials.',
                          style: TextStyle(
                            fontSize: 12,
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
              ThemedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
