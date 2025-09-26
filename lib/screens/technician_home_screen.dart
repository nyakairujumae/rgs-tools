import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import 'shared_tools_screen.dart';
import 'assign_tool_screen.dart';
import 'checkout_screen.dart';
import 'checkin_screen.dart';
import 'tool_detail_screen.dart';
import 'settings_screen.dart';
import 'add_tool_issue_screen.dart';
import '../models/tool.dart';
import '../widgets/common/rgs_logo.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _selectedIndex = 0;
  bool _isDisposed = false;

  final List<Widget> _screens = [
    const TechnicianDashboardScreen(),
    const SharedToolsScreen(),
    const MyToolsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
              // Don't render PopupMenuButton during logout to prevent widget tree issues
              if (authProvider.isLoading || authProvider.isLoggingOut) {
                return IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: null, // Disabled during logout
                );
              }
              
              return PopupMenuButton<String>(
                icon: Icon(Icons.account_circle),
                onSelected: (value) async {
                  if (value == 'logout' && !_isDisposed && mounted) {
                    try {
                      // Close any open popup menus first (safely)
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      
                      // Simply sign out - let the app handle navigation naturally
                      await authProvider.signOut();
                      
                    } catch (e) {
                      // Silent error handling - the app will handle navigation
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
                              authProvider.userFullName ?? 'Technician',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Technician',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: 'Shared Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'My Tools',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckinScreen(),
                  ),
                );
              },
              backgroundColor: Colors.green,
              child: Icon(Icons.keyboard_return, color: Theme.of(context).textTheme.bodyLarge?.color),
            )
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolIssueScreen(),
                  ),
                );
              },
              backgroundColor: Colors.red,
              child: Icon(Icons.report_problem, color: Colors.white),
            ),
    );
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

// Technician Dashboard Screen
class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});

  void _navigateToTab(int index, BuildContext context) {
    final technicianHomeState = context.findAncestorStateOfType<_TechnicianHomeScreenState>();
    technicianHomeState?.setState(() {
      technicianHomeState._selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseToolProvider, AuthProvider>(
      builder: (context, toolProvider, authProvider, child) {
        final tools = toolProvider.tools;
        final userId = authProvider.user?.id;
        
        // Get tools assigned to this technician
        final myTools = tools.where((tool) => tool.assignedTo == userId).toList();
        final availableSharedTools = tools.where((tool) => 
          tool.status == 'Available' && tool.assignedTo == null).toList();

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
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, ${authProvider.userFullName ?? 'Technician'}!',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                'Manage your tools and access shared resources',
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

              // My Tools Overview
              InkWell(
                onTap: () {
                  // Navigate to My Tools tab
                  _navigateToTab(2, context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Assigned Tools',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${myTools.length}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (myTools.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No tools assigned yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Contact your supervisor to get tools assigned',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: myTools.take(3).map((tool) => _buildToolItem(tool, context)).toList(),
                      ),
                    if (myTools.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextButton(
                          onPressed: () {
                            // Navigate to My Tools tab
                            _navigateToTab(2, context);
                          },
                          child: Text(
                            'View All My Tools (${myTools.length})',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ),

              SizedBox(height: 24),

              // Available Shared Tools
              InkWell(
                onTap: () {
                  // Navigate to Shared Tools tab
                  _navigateToTab(1, context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Shared Tools',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${availableSharedTools.length}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (availableSharedTools.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.share,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No shared tools available',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: availableSharedTools.take(3).map((tool) => _buildToolItem(tool, context, isShared: true)).toList(),
                      ),
                    if (availableSharedTools.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextButton(
                          onPressed: () {
                            // Navigate to Shared Tools tab
                            _navigateToTab(1, context);
                          },
                          child: Text(
                            'View All Shared Tools (${availableSharedTools.length})',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                      'Check In Tool',
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
                      'Request Tool',
                      Icons.add_circle,
                      Colors.green,
                      () {
                        // Navigate to Shared Tools tab
                        _navigateToTab(1, context);
                      },
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
                      'Report Issue',
                      Icons.report_problem,
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddToolIssueScreen(),
                          ),
                        );
                      },
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

  Widget _buildToolItem(Tool tool, BuildContext context, {bool isShared = false}) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/tool-detail',
          arguments: tool,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isShared ? Colors.blue.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: tool.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.build,
                                  color: isShared ? Colors.blue : Colors.green,
                                  size: 20,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                );
                              },
                            )
                          : File(tool.imagePath!).existsSync()
                              ? Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.build,
                                      color: isShared ? Colors.blue : Colors.green,
                                      size: 20,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.build,
                                  color: isShared ? Colors.blue : Colors.green,
                                  size: 20,
                                ),
                    )
                  : Icon(
                      Icons.build,
                      color: isShared ? Colors.blue : Colors.green,
                      size: 20,
                    ),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${tool.category} • ${tool.brand ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            status: tool.status,
          ),
        ],
      ),
    ),
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

// My Tools Screen for Technicians
class MyToolsScreen extends StatelessWidget {
  const MyToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseToolProvider, AuthProvider>(
      builder: (context, toolProvider, authProvider, child) {
        final tools = toolProvider.tools;
        final userId = authProvider.user?.id;
        
        // Get tools assigned to this technician
        final myTools = tools.where((tool) => tool.assignedTo == userId).toList();

        if (toolProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        if (myTools.isEmpty) {
          return EmptyState(
            icon: Icons.build_circle_outlined,
            title: 'No Tools Assigned',
            subtitle: 'You don\'t have any tools assigned yet. Contact your supervisor to get tools assigned.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await toolProvider.loadTools();
          },
          color: Colors.green,
          backgroundColor: Theme.of(context).cardTheme.color,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myTools.length,
            itemBuilder: (context, index) {
              final tool = myTools[index];
              return _buildToolCard(tool, context);
            },
          ),
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool, BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tool Image/Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withValues(alpha: 0.2),
                ),
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: tool.imagePath!.startsWith('http')
                            ? Image.network(
                                tool.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.build,
                                    color: Colors.green,
                                    size: 30,
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : File(tool.imagePath!).existsSync()
                                ? Image.file(
                                    File(tool.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.build,
                                        color: Colors.green,
                                        size: 30,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.build,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                      )
                    : Icon(
                        Icons.build,
                        color: Colors.green,
                        size: 30,
                      ),
              ),
              
              SizedBox(width: 16),
              
              // Tool Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${tool.category} • ${tool.brand ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(
                          status: tool.status,
                        ),
                        SizedBox(width: 8),
                        if (tool.currentValue != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'AED ${tool.currentValue!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToolDetailScreen(tool: tool),
                    ),
                  );
                },
                icon: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

