import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'assign_tool_screen.dart';
import 'shared_tools_screen.dart';
import '../widgets/common/rgs_logo.dart';

class AdminHomeScreen extends StatefulWidget {
  final int initialTab;

  const AdminHomeScreen({super.key, this.initialTab = 0});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _selectedIndex;
  bool _isDisposed = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.clamp(0, 3);
    _screens = [
      const SimpleDashboardScreen(),
      const ToolsScreen(),
      const SharedToolsScreen(),
      const TechniciansScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

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
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading || authProvider.isLoggingOut) {
                return IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: null,
                );
              }

              return Builder(
                builder: (context) {
                  return PopupMenuButton<String>(
                    icon: Icon(Icons.account_circle),
                    onSelected: (value) async {
                      if (value == 'logout' && !_isDisposed && mounted) {
                        try {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                          await authProvider.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          debugPrint('Logout error: $e');
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.grey),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authProvider.userFullName ?? 'Admin User',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Admin',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Settings',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index.clamp(0, 3)),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Shared',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Technicians',
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.add, color: Theme.of(context).textTheme.bodyLarge?.color),
            )
          : null,
    );
  }
}

// Simple Dashboard Screen
class SimpleDashboardScreen extends StatelessWidget {
  const SimpleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Welcome to the HVAC Tools Manager',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolScreen(),
                  ),
                );
              },
              child: Text('Add Tool'),
            ),
          ],
        ),
      ),
    );
  }
}