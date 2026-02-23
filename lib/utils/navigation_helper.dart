import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Helper class for safe navigation operations
class NavigationHelper {
  /// Safely pops the current route if possible
  /// Returns true if popped, false if there's no route to pop
  static bool safePop(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
      return true;
    }
    return false;
  }

  /// Safely pops the current route, or navigates to a fallback route if no route to pop
  static void safePopOrNavigate(
    BuildContext context,
    Widget fallbackScreen, {
    String? fallbackRouteName,
  }) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // No route to pop, navigate to fallback
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => fallbackScreen,
          settings: RouteSettings(name: fallbackRouteName),
        ),
      );
    }
  }

  /// Safely pops until a specific route condition is met
  static void safePopUntil(BuildContext context, bool Function(Route<dynamic>) predicate) {
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, predicate);
    }
  }

  /// Checks if navigation is possible before popping
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}



