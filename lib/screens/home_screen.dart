import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'assign_tool_screen.dart';
import 'checkin_screen.dart';
import 'permanent_assignment_screen.dart';
import 'bulk_import_screen.dart';
import 'maintenance_screen.dart';
import 'cost_analytics_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'advanced_search_screen.dart';
import 'compliance_screen.dart';
import 'approval_workflows_screen.dart';
import '../widgets/common/rgs_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab),
      const ToolsScreen(),
      const TechniciansScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        toolbarHeight: 80, // Increased height to fit the slogan
        title: const RGSLogo(),
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
                  if (value == 'logout') {
                    try {
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
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
                              authProvider.userFullName ?? 'User',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              authProvider.userEmail ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
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
            icon: Icon(Icons.people),
            label: 'Technicians',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddToolScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  
  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
      builder: (context, toolProvider, technicianProvider, child) {
        final tools = toolProvider.tools;
        final technicians = technicianProvider.technicians;
        
        final totalTools = tools.length;
        final availableTools = tools.where((t) => t.status == 'Available').length;
        final inUseTools = tools.where((t) => t.status == 'In Use').length;
        final maintenanceTools = tools.where((t) => t.status == 'Maintenance').length;
        final totalValue = toolProvider.getTotalValue();
        final toolsNeedingMaintenance = toolProvider.getToolsNeedingMaintenance();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'RGS tools Overview',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
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
                childAspectRatio: 1.3, // Increased to give more space for text
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
                    () => onNavigateToTab(2), // Navigate to Technicians tab
                  ),
                  _buildStatCard(
                    'Total Value',
                    'AED ${totalValue.toStringAsFixed(0)}',
                    Icons.attach_money, // Will be replaced with custom icon
                    Colors.orange,
                    context,
                    () => onNavigateToTab(3), // Navigate to Reports tab
                  ),
                  _buildStatCard(
                    'Need Maintenance',
                    toolsNeedingMaintenance.toString(),
                    Icons.warning,
                    Colors.red,
                    context,
                    () => onNavigateToTab(1), // Navigate to Tools tab (can filter by maintenance)
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Status Overview
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Tool Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                color: Theme.of(context).cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatusRow('Available', availableTools, AppTheme.statusAvailable),
                      _buildStatusRow('In Use', inUseTools, AppTheme.statusInUse),
                      _buildStatusRow('Maintenance', maintenanceTools, AppTheme.statusMaintenance),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Quick Actions
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Assign Tool',
                      Icons.person_add,
                      AppTheme.primaryColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssignToolScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Return Tool',
                      Icons.assignment_return,
                      AppTheme.secondaryColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckinScreen(),
                          ),
                        );
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
                      'Add Tool',
                      Icons.add,
                      AppTheme.accentColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddToolScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Technician',
                      Icons.person_add,
                      AppTheme.successColor,
                      () {
                        // Navigate to add technician
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
                      'Bulk Import',
                      Icons.upload_file,
                      AppTheme.warningColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BulkImportScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Cost Analytics',
                      Icons.analytics,
                      AppTheme.accentColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CostAnalyticsScreen(),
                          ),
                        );
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
                      'Favorites',
                      Icons.favorite,
                      AppTheme.errorColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Search',
                      Icons.search,
                      AppTheme.accentColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdvancedSearchScreen(),
                          ),
                        );
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
                      'Maintenance',
                      Icons.build,
                      AppTheme.warningColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaintenanceScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Compliance',
                      Icons.verified_user,
                      AppTheme.successColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComplianceScreen(),
                          ),
                        );
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
                      'Approvals',
                      Icons.approval,
                      AppTheme.primaryColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApprovalWorkflowsScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Settings',
                      Icons.settings,
                      AppTheme.textSecondary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Recent Tools
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Recent Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                color: Theme.of(context).cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: tools.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.build,
                                  size: 48,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tools added yet',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap "Add Tool" to get started',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: tools.take(5).map((tool) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(tool.status),
                                child: Icon(
                                  Icons.build,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                tool.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              subtitle: Text(
                                '${tool.category} • ${tool.brand ?? 'Unknown'}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              trailing: Chip(
                                label: Text(
                                  tool.status,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(tool.status),
                              ),
                            );
                          }).toList(),
                        ),
                ),
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
      child: Card(
        color: Theme.of(context).cardTheme.color,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Dirham icon for Total Value, regular icon for others
              title == 'Total Value' 
                ? _buildDirhamIcon(color)
                : Icon(icon, size: 24, color: color),
              SizedBox(height: 6),
              // Value text with responsive sizing
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4),
              // Title with responsive sizing and proper overflow handling
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirhamIcon(Color color) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: DirhamIconPainter(color),
      ),
    );
  }

  Widget _buildStatusRow(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap, BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'In Use':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      case 'Retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

}

class DirhamIconPainter extends CustomPainter {
  final Color color;

  DirhamIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.3;

    // Draw the letter D
    // Left vertical line
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX - radius, centerY + radius),
      paint,
    );

    // Top horizontal line
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX + radius * 0.3, centerY - radius),
      paint,
    );

    // Bottom horizontal line
    canvas.drawLine(
      Offset(centerX - radius, centerY + radius),
      Offset(centerX + radius * 0.3, centerY + radius),
      paint,
    );

    // Curved part of D
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX - radius, centerY), radius: radius),
      -1.57, // -90 degrees
      3.14, // 180 degrees
      false,
      paint,
    );

    // Draw two vertical lines crossing the D (Dirham symbol)
    
    // First vertical line
    canvas.drawLine(
      Offset(centerX - radius * 0.2, centerY - radius),
      Offset(centerX - radius * 0.2, centerY + radius),
      paint,
    );

    // Second vertical line
    canvas.drawLine(
      Offset(centerX + radius * 0.2, centerY - radius),
      Offset(centerX + radius * 0.2, centerY + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

