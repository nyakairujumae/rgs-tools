import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumFieldStyles {
  static const Color fillColor = Color(0xFFF8F9FB);
  static const Color borderColor = Color(0xFFE5E7EB);

  static TextStyle labelTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle fieldTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hintText,
    Widget? prefixIcon,
    List<Widget>? suffixIcons,
    Widget? suffixIcon,
    String? helperText,
    EdgeInsets? contentPadding,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface;

    Widget? styledSuffix;
    if (suffixIcons != null && suffixIcons.isNotEmpty) {
      styledSuffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: suffixIcons
            .map(
              (icon) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: 18,
                    color: baseColor.withOpacity(0.6),
                  ),
                  child: icon,
                ),
              ),
            )
            .toList(),
      );
    } else if (suffixIcon != null) {
      styledSuffix = IconTheme.merge(
        data: IconThemeData(
          size: 18,
          color: baseColor.withOpacity(0.6),
        ),
        child: suffixIcon,
      );
    }

    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: baseColor.withOpacity(0.45),
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor.withOpacity(0.6),
      ),
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      prefixIcon: prefixIcon == null
          ? null
          : IconTheme.merge(
              data: IconThemeData(
                size: 18,
                color: baseColor.withOpacity(0.5),
              ),
              child: prefixIcon,
            ),
      suffixIcon: styledSuffix,
      helperText: helperText,
      helperStyle: TextStyle(
        fontSize: 12,
        color: baseColor.withOpacity(0.45),
      ),
    );
  }

  static BoxDecoration dropdownContainerDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static InputDecoration dropdownInputDecoration(
    BuildContext context, {
    String? hintText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface.withOpacity(0.45),
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  static Widget dropdownIcon(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Icon(
      Icons.keyboard_arrow_down_rounded,
      size: 20,
      color: color,
    );
  }

  static Widget labeledField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelTextStyle(context)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  static const double fieldSpacing = 16;
}
