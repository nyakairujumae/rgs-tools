import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../utils/responsive_helper.dart';
import '../widgets/premium_field_styles.dart';
import 'admin_home_screen.dart';
import 'role_selection_screen.dart';
import 'technician_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const _adminDomains = ['@royalgulf.ae', '@mekar.ae'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktopWidth = MediaQuery.of(context).size.width >= 900;
    final isDesktopPlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);
    final applyDesktopStyling = isDesktopWidth || isDesktopPlatform;
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = applyDesktopStyling
        ? (isDarkMode ? const Color(0xFF0F172A) : Colors.white)
        : colorScheme.surface;
    final cardShadow = applyDesktopStyling
        ? BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 20),
          )
        : const BoxShadow(color: Colors.transparent);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: isDesktopWidth ? 80 : 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktopWidth ? 520 : double.infinity,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                  boxShadow: applyDesktopStyling ? [cardShadow] : null,
                  gradient: applyDesktopStyling && isDarkMode
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF111827),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktopWidth ? 32 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        _buildHeader(theme),
                        
                        const SizedBox(height: 32),
                        
                        // Email Field
                        Text(
                          'Email Address',
                          style: PremiumFieldStyles.labelTextStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: PremiumFieldStyles.fieldTextStyle(context),
                          decoration: PremiumFieldStyles.inputDecoration(
                            context,
                            hintText: 'e.g., user@royalgulf.ae',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Please enter your email address';
                            }
                            const emailPattern =
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$';
                            if (!RegExp(emailPattern).hasMatch(email)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password Field
                        Text(
                          'Password',
                          style: PremiumFieldStyles.labelTextStyle(context),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: PremiumFieldStyles.fieldTextStyle(context),
                          decoration: PremiumFieldStyles.inputDecoration(
                            context,
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'Please enter your password' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sign In Button
                        Container(
                          height: 56,
                          decoration: applyDesktopStyling
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.85),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.45),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                )
                              : null,
                          child: Material(
                            color: applyDesktopStyling
                                ? Colors.transparent
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _isLoading ? null : _handleLogin,
                              child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: applyDesktopStyling ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: applyDesktopStyling ? 0.6 : 0.2,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Register Links
                        Column(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                              ),
                              child: Text(
                                'Don\'t have an account? Register Here',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose Admin or Technician registration',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Role Information
                        _buildRoleInfoCard(),
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      await authProvider.signIn(
        email: email,
        password: _passwordController.text,
      );

      if (mounted) {
        if (authProvider.isAdmin && !_hasValidAdminDomain(email)) {
          AuthErrorHandler.showErrorSnackBar(
            context,
            'Access denied: Invalid admin credentials',
          );
          await authProvider.signOut();
          return;
        }

        AuthErrorHandler.showSuccessSnackBar(
          context,
          '🎉 Welcome back! Successfully signed in.',
        );
        _navigateAfterLogin(authProvider);
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          AuthErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'Please enter your email address first',
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      
      await authProvider.resetPassword(email);

      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          '📧 Password reset email sent! Check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          AuthErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.login, size: 64, color: theme.primaryColor),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your RGS HVAC Services account',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Account Types',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Admin: Full system access and management\nTechnician: Tool management and reporting',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValidAdminDomain(String email) {
    return _adminDomains.any(email.endsWith);
  }

  void _navigateAfterLogin(AuthProvider authProvider) {
    final route = MaterialPageRoute(
      builder: (_) => authProvider.isAdmin
          ? const AdminHomeScreen()
          : const TechnicianHomeScreen(),
    );
    Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
  }
}
