import 'package:flutter/material.dart';
import 'admin_registration_screen.dart';
import 'technician_registration_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Diagonal dots pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: DiagonalDotsPainter(),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Branding Section - Takes up about half the screen
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // RGS Branding - Larger and more prominent
                        Column(
                          children: [
                            Text(
                              'RGS',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'HVAC SERVICES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Not your ordinary HVAC company.',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Role Selection Buttons - Vertical layout with pill shapes
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Admin Button - Green like the "Book Online" button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminRegistrationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28), // Pill shape
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Admin Registration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Technician Button - Black like the "Learn More" button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TechnicianRegistrationScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28), // Pill shape
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Technician Registration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    const double dotSize = 8.0;
    
    // Create many random dots across the upper half
    final int totalDots = 80; // Increased total number of dots
    
    for (int i = 0; i < totalDots; i++) {
      // Generate random positions in upper half
      final double x = (i * 37.0 + (i * 13.0) % 23.0) % size.width;
      final double y = (i * 29.0 + (i * 17.0) % 19.0) % (size.height * 0.5);
      
      // Add some variation to make it more organic
      final double offsetX = (i % 7) * 3.0;
      final double offsetY = (i % 11) * 2.0;
      
      final double finalX = (x + offsetX) % size.width;
      final double finalY = (y + offsetY) % (size.height * 0.5);
      
      canvas.drawCircle(
        Offset(finalX, finalY),
        dotSize / 2,
        paint,
      );
    }
    
    // Add some additional scattered dots for more density
    for (int i = 0; i < 40; i++) {
      final double x = (i * 43.0 + (i * 7.0) % 31.0) % size.width;
      final double y = (i * 31.0 + (i * 19.0) % 23.0) % (size.height * 0.5);
      
      canvas.drawCircle(
        Offset(x, y),
        dotSize / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}