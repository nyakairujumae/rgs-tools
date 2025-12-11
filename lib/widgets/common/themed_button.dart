import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';

/// ChatGPT-style themed elevated button
/// Automatically applies the global theme styling
/// 
/// Usage:
/// ```dart
/// ThemedButton(
///   onPressed: () {},
///   child: Text('Submit'),
/// )
/// 
/// // With loading state
/// ThemedButton(
///   onPressed: isLoading ? null : _handleSubmit,
///   isLoading: isLoading,
///   child: Text('Submit'),
/// )
/// ```
class ThemedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const ThemedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.backgroundColor,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.secondaryColor, // Green accent
          foregroundColor: Colors.white,
          elevation: 0, // No hard shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : child,
      ),
    );
  }
}

/// ChatGPT-style text button
class ThemedTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? textColor;

  const ThemedTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppTheme.secondaryColor, // Green accent text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: child,
    );
  }
}

/// ChatGPT-style outlined button
class ThemedOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? textColor;

  const ThemedOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppTheme.secondaryColor,
        side: BorderSide(color: borderColor ?? AppTheme.secondaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: child,
    );
  }
}

