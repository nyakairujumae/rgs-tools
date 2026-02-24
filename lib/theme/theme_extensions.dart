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
  
  /// Get ChatGPT-style input decoration
  /// OUTLINED, MODERN, INTERACTIVE - distinct from cards
  /// Automatically adapts to light/dark theme
  InputDecoration get chatGPTInputDecoration {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: cardBackground, // Theme-aware background
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Premium padding
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), // Modern rounded corners
        borderSide: BorderSide(
          color: cardBorder, // Theme-aware border
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppTheme.secondaryColor, // Brand green - strong focus state
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cardBorder, width: 1),
      ),
      hintStyle: TextStyle(
        color: isDark 
            ? Colors.grey[400] 
            : Colors.black54,
      ),
      labelStyle: TextStyle(
        color: isDark 
            ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
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
