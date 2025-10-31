import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import 'technician_add_tool_screen.dart';
import 'technician_home_screen.dart';

class InitialToolSetupScreen extends StatefulWidget {
  const InitialToolSetupScreen({super.key});

  @override
  State<InitialToolSetupScreen> createState() => _InitialToolSetupScreenState();
}

class _InitialToolSetupScreenState extends State<InitialToolSetupScreen> {
  bool _isLoading = true;
  bool _setupCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      // Check if setup was already completed
      final prefs = await SharedPreferences.getInstance();
      final setupKey = 'initial_setup_completed_$userId';
      final completed = prefs.getBool(setupKey) ?? false;
      
      if (completed) {
        // Setup already completed, go to home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TechnicianHomeScreen(),
            ),
          );
        }
        return;
      }
      
      // Also check if they already have tools (someone might have added tools for them)
      final toolProvider = context.read<SupabaseToolProvider>();
      await toolProvider.loadTools();
      
      final userTools = toolProvider.tools.where((tool) => 
        tool.assignedTo == userId || 
        (tool.status == 'In Use' && tool.assignedTo == userId)
      ).toList();
      
      if (userTools.isNotEmpty) {
        // They have tools, mark setup as complete
        await prefs.setBool(setupKey, true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TechnicianHomeScreen(),
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking setup status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _skipSetup() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId != null) {
      // Mark setup as completed even if they skip
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('initial_setup_completed_$userId', true);
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TechnicianHomeScreen(),
        ),
      );
    }
  }

  void _addTools() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TechnicianAddToolScreen(),
      ),
    ).then((_) async {
      // After adding tools, mark setup as completed
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('initial_setup_completed_$userId', true);
      }
      
      // Reload tools to refresh the list
      if (mounted) {
        await context.read<SupabaseToolProvider>().loadTools();
        
        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TechnicianHomeScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              
              SizedBox(height: 32),
              
              // Title
              Text(
                'Setup Your Tools',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                'Do you have tools that you already possess and want to add to the system? This is a one-time setup to help get started.\n\nAfter this initial setup, only administrators can add new tools to the system.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Important',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'This feature is only available during initial setup. After you complete your tool list, only administrators will be able to add new tools.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Add Tools Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addTools,
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Add My Tools'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Skip Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _skipSetup,
                  icon: Icon(Icons.skip_next),
                  label: Text('Skip for Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

