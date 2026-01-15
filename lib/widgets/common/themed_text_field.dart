import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_theme.dart';

/// ChatGPT-style themed text field
/// Automatically applies the global theme styling
/// 
/// Usage:
/// ```dart
/// ThemedTextField(
///   controller: _controller,
///   label: 'Email Address',
///   hint: 'Enter your email',
///   prefixIcon: Icons.email,
/// )
/// 
/// // With validation
/// ThemedTextField(
///   controller: _controller,
///   label: 'Password',
///   obscureText: true,
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class ThemedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final String? helperText;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const ThemedTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.helperText,
    this.errorText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 52)
            : null,
        suffixIcon: suffixIcon,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }
}

/// ChatGPT-style text form field with label
/// Provides consistent spacing and styling
class ThemedLabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ThemedLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8), // ChatGPT-style: 8px small gap
          child,
        ],
      ),
    );
  }
}
