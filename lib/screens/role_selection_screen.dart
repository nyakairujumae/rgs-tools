import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../utils/logo_assets.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../utils/auth_error_handler.dart';
import 'admin_registration_screen.dart';
import 'auth/login_screen.dart';
import 'technician_registration_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktopWidth = size.width >= 900;
    final isDesktopPlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final isDesktop = isDesktopWidth || isDesktopPlatform;
    final isWebOrWideScreen = kIsWeb || size.width > 600;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWebOrWideScreen ? 400 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildBranding(context, isDesktop),
                    const SizedBox(height: 36),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final provider = authProvider.user?.appMetadata?['provider'] as String?;
                        final roleFromMetadata = authProvider.user?.userMetadata?['role'] as String?;
                        final isOAuthUser = authProvider.isAuthenticated &&
                            provider != null &&
                            provider != 'email' &&
                            (authProvider.userRole == UserRole.pending ||
                                roleFromMetadata == null ||
                                roleFromMetadata.isEmpty);
                        
                        return Column(
                          children: [
                            _buildRoleButton(
                              context: context,
                              label: isOAuthUser ? 'Continue as Admin' : 'Register as Admin',
                              color: AppTheme.secondaryColor,
                              onTap: _isProcessing 
                                  ? () {} // Empty function when processing
                                  : () => _handleRoleSelection(
                                      context,
                                      UserRole.admin,
                                      isOAuthUser,
                                    ),
                              animationCurve:
                                  const Interval(0.0, 1.0, curve: Curves.easeOut),
                            ),
                            const SizedBox(height: 16),
                            _buildRoleButton(
                              context: context,
                              label: isOAuthUser ? 'Continue as Technician' : 'Register as Technician',
                              color: theme.colorScheme.surface,
                              onTap: _isProcessing 
                                  ? () {} // Empty function when processing
                                  : () => _handleRoleSelection(
                                      context,
                                      UserRole.technician,
                                      isOAuthUser,
                                    ),
                              animationCurve:
                                  const Interval(0.2, 1.0, curve: Curves.easeOut),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildSignInLink(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final subtitleColor =
        theme.colorScheme.onBackground.withOpacity(0.65);
    final logoWidth = isDesktop ? 150.0 : 120.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          ),
          child: Image.asset(
            getThemeLogoAsset(theme.brightness),
            width: logoWidth,
            height: null,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error loading logo: $error');
              debugPrint('❌ Logo asset path: ${getThemeLogoAsset(theme.brightness)}');
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
          child: Text(
            'Tool Tracking • Assignments • Inventory',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: context.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Curve animationCurve = Curves.easeOut,
  }) {
    bool isPressed = false;
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(context.borderRadiusLarge);
    // Use theme-aware text color: if color is secondaryColor (green), use white; otherwise use onSurface
    final textColor = color == AppTheme.secondaryColor 
        ? Colors.white 
        : theme.colorScheme.onSurface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: animationCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StatefulBuilder(
          builder: (context, setStateSB) {
            return AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: isPressed ? 0.98 : 1.0,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: borderRadius,
                  splashColor: theme.colorScheme.onSurface.withOpacity(0.08),
                  highlightColor: theme.colorScheme.onSurface.withOpacity(0.06),
                  onHighlightChanged: (value) =>
                      setStateSB(() => isPressed = value),
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: borderRadius,
                      boxShadow: context.cardShadows,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
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
          onPressed: () => _navigate(context, const LoginScreen()),
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
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
  
  Future<void> _handleRoleSelection(BuildContext context, UserRole role, bool isOAuthUser) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      if (role == UserRole.admin) {
        final bootstrapAllowed = await authProvider.canBootstrapAdmin();
        if (!bootstrapAllowed) {
          if (!mounted) return;
          AuthErrorHandler.showErrorSnackBar(
            context,
            'Admin registration is closed. Please request an admin invite.',
          );
          return;
        }
      }

      if (isOAuthUser) {
        await authProvider.assignRoleToOAuthUser(role);
        if (!mounted) return;
        if (role == UserRole.admin) {
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/pending-approval', (_) => false);
        }
        return;
      }

      // Regular user - navigate to registration screen
      if (role == UserRole.admin) {
        _navigate(context, const AdminRegistrationScreen());
      } else {
        _navigate(context, const TechnicianRegistrationScreen());
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = AuthErrorHandler.getErrorMessage(e);
      AuthErrorHandler.showErrorSnackBar(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
