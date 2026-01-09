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
  
  /// Get ChatGPT-style card decoration
  /// Use this for all cards, containers, list tiles, tool widgets, and form surfaces
  /// Premium soft-filled style - subtle border with web-only shadow
  /// Automatically adapts to light/dark theme
  BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardBackground, // Theme-aware background
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getCardBorderRadius(this),
      ),
      border: Border.all(
        color: AppTheme.getCardBorderSubtle(this), // Theme-aware border
        width: ResponsiveHelper.isWeb ? 0.8 : 0.5,
      ),
      boxShadow: ResponsiveHelper.isWeb ? cardShadows : [],
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
  
  /// Get icon button background color (for social login buttons)
  Color get iconButtonBackground => AppTheme.getIconButtonBackground(this);
  
  /// Get secondary text color (for subtle text like "Forgot Password")
  Color get secondaryTextColor => AppTheme.getSecondaryTextColor(this);
}
