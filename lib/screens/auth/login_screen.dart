import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../config/app_config.dart';
import '../../utils/responsive_helper.dart';
import '../../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildSocialButtons({
    required BuildContext context,
    required bool isDesktopLayout,
  }) {
    final theme = Theme.of(context);
    final isIOS = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.isLoading;

        Widget buildButton({
          required VoidCallback onPressed,
          required Widget icon,
          required String label,
        }) {
          return SizedBox(
            height: ResponsiveHelper.getResponsiveListItemHeight(context, 48),
            child: OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(
                  color: isDesktopLayout
                      ? Colors.white.withOpacity(0.4)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(
                      context,
                      isDesktopLayout ? 24 : 18,
                    ),
                  ),
                ),
                backgroundColor: isDesktopLayout
                    ? Colors.white.withOpacity(0.04)
                    : theme.colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final buttons = <Widget>[
          buildButton(
            onPressed: () async {
              try {
                await authProvider.signInWithGoogle();
              } catch (e) {
                if (context.mounted) {
                  final errorMessage = AuthErrorHandler.getErrorMessage(e);
                  AuthErrorHandler.showErrorSnackBar(context, errorMessage);
                }
              }
            },
            icon: Image.asset(
              'assets/images/google_logo.png',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata_rounded,
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                color: theme.colorScheme.primary,
              ),
            ),
            label: 'Sign in with Google',
          ),
        ];

        if (isIOS) {
          buttons.add(
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context, 12),
            ),
          );
          buttons.add(
            buildButton(
              onPressed: () async {
                try {
                  await authProvider.signInWithApple();
                } catch (e) {
                  if (context.mounted) {
                    final errorMessage = AuthErrorHandler.getErrorMessage(e);
                    AuthErrorHandler.showErrorSnackBar(context, errorMessage);
                  }
                }
              },
              icon: Image.asset(
                'assets/images/apple_logo.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.apple,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 22),
                  color: isDesktopLayout ? Colors.white : Colors.black,
                ),
              ),
              label: 'Sign in with Apple',
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    final Color textPrimary =
        isDesktopLayout ? Colors.white : colorScheme.onSurface;
    final Color textSecondary = isDesktopLayout
        ? Colors.white.withOpacity(0.7)
        : colorScheme.onSurface.withValues(alpha: 0.7);
    final Color hintTextColor = isDesktopLayout
        ? Colors.white.withOpacity(0.6)
        : colorScheme.onSurface.withValues(alpha: 0.6);
    final Color fieldIconColor = isDesktopLayout
        ? Colors.white.withOpacity(0.7)
        : colorScheme.onSurface.withValues(alpha: 0.6);
    final Color inputFillColor = isDesktopLayout
        ? Colors.white.withOpacity(0.04)
        : (isDarkMode ? colorScheme.surface : Colors.white);
    final Color inputBorderColor = isDesktopLayout
        ? Colors.white.withOpacity(0.2)
        : colorScheme.onSurface.withValues(alpha: 0.3);
    final double borderRadiusValue = ResponsiveHelper.getResponsiveBorderRadius(
      context,
      isDesktopLayout ? 28 : 20,
    );

    OutlineInputBorder buildBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    InputDecoration buildInputDecoration({
      required String label,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: hintTextColor,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: fieldIconColor,
          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputFillColor,
        border: buildBorder(inputBorderColor, isDesktopLayout ? 1.4 : 1),
        enabledBorder: buildBorder(inputBorderColor, isDesktopLayout ? 1.4 : 1),
        focusedBorder: buildBorder(AppTheme.secondaryColor, 2),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isDesktopLayout ? 22 : 16,
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: isDesktopLayout ? 56 : 24,
            vertical: 40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktopLayout ? 520 : double.infinity,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktopLayout ? 32 : 0,
                  vertical: isDesktopLayout ? 32 : 0,
                ),
                decoration: isDesktopLayout
                    ? BoxDecoration(
                        color: const Color(0xFF0B111C).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 30,
                            offset: Offset(0, 20),
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      'assets/images/rgs.jpg',
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 34),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context, 16),
                            ),
                            decoration: buildInputDecoration(
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              if (!AppConfig.isEmailDomainAllowed(value)) {
                                return 'Email domain not allowed. Use @mekar.ae or other approved domains';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 16),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context, 16),
                            ),
                            decoration: buildInputDecoration(
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: fieldIconColor,
                                  size: ResponsiveHelper.getResponsiveIconSize(
                                      context, 20),
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
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 20),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: ResponsiveHelper
                                    .getResponsiveListItemHeight(context, 56),
                                child: ElevatedButton(
                                  onPressed:
                                      authProvider.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          borderRadiusValue),
                                    ),
                                    elevation: isDesktopLayout ? 8 : 0,
                                    padding: ResponsiveHelper
                                        .getResponsiveButtonPadding(context),
                                  ),
                                  child: authProvider.isLoading
                                      ? SizedBox(
                                          height: ResponsiveHelper
                                              .getResponsiveIconSize(context, 20),
                                          width: ResponsiveHelper
                                              .getResponsiveIconSize(context, 20),
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper
                                                .getResponsiveFontSize(context, 16),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 20),
                          ),
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDesktopLayout
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.grey[300],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Or continue with',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                            context, 13),
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDesktopLayout
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 16),
                          ),
                          // Social Sign-in Buttons
                          _buildSocialButtons(
                            context: context,
                            isDesktopLayout: isDesktopLayout,
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 20),
                          ),
                          TextButton(
                            onPressed: _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: ResponsiveHelper.getResponsivePadding(
                                context,
                                vertical: 8,
                              ),
                            ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color:
                                          const Color(0xFF2E7D32),
                                      fontSize:
                                          ResponsiveHelper.getResponsiveFontSize(
                                              context, 14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(
                                context, 12),
                          ),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chevron_left,
                                  size: ResponsiveHelper.getResponsiveIconSize(
                                      context, 18),
                                  color: isDesktopLayout
                                      ? Colors.white.withOpacity(0.7)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Back to Role Selection',
                                  style: TextStyle(
                                    color: isDesktopLayout
                                        ? Colors.white.withOpacity(0.7)
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                    fontSize: ResponsiveHelper
                                        .getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Check platform type
      final isDesktopPlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);
      
      // For WEB ONLY: use simulated login (no backend)
      // Desktop and Mobile: use real Supabase authentication (same database)
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - using simulated login');
        final authProvider = context.read<AuthProvider>();
        final email = _emailController.text.trim();
        
        // Show loading state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signing in...'),
            backgroundColor: Colors.blue,
          ),
        );
        
        // Simulate a brief loading delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to determine role from email - check for admin patterns
        UserRole role = UserRole.technician;
        final emailLower = email.toLowerCase();
        
        if (emailLower.contains('admin') || emailLower.contains('manager') || 
            emailLower.contains('@royalgulf.ae') || emailLower.contains('@mekar.ae')) {
          role = UserRole.admin;
        }
        
        // Set the simulated user in AuthProvider
        authProvider.simulateLogin(email, role);
        
        if (mounted) {
          // Navigate based on role
          if (role == UserRole.admin) {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/technician');
          }
        }
        return;
      }

      // Desktop and Mobile login logic - use real Supabase authentication
      // Both sync with the same database
      if (isDesktopPlatform) {
        debugPrint('🖥️ Desktop platform detected - using real Supabase authentication');
      } else {
        debugPrint('📱 Mobile platform detected - using real Supabase authentication');
      }
      
      final authProvider = context.read<AuthProvider>();
      
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Wait a moment for role to be properly loaded
        await Future.delayed(Duration(milliseconds: 300));
        
        // Check approval status for technicians
        if (!authProvider.isAdmin) {
          final isApproved = await authProvider.checkApprovalStatus();
          if (isApproved == false) {
            // User is pending approval or rejected
            Navigator.pushReplacementNamed(context, '/pending-approval');
            return;
          }
        }
        
        // Navigate based on role (automatically determined from database)
        if (authProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (authProvider.isPendingApproval) {
          Navigator.pushReplacementNamed(context, '/pending-approval');
        } else {
          // Technician is approved - will check for initial setup in InitialToolSetupScreen
          Navigator.pushReplacementNamed(context, '/technician');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    // Show dialog to enter email
    final emailController = TextEditingController(
      text: _emailController.text, // Pre-fill with existing email if any
    );
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'your.email@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Send Reset Link'),
          ),
        ],
        ),
      );

    if (result == true && emailController.text.trim().isNotEmpty) {
    try {
      final authProvider = context.read<AuthProvider>();
        await authProvider.resetPassword(emailController.text.trim());
      
      if (mounted) {
          // Update the email field with the entered email
          _emailController.text = emailController.text.trim();
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Email Sent!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'We\'ve sent a password reset link to ${emailController.text.trim()}. Please check your inbox and follow the instructions to reset your password.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
    }
    
    emailController.dispose();
  }
}
