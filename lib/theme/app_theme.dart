  import 'package:flutter/material.dart';

/// Centralized theme configuration for RGS TOOLS
/// Follows user preferences for white background and black text
class AppTheme {
  // Color palette - Inspired by modern gradient design
  static const Color primaryColor =
      Color(0xFF2563EB); // Vibrant medium-dark blue
  static const Color secondaryColor =
      Color(0xFF047857); // Green accent for interactions
  static const Color accentColor =
      Color(0xFF34D399); // Lighter green for states
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.amber;
  static const Color successColor = Colors.green;

  // Neutral surfaces - ChatGPT-style theme
  static const Color appBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFF5F5F5); // Card color for light theme
  static const Color scaffoldBackground = Colors.white; // Pure white background
  static const Color subtleSurface = Color(0xFFF9FAFB);
  static const Color subtleBorder = Color(0xFFE5E5E5); // Very subtle borders
  static const Color cardBorder = Color(0xFFE5E5E5); // Card border color (light mode)
  static const Color darkCardBorder = Color(0xFF21262D); // Card border color (dark mode)
  
  // Spacing constants
  static const double spacingMicro = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  
  // Border radius constants
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 14.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  
  // Shadow constants
  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.08), // Soft shadow for depth
    blurRadius: 12,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  );
  
  static List<BoxShadow> get cardShadows => [softShadow];

  // Gradient background colors - Light palette (retained for legacy widgets)
  static const Color gradientStart = Color(0xFFE8F0FE); // Light lavender-blue
  static const Color gradientEnd = Color(0xFFF0F4F8); // Light gray-blue
  static const Color cardGradientStart = Color(0xFFFFFFFF); // White
  static const Color cardGradientEnd = Color(0xFFFFFFFF); // White

  // Gradient background colors - Dark palette
  static const Color darkGradientStart = Color(0xFF050505); // Near black
  static const Color darkGradientEnd = Color(0xFF0F0F0F); // Charcoal black
  static const Color darkCardGradientStart =
      Color(0xFF121212); // Subtle dark gray
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

  static LinearGradient authBackgroundGradientFor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E2D1A), Color(0xFF05140B)],
        stops: [0.0, 1.0],
      );
    }

    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF81DEAA),
        Color(0xFFDFF7E8),
        Color(0xFFFAFFFB),
      ],
      stops: [0.0, 0.4, 1.0],
    );
  }

  static LinearGradient authCardGradientFor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102719), Color(0xFF07150C)],
            stops: [0.0, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3FFF7), Color(0xFFFFFFFF)],
            stops: [0.0, 1.0],
          );
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
    return brightness == Brightness.dark
        ? darkCardGradientStart
        : cardBackground; // Use f5f5f5 for cards in light mode
  }

  static Color elevatedSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : Colors.white;
  }

  /// Get the scaffold background color (respects theme)
  static Color getScaffoldBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? backgroundColor
        : scaffoldBackground; // Pure white for light mode
  }

  /// Get the card background color (respects theme)
  static Color getCardBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF161B22) // Dark card color
        : cardBackground; // f5f5f5 for light mode
  }

  /// Get the app bar background color (respects theme)
  static Color getAppBarBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF000000) // Pure black for dark mode
        : scaffoldBackground; // Pure white for light mode
  }

  /// Get input field background color (respects theme)
  static Color getInputBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF0D1117)
        : cardBackground; // f5f5f5 input fields in light mode
  }

  /// Get icon button background color (for social login buttons)
  static Color getIconButtonBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF3F3F3);
  }

  /// Get secondary text color (for subtle text like "Forgot Password")
  static Color getSecondaryTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey[300]!
        : Colors.grey[600]!;
  }

  /// Get card border color (respects theme)
  static Color getCardBorder(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? darkCardBorder
        : cardBorder;
  }

  /// Get card border color for subtle borders (respects theme)
  static Color getCardBorderSubtle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.04);
  }

  // Text colors - ChatGPT-style light theme
  static const Color textPrimary = Color(0xFF1A1A1A); // Dark grey-black, not pure black
  static const Color textSecondary = Color.fromRGBO(0, 0, 0, 0.6); // rgba(0,0,0,0.6)
  static const Color textHint = Color.fromRGBO(0, 0, 0, 0.4);
  static const Color dividerColor = Color(0xFFE0E0E0); // Divider color

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
        surface: appBackground,
        background: appBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: scaffoldBackground, // Pure white background
      hoverColor: secondaryColor.withValues(alpha: 0.08),
      focusColor: secondaryColor.withValues(alpha: 0.12),
      splashColor: secondaryColor.withValues(alpha: 0.12),
      highlightColor: secondaryColor.withValues(alpha: 0.1),

      // AppBar theme - ChatGPT-style
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground, // Pure white
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Color.fromRGBO(0, 0, 0, 0.04), // rgba(0,0,0,0.04)
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme - ChatGPT style (SOFT-FILLED, NO OUTLINES)
      cardTheme: CardThemeData(
        color: cardBackground, // #F5F5F5 for cards
        elevation: 0, // No elevation/shadow
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // Premium rounded corners
          // Subtle border for lifted effect
          side: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      // Text theme - ChatGPT-style colors
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
        bodySmall: TextStyle(color: Color.fromRGBO(0, 0, 0, 0.6), fontSize: 12),
        labelLarge: TextStyle(
            color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(
            color: Color.fromRGBO(0, 0, 0, 0.6), fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            color: Color.fromRGBO(0, 0, 0, 0.6), fontSize: 10, fontWeight: FontWeight.w500),
      ),

      // Input decoration theme - ChatGPT style (OUTLINED, MODERN, INTERACTIVE)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground, // #F5F5F5 input field background
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Premium padding
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Modern rounded corners
          borderSide: const BorderSide(
            color: cardBorder, // #E5E5E5 - soft border
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: secondaryColor, // Brand green - strong focus state
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        labelStyle: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w400),
        prefixIconColor: Colors.grey[600],
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF4B5563),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          backgroundColor: cardBackground,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Button themes - ChatGPT style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor, // Green accent
          foregroundColor: Colors.white,
          elevation: 0, // No hard shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
          ),
          padding: const EdgeInsets.symmetric(vertical: 14), // ChatGPT-style button padding
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor, // Green accent text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // ChatGPT-style: 14px radius
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: secondaryColor, // Green for selected
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        labelStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: secondaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: secondaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        overlayColor: MaterialStatePropertyAll(
          secondaryColor.withValues(alpha: 0.12),
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
        onSurface:
            const Color(0xFFF0F6FC), // Slightly off-white for better contrast
        onError: Colors.white,
      ),
      hoverColor: secondaryColor.withValues(alpha: 0.16),
      focusColor: secondaryColor.withValues(alpha: 0.22),
      splashColor: secondaryColor.withValues(alpha: 0.2),
      highlightColor: secondaryColor.withValues(alpha: 0.18),

      // Scaffold background - Dark background for dark theme
      scaffoldBackgroundColor: backgroundColor, // Pure black for dark theme

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
          side: const BorderSide(
              color: Color(0xFF21262D), width: 1), // Subtle border
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 32,
            fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 24,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 22,
            fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 20,
            fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 18,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 16,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 12,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFFF0F6FC), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFF0F6FC), fontSize: 14),
        bodySmall: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 12), // Subtle gray for secondary text
        labelLarge: TextStyle(
            color: Color(0xFFF0F6FC),
            fontSize: 14,
            fontWeight: FontWeight.w500),
        labelMedium: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 12,
            fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 10,
            fontWeight: FontWeight.w500),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D333B), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D333B), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        labelStyle: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 13,
            fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(
            color: Color(0xFF6E7681),
            fontSize: 12.5,
            fontWeight: FontWeight.w400),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF9BA1A6),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          backgroundColor: Color(0xFF0D1117),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF000000), // Pure black
        selectedItemColor: secondaryColor,
        unselectedItemColor:
            const Color(0xFF8B949E), // Subtle gray for unselected
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF161B22), // Darker chip background
        labelStyle: const TextStyle(color: Color(0xFFF0F6FC)), // Off-white text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
              color: Color(0xFF21262D), width: 1), // Subtle border
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: secondaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: secondaryColor,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        overlayColor: MaterialStatePropertyAll(
          secondaryColor.withValues(alpha: 0.2),
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
