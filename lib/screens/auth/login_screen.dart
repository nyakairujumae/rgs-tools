import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/auth_error_handler.dart';
import '../../config/app_config.dart';
import '../../utils/logo_assets.dart';
import '../../utils/responsive_helper.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/themed_text_field.dart';
import '../../widgets/common/themed_button.dart';

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

  Widget _buildSocialIconButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.isLoading;

        Widget buildIconButton({
          required VoidCallback onPressed,
          required Widget icon,
          required String label,
        }) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.iconButtonBackground,
                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                  ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onPressed,
                    borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                    child: Center(child: icon),
                  ),
                ),
              ),
              const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: context.secondaryTextColor,
                    ),
                  ),
                ],
          );
        }

        final buttons = <Widget>[
          buildIconButton(
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
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata_rounded,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
            ),
            label: 'Google',
          ),
        ];

        if (isIOS) {
          buttons.add(SizedBox(width: context.spacingLarge + context.spacingSmall)); // 20px
          buttons.add(
            buildIconButton(
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
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/apple_logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.apple,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              label: 'Apple',
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logoAsset = getThemeLogoAsset(theme.brightness);
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;
    
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
                    // Top whitespace 80-100px
                    SizedBox(height: context.spacingLarge * 5.625), // ~90px
                    
                    // Logo centered - width 110-130px
                    Center(
                      child: Image.asset(
                        logoAsset,
                        width: 120,
                        height: null,
                      fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Error loading logo: $error');
                          debugPrint('❌ Logo asset path: $logoAsset');
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    
                    // Spacing ~34px
                    SizedBox(height: context.spacingLarge * 2.125), // ~34px
                    
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email field
                          ThemedTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                              label: 'Email',
                            hint: 'Enter your email',
                              prefixIcon: Icons.email_outlined,
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
                          
                          // Password field - tight spacing (~12px)
                          SizedBox(height: context.spacingMedium), // ~12px
                          ThemedTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                              label: 'Password',
                            hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          // Spacing ~24px
                          SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px
                          
                          // Sign In button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return ThemedButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                isLoading: authProvider.isLoading,
                                child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                    fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                        ),
                                ),
                              );
                            },
                          ),
                          
                          // Spacing ~24px below Sign In button
                          SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px
                          
                          // "Or continue with" divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: context.cardBorder,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Or continue with',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: context.cardBorder,
                                ),
                              ),
                            ],
                          ),
                          
                          // Spacing above social icons
                          SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px
                          
                          // Social icon buttons with labels
                          _buildSocialIconButtons(context),
                          
                          // Spacing
                          SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px
                          
                          // Back & Forgot Password in same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemedTextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/role-selection',
                                (route) => false,
                              );
                            },
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                              ),
                            ),
                              ThemedTextButton(
                                onPressed: _handleForgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  ),
                                ),
                              ],
                          ),
                          
                          // Bottom safe-area spacing
                          SizedBox(height: MediaQuery.of(context).padding.bottom + context.spacingLarge),
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
        // Default to pending (unknown) instead of assuming technician
        UserRole role = UserRole.pending;
        final emailLower = email.toLowerCase();
        
        if (emailLower.contains('admin') || emailLower.contains('manager') || 
            emailLower.contains('@royalgulf.ae') || 
            emailLower.contains('@mekar.ae') || 
            emailLower.contains('@gmail.com')) {
          role = UserRole.admin;
        } else {
          // For web simulation, if no admin pattern, still use pending
          // User should register with explicit role
          role = UserRole.pending;
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
      
      final email = _emailController.text.trim();
      
      // Try to sign in - Supabase will handle email confirmation check
      // If email is not confirmed, signIn will throw an error which we'll catch below
      await authProvider.signIn(
        email: email,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              minimumSize: const Size(120, 44), // Ensure button is wide enough
            ),
            child: Text(
              'Send Reset Link',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
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
