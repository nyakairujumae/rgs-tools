import 'package:flutter/material.dart';

class RGSLogo extends StatelessWidget {
  const RGSLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // RGS text - smaller to fit in app bar
    final rgsStyle = TextStyle(
      fontSize: 24, // Primary logo text
      fontWeight: FontWeight.w800,
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
      letterSpacing: 0.5,
    );
    const rgsText = 'RGS';

    // HVAC SERVICES text - smaller to fit in app bar
    final hvacStyle = TextStyle(
      fontSize: 13, // Slightly larger for better legibility
      fontWeight: FontWeight.w500,
      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
      letterSpacing: 0.1,
    );
    const hvacText = 'HVAC SERVICES';

    // Slogan text - italic and smaller
    final sloganStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
          .withOpacity(0.85),
      letterSpacing: 0.1,
    );
    const sloganText = '"Not your ordinary HVAC company"';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(rgsText, style: rgsStyle),
        SizedBox(height: 2), // Small gap between RGS and HVAC SERVICES
        Text(hvacText, style: hvacStyle),
        SizedBox(height: 1), // Minimal gap before slogan
        Text(sloganText, style: sloganStyle),
      ],
    );
  }
}
