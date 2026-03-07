import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_handler.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import '../utils/responsive_helper.dart';
import 'company_setup_wizard_screen.dart';
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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _checkBootstrapAccess() async {
    final authProvider = context.read<AuthProvider>();
    final allowed = await authProvider.canBootstrapAdmin();
    if (!mounted) return;
    if (!allowed) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'Admin registration is closed. Please request an admin invite.',
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDesktopLayout = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Registration', style: TextStyle(fontWeight: FontWeight.w600)),
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
              constraints: BoxConstraints(maxWidth: isDesktopLayout ? 640 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Register as an administrator for ${AppConfig.appName}',
                    style: TextStyle(fontSize: 16, color: context.secondaryTextColor, fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacingLarge * 1.5),

                  Container(
                    padding: EdgeInsets.all(isDesktopLayout ? 32 : context.spacingLarge),
                    decoration: context.cardDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ThemedTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter full name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your full name' : null,
                          ),
                          SizedBox(height: context.spacingMedium),

                          ThemedTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            label: 'Email Address',
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Please enter your email address';
                              if (!AppConfig.isAdminEmailDomain(value)) {
                                return 'Invalid email domain for admin registration. Use ${AppConfig.adminDomainsDisplay}';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacingMedium),

                          ThemedTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            label: 'Password',
                            hint: 'Minimum 6 characters',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacingMedium),

                          ThemedTextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacingLarge + context.spacingSmall),

                          ThemedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            isLoading: _isLoading,
                            child: const Text('Register as Admin',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          ),
                          SizedBox(height: context.spacingLarge),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.secondaryTextColor)),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                    context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text('Sign in',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor)),
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
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      Logger.debug('🔍 Starting admin registration...');
      final response = await authProvider.registerAdmin(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      Logger.debug('✅ Admin registration completed');
      if (mounted) {
        if (response.user == null) throw Exception('Registration failed. Please try again.');
        if (response.session != null) {
          // Auto-confirmed — go to company setup wizard
          AuthErrorHandler.showSuccessSnackBar(context, 'Account created! Let\'s set up your company.');
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const CompanySetupWizardScreen()), (route) => false);
        } else {
          // Email confirmation required
          await _showEmailConfirmationDialog();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        Logger.debug('❌ Admin registration error: $e');
        String msg = AuthErrorHandler.getErrorMessage(e);
        if (e.toString().contains('already registered') || e.toString().contains('already exists')) {
          msg = 'This email is already registered. Try signing in instead.';
        }
        AuthErrorHandler.showErrorSnackBar(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEmailConfirmationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Icon(Icons.email_outlined, color: AppTheme.secondaryColor, size: 28),
          const SizedBox(width: 12),
          const Text('Check Your Email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We\'ve sent a confirmation link to:'),
            const SizedBox(height: 8),
            Text(_emailController.text.trim(),
                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryColor)),
            const SizedBox(height: 16),
            const Text(
              'Click the link in your email to confirm your account. After confirming, sign in and you\'ll be taken to the company setup wizard.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          ThemedButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}
