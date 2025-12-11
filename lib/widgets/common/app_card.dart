import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// Premium ChatGPT-style card widget
/// 
/// A reusable card component that follows the unified design system:
/// - Soft-filled surface (#F5F5F5)
/// - NO borders - pure soft fill
/// - Ultra-soft shadow (0.04 opacity)
/// - 18px default border radius
/// 
/// Usage:
/// ```dart
/// AppCard(
///   padding: EdgeInsets.all(20),
///   child: Column(
///     children: [...],
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final bool enableShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme-based decoration for consistency
    final decoration = context.cardDecoration.copyWith(
      borderRadius: radius != null ? BorderRadius.circular(radius!) : null,
      boxShadow: enableShadow
          ? context.cardShadows
          : [],
    );

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );
  }
}

