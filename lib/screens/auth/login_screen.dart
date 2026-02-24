import 'dart:async';
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
import '../../services/supabase_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_role.dart';
import '../../widgets/common/themed_text_field.dart';
import '../../widgets/common/themed_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'auth_error_screen.dart';
import '../../utils/logger.dart';
import '../../l10n/app_localizations.dart';

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
  bool _isSigningIn = false;
  static const Duration _authTimeout = Duration(seconds: 15);
  static const Duration _profileTimeout = Duration(seconds: 10);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildSocialIconButtons(BuildContext context) {
    final theme = Theme.of(context);
    final supportsApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final showAppleSignIn = supportsApple;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.isLoading;

        Widget buildIconButton({
          required VoidCallback onPressed,
          required Widget icon,
          required String label,
        }) {
          return Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.iconButtonBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.cardBorder,
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onPressed,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final buttons = <Widget>[
          buildIconButton(
            onPressed: () async {
              try {
                await authProvider
                    .signInWithGoogle()
                    .timeout(
                      _authTimeout,
                      onTimeout: () {
                        authProvider.resetLoadingState(reason: 'google-timeout');
                        throw TimeoutException(
                          'Google sign-in timed out.',
                          _authTimeout,
                        );
                      },
                    );
                if (context.mounted) {
                  await _handleOAuthPostLogin(authProvider);
                }
              } catch (e) {
                authProvider.resetLoadingState(reason: 'google-error');
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

        if (showAppleSignIn) {
          buttons.add(const SizedBox(width: 12));
          buttons.add(
            buildIconButton(
              onPressed: () async {
                try {
                  await authProvider.signInWithApple();
                  if (context.mounted) {
                    await _handleOAuthPostLogin(authProvider);
                  }
                } catch (e) {
                  authProvider.resetLoadingState(reason: 'apple-error');
                  if (context.mounted) {
                    String errorMessage;
                    if (e is SignInWithAppleAuthorizationException) {
                      if (e.code == AuthorizationErrorCode.canceled) {
                        errorMessage = 'Apple sign-in was cancelled.';
                      } else {
                        errorMessage = e.message ?? 'Apple sign-in failed.';
                      }
                    } else if (e.toString().contains('Sign in with Apple')) {
                      errorMessage = e.toString();
                    } else {
                      errorMessage = AuthErrorHandler.getErrorMessage(e);
                    }
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
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final bool isDesktopLayout = size.width >= 900;
    final bool isTabletLayout = !kIsWeb && size.shortestSide >= 600;
    final bool useCardLayout = isDesktopLayout || isTabletLayout;
    final double cardMaxWidth = isDesktopLayout
        ? 520
        : (isTabletLayout ? 560 : double.infinity);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardBackground = context.cardBackground;
    final cardBorder = context.cardBorder;
    final cardShadow = BoxShadow(
      color: isDarkMode ? Colors.black54 : Colors.black.withOpacity(0.12),
      blurRadius: isDarkMode ? 30 : 32,
      offset: Offset(0, isDarkMode ? 20 : 14),
    );
    final initialRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final showDeepLinkBanner = initialRoute.contains('auth/callback') ||
        initialRoute.contains('reset-password') ||
        initialRoute.contains('code=');
    
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: useCardLayout ? 48 : 24,
                vertical: isTabletLayout ? 24 : 40,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment:
                      isTabletLayout ? Alignment.center : Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardMaxWidth,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: useCardLayout ? 32 : 0,
                        vertical: useCardLayout ? 32 : 0,
                      ),
                      decoration: useCardLayout
                          ? BoxDecoration(
                              color: cardBackground.withOpacity(
                                isDarkMode ? 0.9 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(color: cardBorder),
                              boxShadow: [cardShadow],
                            )
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDeepLinkBanner) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          'Deep link: $initialRoute',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacingLarge),
                    ],
                    // Top whitespace 80-100px
                    SizedBox(
                      height: isTabletLayout
                          ? context.spacingLarge * 3
                          : context.spacingLarge * 5.625,
                    ), // ~48px / ~90px
                    
                    // Logo centered - width 110-130px
                    Center(
                      child: Image.asset(
                        logoAsset,
                        width: isTabletLayout ? 140 : 120,
                        height: null,
                      fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          Logger.debug('❌ Error loading logo: $error');
                          Logger.debug('❌ Logo asset path: $logoAsset');
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
                              label: AppLocalizations.of(context).login_emailLabel,
                            hint: AppLocalizations.of(context).login_emailHint,
                              prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).validation_emailRequired;
                              }
                              if (!value.contains('@')) {
                                return AppLocalizations.of(context).validation_emailInvalid;
                              }
                              if (!AppConfig.isEmailDomainAllowed(value)) {
                                return AppLocalizations.of(context).login_emailDomainNotAllowed;
                              }
                              return null;
                            },
                          ),
                          
                          // Password field
                          const SizedBox(height: 18),
                          ThemedTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                              label: AppLocalizations.of(context).login_passwordLabel,
                            hint: AppLocalizations.of(context).login_passwordHint,
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
                                return AppLocalizations.of(context).validation_passwordRequired;
                              }
                              if (value.length < 6) {
                                return AppLocalizations.of(context).validation_passwordMinLength;
                              }
                              return null;
                            },
                          ),
                          
                          // Spacing ~24px
                          SizedBox(height: context.spacingLarge + context.spacingSmall), // 24px
                          
                          // Sign In button
                          ThemedButton(
                            onPressed: _isSigningIn ? null : _handleLogin,
                            isLoading: _isSigningIn,
                            child: Text(
                                      AppLocalizations.of(context).login_signInButton,
                                      style: const TextStyle(
                                fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                    ),
                            ),
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
            );
          },
        ),
      ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSigningIn = true);

    try {
      // All platforms (Web, Desktop, Mobile) use real Supabase authentication
      final isDesktopPlatform = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);
      
      if (kIsWeb) {
        Logger.debug('🌐 Web platform detected - using real Supabase authentication');
      } else if (isDesktopPlatform) {
        Logger.debug('🖥️ Desktop platform detected - using real Supabase authentication');
      } else {
        Logger.debug('📱 Mobile platform detected - using real Supabase authentication');
      }
      
      final authProvider = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      
      // Try to sign in - Supabase will handle email confirmation check
      // If email is not confirmed, signIn will throw an error which we'll catch below
      await authProvider.signIn(
        email: email,
        password: _passwordController.text,
      ).timeout(
        _authTimeout,
        onTimeout: () {
          authProvider.resetLoadingState(reason: 'email-timeout');
          throw TimeoutException(
            'Email sign-in timed out.',
            _authTimeout,
          );
        },
      );
      
      if (mounted) {
        final hasProfile = await _ensureProfileLoaded(authProvider);
        if (!hasProfile) {
          return;
        }

        final session = SupabaseService.client.auth.currentSession;
        if (session == null || session.user == null) {
          authProvider.resetLoadingState(reason: 'session-missing');
          throw Exception('Login succeeded but no session was established.');
        }

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
      context.read<AuthProvider>().resetLoadingState(reason: 'email-error');
      if (mounted) {
        setState(() => _isSigningIn = false);
        final errorMessage = AuthErrorHandler.getErrorMessage(e);
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    }
  }

  Future<void> _handleOAuthPostLogin(AuthProvider authProvider) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final session = SupabaseService.client.auth.currentSession;
    if (session == null || session.user == null) {
      authProvider.resetLoadingState(reason: 'oauth-session-missing');
      throw Exception('Login succeeded but no session was established.');
    }

    final appMetadata = session.user.appMetadata ?? <String, dynamic>{};
    final provider = appMetadata['provider']?.toString();
    final providers = appMetadata['providers'];
    final isAppleProvider = provider == 'apple' ||
        (providers is List && providers.map((e) => e.toString()).contains('apple'));
    final bypassApproval =
        isAppleProvider && await authProvider.isAppleApprovalBypassEnabled();

    final roleFromMetadata = session.user.userMetadata?['role'] as String?;
    String? resolvedRole = roleFromMetadata;
    if (resolvedRole == null || resolvedRole.isEmpty) {
      try {
        final userRecord = await SupabaseService.client
            .from('users')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
        resolvedRole = userRecord?['role'] as String?;
      } catch (_) {
        resolvedRole = null;
      }
    }

    // If no role by id, check by email - same email may be registered via email/password
    // (OAuth creates a different auth identity than email signup)
    if ((resolvedRole == null || resolvedRole.isEmpty) && session.user.email != null && session.user.email!.isNotEmpty) {
      try {
        final existingByEmail = await SupabaseService.client
            .from('users')
            .select('id, role')
            .eq('email', session.user.email!.toLowerCase().trim())
            .maybeSingle();
        if (existingByEmail != null) {
          // Email already registered - different auth identity. Ask to use email sign-in.
          await authProvider.signOut();
          if (mounted) {
            AuthErrorHandler.showErrorSnackBar(
              context,
              'This email is already registered. Please sign in with your email and password.',
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
          return;
        }
      } catch (_) {
        // Continue to role selection on error
      }
    }

    if (resolvedRole == null || resolvedRole.isEmpty) {
      // Not registered - must create account first. Redirect to role selection.
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Create an account to continue with your ${isAppleProvider ? "Apple" : "Google"} ID',
        );
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
      return;
    }

    final hasProfile = await _ensureProfileLoaded(authProvider);
    if (!hasProfile) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!authProvider.isAdmin && !bypassApproval) {
      final isApproved = await authProvider.checkApprovalStatus();
      if (isApproved == false) {
        Navigator.pushReplacementNamed(context, '/pending-approval');
        return;
      }
    }

    if (authProvider.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (!bypassApproval && authProvider.isPendingApproval) {
      Navigator.pushReplacementNamed(context, '/pending-approval');
    } else {
      Navigator.pushReplacementNamed(context, '/technician');
    }
  }

  Future<bool> _ensureProfileLoaded(AuthProvider authProvider) async {
    final session = SupabaseService.client.auth.currentSession;
    final user = session?.user;
    if (user == null) {
      authProvider.resetLoadingState(reason: 'profile-session-missing');
      return false;
    }

    Map<String, dynamic>? profile;
    try {
      profile = await UserProfileService.getUserProfile(user.id).timeout(
        _profileTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Profile loading timed out.',
            _profileTimeout,
          );
        },
      );
    } catch (_) {
      profile = null;
    }

    final roleFromProvider = authProvider.userRole.value;
    final role = profile?['role'] as String? ??
        authProvider.user?.userMetadata?['role'] as String? ??
        (roleFromProvider == 'pending' ? null : roleFromProvider);
    final hasOrgField = profile?.containsKey('organization_id') ?? false;
    final organizationId =
        hasOrgField && profile != null ? profile['organization_id'] : null;
    final missingRole = role == null || role.isEmpty;
    final missingOrg = role == 'technician' &&
        hasOrgField &&
        (organizationId == null || organizationId.toString().isEmpty);
    final isProfileIncomplete = missingRole || missingOrg;

    if (isProfileIncomplete) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthErrorScreen(
              title: 'Profile Unavailable',
              message:
                  'We could not load your account details. Please contact support or try again.',
            ),
          ),
        );
      }
      return false;
    }

    return true;
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
