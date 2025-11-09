import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/rgs_logo.dart';
import '../../utils/auth_error_handler.dart';
import '../../config/app_config.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 80.0, bottom: 16.0),
          child: Column(
            children: [
                  // Branding Section
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // RGS Branding - Larger and more prominent
                    Column(
                      children: [
                        Text(
                          'RGS',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                                color: Colors.grey[800],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HVAC SERVICES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                            letterSpacing: 0.5,
                          ),
                        ),
                            const SizedBox(height: 16),
                        Text(
                          'Not your ordinary HVAC company.',
                          style: TextStyle(
                                fontSize: 18,
                            fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                  
                  const SizedBox(height: 32),
              
              // Login Form Section
                  Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradientFor(context),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: Colors.grey[800]),
                            decoration: InputDecoration(
                              labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                              ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Password Field
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradientFor(context),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                              style: TextStyle(color: Colors.grey[800]),
                            decoration: InputDecoration(
                              labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                              ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade600, Colors.green.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: authProvider.isLoading ? null : _handleLogin,
                                    borderRadius: BorderRadius.circular(28),
                                    child: Center(
                                  child: authProvider.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Forgot Password
                          InkWell(
                            onTap: _handleForgotPassword,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Back to Role Selection
                          InkWell(
                            onTap: () {
                                Navigator.pop(context);
                              },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                '← Back to Role Selection',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
