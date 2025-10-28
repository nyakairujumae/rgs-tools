import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import 'shared_tools_screen.dart';
import 'checkin_screen.dart';
import 'web/checkin_screen_web.dart';
import 'add_tool_issue_screen.dart';
import 'add_tool_screen.dart';
import '../models/tool.dart';
import '../widgets/common/rgs_logo.dart';

// Request Tool Screen
class RequestToolScreen extends StatelessWidget {
  const RequestToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Tool'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Request New Tool',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Need a new tool? Submit your request here.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolScreen(),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Submit Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Report Issue Screen
class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Issue'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem_outlined,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Report an Issue',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Found a problem? Report it here for quick resolution.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolIssueScreen(),
                  ),
                );
              },
              icon: Icon(Icons.report_problem),
              label: Text('Report Issue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _selectedIndex = 0;
  bool _isDisposed = false;

  List<Widget> get _screens => [
    TechnicianDashboardScreen(
      key: ValueKey('tech_dashboard_${DateTime.now().millisecondsSinceEpoch}'),
      onNavigateToTab: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
    const RequestToolScreen(),
    const ReportIssueScreen(),
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const RGSLogo(),
        ),
        centerTitle: true,
        actions: [
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
                      
                      // Sign out and navigate to login
                      await authProvider.signOut();
                      
                      // Navigate to login screen
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                          (route) => false,
                        );
                      }
                      
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
        onTap: (index) => setState(() => _selectedIndex = index.clamp(0, 2)),
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
            icon: Icon(Icons.add),
            label: 'Request Tool',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Issue',
          ),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget _getFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => kIsWeb ? const CheckinScreenWeb() : const CheckinScreen(),
          ),
        );
      },
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      icon: Icon(Icons.keyboard_return),
      label: Text('Check In/Out'),
    );
  }
}

// Technician Dashboard Screen
class TechnicianDashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const TechnicianDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  void _navigateToTab(int index, BuildContext context) {
    onNavigateToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseToolProvider, AuthProvider, SupabaseTechnicianProvider>(
      builder: (context, toolProvider, authProvider, technicianProvider, child) {
        // Debug logging first
        print('🔍 Dashboard - Total tools: ${toolProvider.tools.length}');
        print('🔍 Dashboard - User ID: ${authProvider.user?.id}');
        print('🔍 Dashboard - User Email: ${authProvider.user?.email}');
        
        // Check all tools and their assignedTo values
        for (var tool in toolProvider.tools) {
          print('🔍 Tool: ${tool.name} - AssignedTo: ${tool.assignedTo} - ToolType: ${tool.toolType}');
        }
        
        final myTools = toolProvider.tools.where((tool) => tool.assignedTo == authProvider.user?.id).toList();
        final availableSharedTools = toolProvider.tools.where((tool) => tool.toolType == 'shared' && tool.status == 'Available').toList();

        // Fallback: If no tools are found with current logic, show all tools for debugging
        final displayMyTools = myTools.isNotEmpty ? myTools : toolProvider.tools.take(3).toList();
        final displaySharedTools = availableSharedTools.isNotEmpty ? availableSharedTools : toolProvider.tools.where((tool) => tool.status == 'Available').take(3).toList();
        
        print('🔍 Dashboard - Display My tools: ${displayMyTools.length}');
        print('🔍 Dashboard - Display Shared tools: ${displaySharedTools.length}');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
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
                          SizedBox(height: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Manage your tools and access shared resources',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Shared Tools Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shared Tools',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigateToTab(1, context),
                    child: Text(
                      'See All >',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Shared Tools Horizontal Scroll
              SizedBox(
                height: 200,
                child: availableSharedTools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No shared tools available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displaySharedTools.length,
                        itemBuilder: (context, index) {
                          final tool = displaySharedTools[index];
                          return Container(
                            width: 160,
                            margin: EdgeInsets.only(right: 12),
                            child: _buildToolCard(tool, context),
                          );
                        },
                      ),
              ),

              SizedBox(height: 32),

              // My Tools Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Tools',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigateToTab(2, context),
                    child: Text(
                      'See All >',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // My Tools Vertical List
              displayMyTools.isEmpty
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No tools assigned',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Contact your supervisor',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: displayMyTools.length,
                      itemBuilder: (context, index) {
                        final tool = displayMyTools[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: _buildToolCard(tool, context),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolCard(Tool tool, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/tool-detail',
          arguments: tool,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tool Image - Left Side (Full Height)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                color: Colors.grey[200],
              ),
              child: tool.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                      child: tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.build,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                );
                              },
                            )
                          : File(tool.imagePath!).existsSync()
                              ? Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.build,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.build,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
            ),
            
            // Tool Details - Right Side
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Top Section - Name and Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          tool.toolType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Bottom Section - Status and Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(tool.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tool.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(tool.status),
                            ),
                          ),
                        ),
                        
                        // Location/Type Info
                        if (tool.location != null && tool.location!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  tool.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in use':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      case 'out of service':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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
