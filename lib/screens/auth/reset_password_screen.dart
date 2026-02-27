import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error_handler.dart';
import '../../utils/responsive_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart';
import '../../utils/logger.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;
  final String? type;
  final String? deepLink;

  const ResetPasswordScreen({
    super.key,
    this.accessToken,
    this.refreshToken,
    this.type,
    this.deepLink,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _ensureSessionFromTokens({bool showErrors = false}) async {
    final refreshToken = widget.refreshToken;
    final accessToken = widget.accessToken;
    final token = refreshToken ?? accessToken;
    if (token == null) {
      final deepLink = widget.deepLink;
      if (deepLink == null || deepLink.isEmpty) return;
      try {
        final uri = Uri.parse(deepLink);
        final params = <String, String>{}
          ..addAll(uri.queryParameters)
          ..addAll(
            uri.fragment.isNotEmpty
                ? Uri.splitQueryString(
                    uri.fragment.startsWith('?')
                        ? uri.fragment.substring(1)
                        : uri.fragment,
                  )
                : <String, String>{},
          );
        final tokenHash = params['token'];
        final code = params['code'];
        final type = params['type'];
        Logger.debug('🔐 Reset deep link params: type=$type hasToken=${tokenHash != null}');
        if (code != null) {
          Logger.debug('🔐 Exchanging code for session');
          await Supabase.instance.client.auth.exchangeCodeForSession(code);
          return;
        }
        if (tokenHash != null && (type == 'invite' || type == 'recovery')) {
          Logger.debug('🔐 Verifying OTP from deep link type=$type');
          await Supabase.instance.client.auth.verifyOTP(
            tokenHash: tokenHash,
            type: type == 'invite' ? OtpType.invite : OtpType.recovery,
          );
          return;
        }
        final sessionResponse = await Supabase.instance.client.auth.getSessionFromUrl(uri);
        if (sessionResponse.session == null) {
          throw const AuthException('Session expired. Please open the invite link again.');
        }
        return;
      } catch (e) {
        Logger.debug('❌ Failed to set session from deep link: $e');
        if (showErrors && mounted) {
          final errorMessage = AuthErrorHandler.getErrorMessage(e);
          AuthErrorHandler.showErrorSnackBar(context, errorMessage);
        }
        return;
      }
    }

    try {
      // Supabase setSession now takes a single refresh token argument
      await Supabase.instance.client.auth.setSession(token);
    } catch (e) {
      Logger.debug('❌ Failed to set session for password reset: $e');
      if (showErrors && mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      AuthErrorHandler.showErrorSnackBar(context, 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureSessionFromTokens(showErrors: true);
      if (Supabase.instance.client.auth.currentSession == null) {
        throw const AuthException('Session expired. Please open the invite link again.');
      }

      final authProvider = context.read<AuthProvider>();
      
      // Update password using Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (!mounted) return;

      // Treat both invite and recovery flows the same - auto-login after password set
      // This is because technicians added by admin receive recovery emails
      // and should be logged in automatically after setting their password
      final shouldAutoLogin = widget.type == 'invite' ||
          widget.type == 'recovery' ||
          (widget.deepLink?.contains('mode=invite') ?? false) ||
          (widget.deepLink?.contains('type=recovery') ?? false);

      setState(() {
        _isLoading = false;
      });

      // Show brief success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).resetPassword_successMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );

      // Brief delay then auto-login
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      if (shouldAutoLogin) {
        // Keep the session and route directly to the right home screen
        await authProvider.initialize();
        if (!mounted) return;

        final navigator = Navigator.of(context);
        final isApproved = await authProvider.checkApprovalStatus();

        if (authProvider.isAdmin) {
          navigator.pushNamedAndRemoveUntil('/admin', (route) => false);
        } else if (authProvider.isTechnician && isApproved == true) {
          navigator.pushNamedAndRemoveUntil('/technician', (route) => false);
        } else {
          navigator.pushNamedAndRemoveUntil('/pending-approval', (route) => false);
        }
      } else {
        // Fallback: Sign out and go to login (shouldn't happen normally)
        await authProvider.signOut();
        
        if (!mounted) return;
        
        // Navigate to login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 24,
            vertical: 40,
          ),
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),

              // Branding Section
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: AppTheme.secondaryColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Text(
                    AppLocalizations.of(context).resetPassword_title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  Text(
                    AppLocalizations.of(context).resetPassword_subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),

              // Reset Password Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // New Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).resetPassword_newPasswordLabel,
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).resetPassword_confirmLabel,
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

                    // Reset Password Button
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveHelper.getResponsiveListItemHeight(context, 56),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
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
                        child: _isLoading
                            ? SizedBox(
                                height: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                width: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context).resetPassword_button,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                    // Back to Login
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).resetPassword_backToLogin,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
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
}
