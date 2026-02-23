import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// Premium themed card widget with scale-on-press micro-interaction
/// Automatically applies the global theme styling
///
/// Usage:
/// ```dart
/// ThemedCard(
///   child: Text('Content'),
/// )
///
/// // With tap handler (adds scale animation)
/// ThemedCard(
///   onTap: () => Navigator.push(...),
///   child: Column(...),
/// )
/// ```
class ThemedCard extends StatefulWidget {
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
  State<ThemedCard> createState() => _ThemedCardState();
}

class _ThemedCardState extends State<ThemedCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;

  @override
  void initState() {
    super.initState();
    if (widget.onTap != null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 120),
      );
      _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller?.forward();
  void _onTapUp(TapUpDetails _) => _controller?.reverse();
  void _onTapCancel() => _controller?.reverse();

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius ?? 16);
    final decoration = BoxDecoration(
      color: widget.color ?? context.cardBackground,
      borderRadius: borderRadius,
      border: Border.all(color: context.cardBorder, width: 1),
      boxShadow: context.cardShadows,
    );

    Widget content = Container(
      decoration: decoration,
      padding: widget.padding,
      margin: widget.margin,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale!,
          builder: (context, child) => Transform.scale(
            scale: _scale!.value,
            child: child,
          ),
          child: content,
        ),
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
        color: color ?? context.cardBackground,
        borderRadius: BorderRadius.circular(radius ?? 16),
        border: Border.all(color: context.cardBorder, width: 1),
        boxShadow: context.cardShadows,
      ),
      child: child,
    );
  }
}
