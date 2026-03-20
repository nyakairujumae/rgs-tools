import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/organization_provider.dart';

/// App logo widget — shows org logo image if uploaded, otherwise app name text.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final logoUrl = context.watch<OrganizationProvider>().logoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackText(context),
        ),
      );
    }

    return _fallbackText(context);
  }

  Widget _fallbackText(BuildContext context) {
    return Text(
      AppConfig.appName,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }
}
