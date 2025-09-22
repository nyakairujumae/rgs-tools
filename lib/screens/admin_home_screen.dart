import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'assign_tool_screen.dart';
import 'checkout_screen.dart';
import 'checkin_screen.dart';
import 'reports_screen.dart';
import 'permanent_assignment_screen.dart';
import 'bulk_import_screen.dart';
import 'maintenance_screen.dart';
import 'cost_analytics_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'advanced_search_screen.dart';
import 'compliance_screen.dart';
import 'approval_workflows_screen.dart';
import 'shared_tools_screen.dart';
import 'admin_role_management_screen.dart';
import 'tool_issues_screen.dart';
import '../widgets/common/rgs_logo.dart';

class AdminHomeScreen extends StatefulWidget {
  final int initialTab;
  
  const AdminHomeScreen({super.key, this.initialTab = 0});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class AdminHomeScreenErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const AdminHomeScreenErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          debugPrint('❌ AdminHomeScreen Error: $e');
          debugPrint('📍 Stack trace: $stackTrace');
          
          return Scaffold(
            appBar: AppBar(
              title: Text('Admin Dashboard'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Please try logging out and back in'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.signOut();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        });
                      } catch (e) {
                        debugPrint('Error in error boundary logout: $e');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        });
                      }
                    },
                    child: Text('Logout & Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _selectedIndex;
  bool _isDisposed = false;

  final List<Widget> _screens = [
    DashboardScreen(onNavigateToTab: _navigateToScreen),
    const ToolsScreen(),
    const SharedToolsScreen(),
    const TechniciansScreen(),
    const ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
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
        leading: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.themeIcon,
                color: themeProvider.themeColor,
              ),
              onPressed: () => _showThemeDialog(context, themeProvider),
              tooltip: 'Change Theme',
            );
          },
        ),
        actions: [
          // Settings button
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
            tooltip: 'Settings',
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Builder(
                builder: (context) {
                  return PopupMenuButton<String>(
                icon: Icon(Icons.account_circle),
                onSelected: (value) async {
                  if (value == 'logout' && !_isDisposed && mounted) {
                    try {
                      debugPrint('🚪 Starting logout process...');
                      // Close any open popup menus first (safely)
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      
                      // Simply sign out - let the app handle navigation naturally
                      await authProvider.signOut();
                      debugPrint('✅ Logout completed - app will handle navigation');
                      
                    } catch (e) {
                      debugPrint('❌ Error during logout: $e');
                      // Still try to sign out even on error
                      try {
                        await authProvider.signOut();
                      } catch (e2) {
                        debugPrint('❌ Error during fallback logout: $e2');
                      }
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
        onTap: (index) => setState(() => _selectedIndex = index),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 1 || _selectedIndex == 2)
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
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).cardTheme.color,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'Full Access Control',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => _navigateToScreen(0),
          ),
          _buildDrawerItem(
            icon: Icons.build,
            title: 'Manage Tools',
            onTap: () => _navigateToScreen(1),
          ),
          _buildDrawerItem(
            icon: Icons.share,
            title: 'Shared Tools',
            onTap: () => _navigateToScreen(2),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Manage Technicians',
            onTap: () => _navigateToScreen(3),
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Reports & Analytics',
            onTap: () => _navigateToScreen(4),
          ),
          Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.upload_file,
            title: 'Bulk Import',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BulkImportScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.build_circle,
            title: 'Maintenance',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MaintenanceScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.attach_money,
            title: 'Cost Analytics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CostAnalyticsScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.favorite,
            title: 'Favorites',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritesScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.search,
            title: 'Advanced Search',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdvancedSearchScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.verified_user,
            title: 'Compliance',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ComplianceScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.approval,
            title: 'Approval Workflows',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ApprovalWorkflowsScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.admin_panel_settings,
            title: 'Manage User Roles',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminRoleManagementScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.report_problem,
            title: 'Tool Issues',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ToolIssuesScreen(),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      onTap: () {
        // Close drawer safely
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
        onTap();
      },
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Light Mode'),
                subtitle: Text('Always use the light theme'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark Mode'),
                subtitle: Text('Always use the dark theme'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('System Default'),
                subtitle: Text('Follow the system setting'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  
  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseToolProvider, SupabaseTechnicianProvider, AuthProvider>(
      builder: (context, toolProvider, technicianProvider, authProvider, child) {
        final tools = toolProvider.tools;
        final technicians = technicianProvider.technicians;
        final totalTools = tools.length;
        final totalValue = toolProvider.getTotalValue();
        final toolsNeedingMaintenance = toolProvider.getToolsNeedingMaintenance();
        final availableTools = toolProvider.getAvailableTools();
        final assignedTools = toolProvider.getAssignedTools();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, ${authProvider.userFullName ?? 'Admin'}!',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                'Manage your HVAC tools and technicians',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Tools',
                    totalTools.toString(),
                    Icons.build,
                    Colors.blue,
                    context,
                    () => onNavigateToTab(1), // Navigate to Tools tab
                  ),
                  _buildStatCard(
                    'Technicians',
                    technicians.length.toString(),
                    Icons.people,
                    Colors.green,
                    context,
                    () => onNavigateToTab(3), // Navigate to Technicians tab
                  ),
                  _buildStatCard(
                    'Total Value',
                    '\$${totalValue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.orange,
                    context,
                    () => onNavigateToTab(4), // Navigate to Reports tab
                  ),
                  _buildStatCard(
                    'Need Maintenance',
                    '${toolsNeedingMaintenance.length}',
                    Icons.warning,
                    Colors.red,
                    context,
                    () => onNavigateToTab(1), // Navigate to Tools tab (can filter by maintenance)
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Status Overview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tool Status Overview',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusItem(
                          'Available',
                          availableTools.length.toString(),
                          Colors.green,
                          context,
                        ),
                        _buildStatusItem(
                          'Assigned',
                          assignedTools.length.toString(),
                          Colors.blue,
                          context,
                        ),
                        _buildStatusItem(
                          'Maintenance',
                          '${toolsNeedingMaintenance.length}',
                          Colors.orange,
                          context,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Tool',
                      Icons.add,
                      AppTheme.primaryColor,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddToolScreen(),
                        ),
                      ),
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Assign Tool',
                      Icons.person_add,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssignToolScreen(),
                        ),
                      ),
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Check In',
                      Icons.keyboard_return,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckinScreen(),
                        ),
                      ),
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Reports',
                      Icons.analytics,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      ),
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Tool Issues',
                      Icons.report_problem,
                      Colors.red,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ToolIssuesScreen(),
                        ),
                      ),
                      context,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatusItem(String status, String count, Color color, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

