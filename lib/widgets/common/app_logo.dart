import 'package:flutter/material.dart';
import '../../config/app_config.dart';

/// App logo widget - displays app name from config.
/// Replace with image asset when custom logo is provided.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
      letterSpacing: 0.5,
    );
    return Text(AppConfig.appName, style: style);
  }
}
