import 'package:flutter/material.dart';
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
  
  /// Get card border color
  Color get cardBorder => AppTheme.cardBorder;
  
  /// Get soft shadow for cards
  BoxShadow get softShadow => AppTheme.softShadow;
  
  /// Get card shadows list
  List<BoxShadow> get cardShadows => AppTheme.cardShadows;
  
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
  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(borderRadiusLarge),
    border: Border.all(color: cardBorder, width: 1),
    boxShadow: cardShadows,
  );
  
  /// Get ChatGPT-style input decoration
  InputDecoration get chatGPTInputDecoration => InputDecoration(
    filled: true,
    fillColor: cardBackground,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: BorderSide(color: cardBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: BorderSide(color: cardBorder, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

