import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/common/themed_button.dart';

class AuthErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const AuthErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Back to Login',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 64),
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.8),
                  ),
                  SizedBox(height: context.spacingLarge),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: context.spacingSmall),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: context.spacingLarge),
                  ThemedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    },
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
