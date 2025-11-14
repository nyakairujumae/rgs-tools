import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../config/app_config.dart';
import '../../utils/responsive_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: Colors.grey[900],
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  Text(
                    'HVAC SERVICES',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Text(
                    'Not your ordinary HVAC company.',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
              
              // Login Form Section
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[600],
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
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
                              color: Colors.grey[900],
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey[600],
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[600],
                                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                          
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                          
                          // Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: ResponsiveHelper.getResponsiveListItemHeight(context, 56),
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _handleLogin,
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
                                          'Sign In',
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
                          
                          // Forgot Password
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
                                color: AppTheme.secondaryColor,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                          
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
                                color: Colors.grey[700],
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // For web, simulate login without backend
      if (kIsWeb) {
        // Show loading state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signing in...'),
            backgroundColor: Colors.blue,
          ),
        );
        
        // Simulate a brief loading delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Determine role based on email for demo
        final email = _emailController.text.toLowerCase();
        final isAdmin = email.contains('admin') || email.contains('manager');
        
        if (mounted) {
          // Navigate based on role
          if (isAdmin) {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/technician');
          }
        }
        return;
      }

      // Original mobile login logic
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
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context, 
          '📧 Password reset email sent! Check your inbox.'
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }
}
