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
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDesktopWidth = size.width >= 900;
    final isDesktopPlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final isDesktop = isDesktopWidth || isDesktopPlatform;
    final backgroundColor =
        isDesktop ? const Color(0xFF050A12) : colorScheme.surface;
    final cardColor =
        isDesktop ? const Color(0xFF0F1624) : colorScheme.surface;
    final cardShadow = isDesktop
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 28),
            ),
          ]
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 56 : 24,
              vertical: isDesktop ? 48 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 640 : double.infinity,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(isDesktop ? 32 : 0),
                  border: isDesktop
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        )
                      : null,
                  boxShadow: cardShadow,
                  gradient: isDesktop
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF111B2E),
                            Color(0xFF0B1220),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 40 : 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBranding(theme, isDesktop),
                      SizedBox(height: isDesktop ? 56 : 48),
                      _buildRoleButton(
                        context: context,
                        label: 'Register as Admin',
                        color: Colors.green[600] ?? Colors.green,
                        onTap: () => _navigate(
                          context,
                          const AdminRegistrationScreen(),
                        ),
                        isDesktop: isDesktop,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleButton(
                        context: context,
                        label: 'Register as Technician',
                        color: Colors.black,
                        onTap: () => _navigate(
                          context,
                          const TechnicianRegistrationScreen(),
                        ),
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 32),
                      _buildSignInLink(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme, bool isDesktop) {
    final color = theme.colorScheme.onSurface;
    return Column(
      children: [
        Text(
          'RGS',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HVAC SERVICES',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Not your ordinary HVAC company.',
          style: (isDesktop
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyLarge)
              ?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                isDesktop ? Colors.white.withValues(alpha: 0.75) : color.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDesktop,
    bool isPrimary = false,
  }) {
    if (!isDesktop) {
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final gradient = isPrimary
        ? const LinearGradient(
            colors: [
              Color(0xFF22C55E),
              Color(0xFF15803D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0B1220),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: isPrimary ? 0.0 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
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
            children: const [
              TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign in',
                style: TextStyle(
                  color: Colors.blue,
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
