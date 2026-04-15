import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import 'app_theme.dart';

/// Extension methods for easy theme-aware color access throughout the app
/// 
/// Usage examples:
/// ```dart
/// // In any widget:
/// Container(
///   color: context.scaffoldBackground, // Pure white in light mode
///   child: Card(
///     color: context.cardBackground, // f5f5f5 in light mode
///     child: ...
///   ),
/// )
/// 
/// // For input fields:
/// TextFormField(
///   decoration: InputDecoration(
///     fillColor: context.inputBackground, // White in light mode
///   ),
/// )
/// ```
extension ThemeColorExtension on BuildContext {
  /// Get the scaffold background color (white in light mode, black in dark mode)
  Color get scaffoldBackground => AppTheme.getScaffoldBackground(this);

  /// Get the card background color (f5f5f5 in light mode, dark gray in dark mode)
  Color get cardBackground => AppTheme.getCardBackground(this);

  /// White card fill in light mode, dark card in dark mode
  Color get cardFill => Theme.of(this).brightness == Brightness.dark
      ? AppTheme.getCardBackground(this)
      : Colors.white;

  /// Get the app bar background color (white in light mode, black in dark mode)
  Color get appBarBackground => AppTheme.getAppBarBackground(this);

  /// Get the input field background color (f5f5f5 in light mode, dark in dark mode)
  Color get inputBackground => AppTheme.getInputBackground(this);
  
  /// Get card border color (respects theme)
  Color get cardBorder => AppTheme.getCardBorder(this);
  
  /// Get soft shadow for cards
  BoxShadow get softShadow => AppTheme.getCardShadows(this).first;
  
  /// Get card shadows list
  List<BoxShadow> get cardShadows => AppTheme.getCardShadows(this);
  
  /// Get spacing values
  double get spacingMicro => AppTheme.spacingMicro;
  double get spacingSmall => AppTheme.spacingSmall;
  double get spacingMedium => AppTheme.spacingMedium;
  double get spacingLarge => AppTheme.spacingLarge;
  
  /// Get border radius values
  double get borderRadiusSmall => AppTheme.borderRadiusSmall;
  double get borderRadiusMedium => AppTheme.borderRadiusMedium;
  double get borderRadiusLarge => AppTheme.borderRadiusLarge;
  double get borderRadiusXLarge => AppTheme.borderRadiusXLarge;
  
  /// Premium card decoration — Jobber / ServiceTitan style
  /// Provides visible depth on mobile via shadows, border-driven on web
  /// Automatically adapts to light/dark theme
  BoxDecoration get cardDecoration {
    final isWebPlatform = ResponsiveHelper.isWeb;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getCardBorderRadius(this),
      ),
      border: Border.all(
        color: AppTheme.getCardBorderSubtle(this),
        width: isWebPlatform ? 1.0 : 0.5,
      ),
      boxShadow: [],
    );
  }
  
  /// Web-optimized card decoration – Apple / Jobber style
  BoxDecoration get webCardDecoration {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark
            ? const Color(0xFF38383A)
            : const Color(0xFFE5E5EA),
        width: 1,
      ),
      boxShadow: [],
    );
  }
  
  /// Clean filled input decoration — no outline, slight corner rounding.
  /// Automatically adapts to light/dark theme.
  InputDecoration get chatGPTInputDecoration {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(10);
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;
    final noBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: noBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.secondaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      border: noBorder,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey[500] : Colors.black38,
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
            : const Color(0xFF1A1A1A),
      ),
    );
  }

  /// Solid surface fill matching admin dashboard mobile cards (white / dark).
  Color get dashboardSurfaceFill {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFF141414) : Colors.white;
  }

  /// Soft shadow used on dashboard mobile cards (light mode only).
  List<BoxShadow> get dashboardSurfaceShadows {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    if (isDark) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Rounded card-style surface (filled inputs, tiles, secondary buttons).
  BoxDecoration dashboardSurfaceCardDecoration({double radius = 12}) {
    return BoxDecoration(
      color: dashboardSurfaceFill,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: dashboardSurfaceShadows,
    );
  }

  /// Filled inputs: dashboard card surface, no outline (errors keep a red border).
  InputDecoration dashboardSurfaceInputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? hintStyle,
    TextStyle? labelStyle,
    double borderRadius = 12,
  }) {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    return InputDecoration(
      filled: true,
      fillColor: dashboardSurfaceFill,
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: hintStyle ??
          TextStyle(
            color: isDark ? Colors.grey[500] : Colors.black38,
            fontSize: 14,
          ),
      labelStyle: labelStyle ??
          TextStyle(
            color: isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                : const Color(0xFF1A1A1A),
          ),
    );
  }

  /// Elevated card decoration — for primary/hero cards with more depth
  BoxDecoration get elevatedCardDecoration {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getCardBorderRadius(this),
      ),
      border: Border.all(
        color: AppTheme.getCardBorderSubtle(this),
        width: 0.5,
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  /// Get icon button background color (for social login buttons)
  Color get iconButtonBackground => AppTheme.getIconButtonBackground(this);

  /// Get secondary text color (for subtle text like "Forgot Password")
  Color get secondaryTextColor => AppTheme.getSecondaryTextColor(this);
}

/// Reusable status badge widget — colored pill with icon + text
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusBadgeBackground(status);
    final icon = AppTheme.statusBadgeIcon(status);
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
