import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveHelper {
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => !isWeb;
  
  static double getMaxWidth(BuildContext context) {
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Use full width; cap only on very wide displays for readability
      return screenWidth > 1920 ? 1920 : screenWidth;
    }
    return double.infinity;
  }
  
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isWeb) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(16);
  }
  
  static double getCardBorderRadius(BuildContext context) {
    if (isWeb) {
      return 12; // Apple/Jobber-style: slightly rounded, clean web look
    }
    return 16;
  }
  
  static int getGridCrossAxisCount(BuildContext context) {
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 1200) return 4;
      if (screenWidth > 900) return 3;
      if (screenWidth > 600) return 2;
      return 1;
    }
    return 2; // Mobile default
  }
  
  static double getStatCardWidth(BuildContext context) {
    if (isWeb) {
      return 200; // Fixed width for web
    }
    return double.infinity; // Full width on mobile
  }

  // Responsive text sizing that respects text scaling
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Base scaling
    double scale = 1.0;
    
    // Adjust for screen size
    if (screenWidth < 360) {
      scale = 0.85; // Small phones
    } else if (screenWidth < 400) {
      scale = 0.9;
    } else if (screenWidth > 600) {
      scale = 1.1; // Tablets
    }
    
    // Apply text scale factor (respects user accessibility settings)
    // But cap it to prevent excessive scaling
    final textScaleFactor = textScaler.scale(1.0);
    final cappedScaleFactor = textScaleFactor.clamp(0.8, 1.3);
    
    return (baseSize * scale * cappedScaleFactor).clamp(10.0, 32.0);
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    
    double scale = 1.0;
    if (screenWidth < 360) {
      scale = 0.85;
    } else if (screenWidth > 600) {
      scale = 1.15;
    }
    
    // Slightly adjust spacing based on text scale
    final textScaleFactor = textScaler.scale(1.0);
    final adjustedScale = scale * textScaleFactor.clamp(0.9, 1.2);
    
    return baseSpacing * adjustedScale;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scale = 1.0;
    
    if (screenWidth < 360) {
      scale = 0.8; // Compact phones
    } else if (screenWidth > 600) {
      scale = 1.2; // Tablets
    }
    
    if (all != null) {
      final value = all * scale;
      return EdgeInsets.all(value);
    }
    
    return EdgeInsets.symmetric(
      horizontal: (horizontal ?? 16) * scale,
      vertical: (vertical ?? 16) * scale,
    );
  }

  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    
    double scale = 1.0;
    if (screenWidth < 360) {
      scale = 0.9;
    } else if (screenWidth > 600) {
      scale = 1.1;
    }
    
    final textScaleFactor = textScaler.scale(1.0);
    return baseSize * scale * textScaleFactor.clamp(0.9, 1.2);
  }

  // Responsive grid aspect ratio
  static double getResponsiveAspectRatio(BuildContext context, double baseRatio) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    
    // Adjust for screen size
    double adjustment = 0.0;
    if (screenWidth < 360) {
      adjustment = 0.05; // Slightly taller cards on small screens
    } else if (screenWidth > 600) {
      adjustment = -0.05; // Slightly wider cards on tablets
    }
    
    // Adjust for text scaling (taller cards if text is larger)
    final textScaleFactor = textScaler.scale(1.0);
    final textAdjustment = (textScaleFactor - 1.0) * 0.1;
    
    return (baseRatio + adjustment + textAdjustment).clamp(0.5, 0.9);
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseRadius * 0.9; // Slightly smaller on small screens
    } else if (screenWidth > 600) {
      return baseRadius * 1.1; // Slightly larger on tablets
    }
    
    return baseRadius;
  }

  // Check if device is small
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  // Check if device is large (tablet)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  // Check if device is desktop (wide enough for sidebar layout)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Get responsive grid spacing
  static double getResponsiveGridSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseSpacing * 0.8;
    } else if (screenWidth > 600) {
      return baseSpacing * 1.2;
    }
    
    return baseSpacing;
  }

  // Responsive button padding
  static EdgeInsets getResponsiveButtonPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0).clamp(0.9, 1.2);
    
    double horizontal = 24;
    double vertical = 12;
    
    if (screenWidth < 360) {
      horizontal = 16;
      vertical = 10;
    } else if (screenWidth > 600) {
      horizontal = 32;
      vertical = 14;
    }
    
    return EdgeInsets.symmetric(
      horizontal: horizontal * textScaleFactor,
      vertical: vertical * textScaleFactor,
    );
  }

  // Responsive card height (for stat cards)
  static double getResponsiveCardHeight(BuildContext context, double baseHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0).clamp(0.9, 1.2);
    
    double scale = 1.0;
    if (screenWidth < 360) {
      scale = 0.9;
    } else if (screenWidth > 600) {
      scale = 1.1;
    }
    
    return baseHeight * scale * textScaleFactor;
  }

  // Get responsive container constraints for dialogs
  static BoxConstraints getResponsiveDialogConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenWidth < 600) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.9,
      );
    } else {
      return BoxConstraints(
        maxWidth: 600,
        maxHeight: screenHeight * 0.9,
      );
    }
  }

  // Responsive list item height
  static double getResponsiveListItemHeight(BuildContext context, double baseHeight) {
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0).clamp(0.9, 1.3);
    return baseHeight * textScaleFactor;
  }

  // Get responsive column count for filter chips/tabs
  static int getResponsiveColumnCount(BuildContext context, int baseCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseCount > 2 ? 2 : baseCount;
    } else if (screenWidth < 600) {
      return baseCount;
    } else {
      return baseCount + 1; // Allow more columns on larger screens
    }
  }

  // Responsive header height
  static double getResponsiveHeaderHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(1.0).clamp(0.9, 1.2);
    
    double baseHeight = 60;
    if (screenWidth < 360) {
      baseHeight = 56;
    } else if (screenWidth > 600) {
      baseHeight = 64;
    }
    
    return baseHeight * textScaleFactor;
  }
}








