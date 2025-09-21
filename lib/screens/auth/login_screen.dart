import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/rgs_logo.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              
              // RGS Branding and Title
              Column(
                children: [
                  // RGS Logo with enhanced styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const RGSLogo(),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'HVAC Tools Manager',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Professional Tool Management System',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 60),
              
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
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
                    
                    SizedBox(height: 24),
                    
                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Forgot Password
                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

    final authProvider = context.read<AuthProvider>();
    
    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Wait a moment for role to be properly loaded
        await Future.delayed(Duration(milliseconds: 100));
        
        // Navigate based on role (automatically determined from database)
        debugPrint('🔍 Login: User role is ${authProvider.userRole}');
        debugPrint('🔍 Login: isAdmin = ${authProvider.isAdmin}');
        
        if (authProvider.isAdmin) {
          debugPrint('🚀 Navigating to admin screen');
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          debugPrint('🚀 Navigating to technician screen');
          Navigator.pushReplacementNamed(context, '/technician');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Oops! Something went wrong. Please try again.';
        
        // Parse error message to show user-friendly text
        String errorString = e.toString().toLowerCase();
        if (errorString.contains('invalid login credentials') || 
            errorString.contains('invalid_credentials')) {
          errorMessage = 'Hmm, that email or password doesn\'t look right.';
        } else if (errorString.contains('user not found')) {
          errorMessage = 'Sorry, we couldn\'t find an account with that email.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Oh no! Looks like there\'s a connection issue.';
        } else if (errorString.contains('too many requests')) {
          errorMessage = 'Whoa! Too many attempts. Take a quick break.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.blue, // Changed to blue
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Oops! Couldn\'t send the reset email.';
        
        // Parse error message to show user-friendly text
        String errorString = e.toString().toLowerCase();
        if (errorString.contains('user not found') || errorString.contains('invalid email')) {
          errorMessage = 'Sorry, we couldn\'t find an account with that email.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Oh no! Looks like there\'s a connection issue.';
        } else if (errorString.contains('too many requests')) {
          errorMessage = 'Whoa! Too many requests. Take a quick break.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.blue, // Changed to blue
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
