import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
    final backgroundColor = theme.colorScheme.background;
    return Scaffold(
      backgroundColor: backgroundColor,
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
                    color: const Color(0xFF2E7D32),
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
            'assets/images/rgs.jpg',
            width: logoWidth,
            fit: BoxFit.contain,
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: subtitleColor,
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
    final borderRadius = BorderRadius.circular(30);
    final textColor = Colors.white;
    final shadowColor = Colors.black.withOpacity(0.1);

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
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _navigate(context, const LoginScreen()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            children: [
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextSpan(
                text: 'Sign in',
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
