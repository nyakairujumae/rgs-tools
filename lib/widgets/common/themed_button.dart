import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';


/// Premium themed elevated button with scale-on-press micro-interaction
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
class ThemedButton extends StatefulWidget {
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
  State<ThemedButton> createState() => _ThemedButtonState();
}

class _ThemedButtonState extends State<ThemedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (_enabled) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (_enabled) _controller.reverse();
  }

  void _onTapCancel() {
    if (_enabled) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: SizedBox(
          height: widget.height ?? 52,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.backgroundColor ?? AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: widget.padding ??
                  const EdgeInsets.symmetric(vertical: 14),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : widget.child,
          ),
        ),
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
        foregroundColor: textColor ?? AppTheme.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: child,
    );
  }
}
