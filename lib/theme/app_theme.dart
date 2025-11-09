import 'package:flutter/material.dart';

/// Centralized theme configuration for RGS TOOLS
/// Follows user preferences for white background and black text
class AppTheme {
  // Color palette - Inspired by modern gradient design
  static const Color primaryColor = Color(0xFF2563EB); // Vibrant medium-dark blue
  static const Color secondaryColor = Colors.green;
  static const Color accentColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.amber;
  static const Color successColor = Colors.green;
  
  // Gradient background colors - Light palette
  static const Color gradientStart = Color(0xFFE8F0FE); // Light lavender-blue
  static const Color gradientEnd = Color(0xFFF0F4F8); // Light gray-blue
  static const Color cardGradientStart = Color(0xFFF5FCFB); // Very light green-tinted (from main gradient)
  static const Color cardGradientEnd = Color(0xFFFFFFFF); // White

  // Gradient background colors - Dark palette
  static const Color darkGradientStart = Color(0xFF050505); // Near black
  static const Color darkGradientEnd = Color(0xFF0F0F0F); // Charcoal black
  static const Color darkCardGradientStart = Color(0xFF121212); // Subtle dark gray
  static const Color darkCardGradientEnd = Color(0xFF080808); // Deep black
  
  // Background colors (for dark theme)
  static const Color backgroundColor = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF1A1A1A);
  
  // Gradient helper
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
  
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardGradientStart, cardGradientEnd],
  );

  static LinearGradient backgroundGradientFor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkGradientStart, darkGradientEnd],
          )
        : backgroundGradient;
  }

  static LinearGradient cardGradientFor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCardGradientStart, darkCardGradientEnd],
          )
        : cardGradient;
  }

  static Color cardSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkCardGradientStart : cardGradientStart;
  }

  static Color elevatedSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white;
  }
  
  // Text colors (user preference: white text)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color textHint = Colors.grey;
  
  // Status colors
  static const Color statusAvailable = Colors.green;
  static const Color statusInUse = Colors.blue;
  static const Color statusMaintenance = Colors.orange;
  static const Color statusRetired = Colors.grey;
  
  // Condition colors
  static const Color conditionExcellent = Colors.green;
  static const Color conditionGood = Colors.blue;
  static const Color conditionFair = Colors.orange;
  static const Color conditionPoor = Colors.red;
  static const Color conditionNeedsRepair = Colors.red;

  /// Light theme with white background and dark text
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.grey,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
        bodySmall: TextStyle(color: Colors.grey, fontSize: 12),
        labelLarge: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8B949E)), // Subtle gray labels
        hintStyle: const TextStyle(color: Color(0xFF8B949E)), // Subtle gray hints
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        labelStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Dark theme for professional appearance
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF0D1117), // Much darker surface
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFF0F6FC), // Slightly off-white for better contrast
        onError: Colors.white,
      ),
      
      // Scaffold background - Will use gradient via Container decoration
      scaffoldBackgroundColor: gradientStart, // Base color for gradient
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000), // Pure black
        foregroundColor: Color(0xFFF0F6FC), // Slightly off-white
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F6FC),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22), // Darker card background
        elevation: 8, // Higher elevation for better depth
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF21262D), width: 1), // Subtle border
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFFF0F6FC), fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFFF0F6FC), fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFFF0F6FC), fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Color(0xFFF0F6FC), fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFFF0F6FC), fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Color(0xFFF0F6FC), fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFF0F6FC), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF8B949E), fontSize: 12), // Subtle gray for secondary text
        labelLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Color(0xFF8B949E), fontSize: 10, fontWeight: FontWeight.w500),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161B22), // Darker input background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF21262D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF21262D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8B949E)), // Subtle gray labels
        hintStyle: const TextStyle(color: Color(0xFF8B949E)), // Subtle gray hints
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF000000), // Pure black
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF8B949E), // Subtle gray for unselected
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF161B22), // Darker chip background
        labelStyle: const TextStyle(color: Color(0xFFF0F6FC)), // Off-white text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF21262D), width: 1), // Subtle border
        ),
      ),
    );
  }
  
  /// Get status color for tools
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return statusAvailable;
      case 'in use':
        return statusInUse;
      case 'maintenance':
        return statusMaintenance;
      case 'retired':
        return statusRetired;
      default:
        return textSecondary;
    }
  }
  
  /// Get condition color for tools
  static Color getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return conditionExcellent;
      case 'good':
        return conditionGood;
      case 'fair':
        return conditionFair;
      case 'poor':
        return conditionPoor;
      case 'needs repair':
        return conditionNeedsRepair;
      default:
        return textSecondary;
    }
  }
  
  /// Get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return errorColor;
      case 'medium':
        return warningColor;
      case 'low':
        return successColor;
      default:
        return textSecondary;
    }
  }

  // Static text styles for easy access (will be overridden by theme)
  static const TextStyle heading1 = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle heading3 = TextStyle(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );

  static const TextStyle bodySmall = TextStyle(
    color: Colors.grey,
    fontSize: 12,
  );
}
