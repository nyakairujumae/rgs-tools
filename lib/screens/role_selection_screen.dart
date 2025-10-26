import 'package:flutter/material.dart';
import 'admin_registration_screen.dart';
import 'technician_registration_screen.dart';
import '../widgets/common/rgs_logo.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        toolbarHeight: 80,
        title: const RGSLogo(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Role Selection Buttons - Centered and Simple
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Admin Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminRegistrationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 20),
                    label: const Text('Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(120, 50),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Technician Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TechnicianRegistrationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.build, size: 20),
                    label: const Text('Technician'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(120, 50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
