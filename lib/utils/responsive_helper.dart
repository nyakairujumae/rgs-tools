import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveHelper {
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => !isWeb;
  
  static double getMaxWidth(BuildContext context) {
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Limit max width on web for better readability
      return screenWidth > 1200 ? 1200 : screenWidth;
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
      return 12;
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
}








