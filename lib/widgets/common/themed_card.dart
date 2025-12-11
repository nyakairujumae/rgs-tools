import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// ChatGPT-style themed card widget
/// Automatically applies the global theme styling
/// 
/// Usage:
/// ```dart
/// ThemedCard(
///   child: Text('Content'),
/// )
/// 
/// // With custom padding
/// ThemedCard(
///   padding: EdgeInsets.all(16),
///   child: Column(...),
/// )
/// 
/// // With custom radius (16-20px recommended)
/// ThemedCard(
///   radius: 20,
///   child: ...
/// )
/// ```
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Color? color;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? context.cardBackground, // #F5F5F5
      borderRadius: BorderRadius.circular(radius ?? 16), // ChatGPT-style: 16-20px
      border: Border.all(color: context.cardBorder, width: 1), // #E5E5E5
      boxShadow: context.cardShadows, // Ultra-soft shadow (0.04 opacity)
    );

    Widget content = Container(
      decoration: decoration,
      padding: padding,
      margin: margin,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? 16),
        child: content,
      );
    }

    return content;
  }
}

/// ChatGPT-style container with card decoration
/// Use this instead of Container with hardcoded BoxDecoration
class ThemedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Color? color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const ThemedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.radius,
    this.color,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? context.cardBackground, // #F5F5F5
        borderRadius: BorderRadius.circular(radius ?? 16), // ChatGPT-style: 16-20px
        border: Border.all(color: context.cardBorder, width: 1), // #E5E5E5
        boxShadow: context.cardShadows, // Ultra-soft shadow (0.04 opacity)
      ),
      child: child,
    );
  }
}

