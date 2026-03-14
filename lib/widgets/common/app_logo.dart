import 'package:flutter/material.dart';

/// App logo widget - displays the logo image based on current theme.
class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 48});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark
          ? 'assets/images/logo_dark.png'
          : 'assets/images/logo_light.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
