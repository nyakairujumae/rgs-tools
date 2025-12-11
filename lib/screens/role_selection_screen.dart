import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../utils/logo_assets.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'admin_registration_screen.dart';
import 'auth/login_screen.dart';
import 'technician_registration_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
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
                  _buildRoleButton(
                    context: context,
                    label: 'Register as Admin',
                    color: AppTheme.secondaryColor,
                    onTap: () => _navigate(
                      context,
                      const AdminRegistrationScreen(),
                    ),
                    animationCurve:
                        const Interval(0.0, 1.0, curve: Curves.easeOut),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleButton(
                    context: context,
                    label: 'Register as Technician',
                    color: Colors.black,
                    onTap: () => _navigate(
                      context,
                      const TechnicianRegistrationScreen(),
                    ),
                    animationCurve:
                        const Interval(0.2, 1.0, curve: Curves.easeOut),
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
    final borderRadius = BorderRadius.circular(context.borderRadiusLarge);
    final textColor = Colors.white;

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
                child: InkWell(
                  onTap: onTap,
                  borderRadius: borderRadius,
                  splashColor: Colors.white.withOpacity(0.08),
                  highlightColor: Colors.white.withOpacity(0.06),
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
}
