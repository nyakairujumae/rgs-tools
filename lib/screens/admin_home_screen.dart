import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/admin_notification_provider.dart';
import 'auth/login_screen.dart';
import 'role_selection_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'checkin_screen.dart';
import 'web/checkin_screen_web.dart';
import 'reports_screen.dart';
import 'report_detail_screen.dart';
import 'permanent_assignment_screen.dart';
import '../services/report_service.dart';
import 'maintenance_screen.dart';
import 'cost_analytics_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'advanced_search_screen.dart';
import 'compliance_screen.dart';
import 'approval_workflows_screen.dart';
import 'shared_tools_screen.dart';
import 'admin_role_management_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_notification_screen.dart';
import 'tool_issues_screen.dart';
import '../widgets/common/rgs_logo.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';

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
          // Handle error silently in production

          return Scaffold(
            appBar: AppBar(
              title: Text('Admin Dashboard'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
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
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        });
                      } catch (e) {
                        // Silent error handling
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
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

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  bool _isDisposed = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex =
        widget.initialTab.clamp(0, 3); // Ensure index is within bounds
    _screens = [
      DashboardScreen(
        key: ValueKey('dashboard_${DateTime.now().millisecondsSinceEpoch}'),
        onNavigateToTab: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        onNavigateToToolsWithFilter: _navigateToToolsWithFilter,
      ),
      const ToolsScreen(),
      const SharedToolsScreen(),
      const TechniciansScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startPeriodicRefresh();
    });
  }

  void _startPeriodicRefresh() {
    // Refresh pending approvals every 30 seconds to catch new registrations
    Future.delayed(Duration(seconds: 30), () {
      if (!_isDisposed && mounted) {
        context.read<PendingApprovalsProvider>().loadPendingApprovals();
        _startPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  Future<void> _loadData() async {
    if (_isDisposed) return;

    try {
      await Future.wait([
        context.read<SupabaseToolProvider>().loadTools(),
        context.read<SupabaseTechnicianProvider>().loadTechnicians(),
        context.read<PendingApprovalsProvider>().loadPendingApprovals(),
      ]);
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      // Reload pending approvals when app comes back to foreground
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: Pending approvals are loaded in initState and refreshed periodically
    // No need to reload on every build to prevent constant refreshing

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Container(
        color: scaffoldColor,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: (_selectedIndex == 1 ||
                  _selectedIndex == 2 ||
                  _selectedIndex == 3)
              ? null
              : AppBar(
                  backgroundColor:
                      isDarkMode ? colorScheme.surface : Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  scrolledUnderElevation: 6,
                  foregroundColor: colorScheme.onSurface,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false, // No drawer menu
                  surfaceTintColor:
                      Colors.transparent, // Remove any tint overlay
                  systemOverlayStyle: null, // Use default system overlay
                  flexibleSpace: _selectedIndex != 0
                      ? Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                        )
                      : null, // Use default for dashboard
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Consumer<AdminNotificationProvider>(
                        builder: (context, notificationProvider, child) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminNotificationScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (notificationProvider.unreadCount > 0)
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '${notificationProvider.unreadCount}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  title: _selectedIndex == 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const RGSLogo(),
                        )
                      : Text(
                          _getTabTitle(_selectedIndex),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                  centerTitle: true,
                  actions: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        // Don't render PopupMenuButton during logout to prevent widget tree issues
                        if (authProvider.isLoading ||
                            authProvider.isLoggingOut) {
                          return IconButton(
                            icon: Icon(Icons.account_circle),
                            onPressed: null, // Disabled during logout
                          );
                        }

                        return Builder(
                          builder: (context) {
                            return PopupMenuButton<String>(
                              icon: Icon(Icons.account_circle),
                              onSelected: (value) async {
                                if (value == 'settings') {
                                  // Navigate to Settings screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsScreen(),
                                    ),
                                  );
                                } else if (value == 'logout' &&
                                    !_isDisposed &&
                                    mounted) {
                                  try {
                                    // Close any open popup menus first (safely)
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                    
                                    // Wait a frame to ensure UI is stable
                                    await Future.delayed(const Duration(milliseconds: 100));

                                    // Sign out and navigate to login
                                    await authProvider.signOut();
                                    
                                    // Wait another frame before navigation
                                    await Future.delayed(const Duration(milliseconds: 100));

                                    // Navigate to login screen
                                    if (mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const RoleSelectionScreen(),
                                          settings: const RouteSettings(name: '/role-selection'),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } catch (e, stackTrace) {
                                    // Silent error handling - the app will handle navigation
                                    debugPrint('Logout error: $e');
                                    debugPrint('Stack trace: $stackTrace');
                                    // Even if there's an error, try to navigate to login
                                    if (mounted) {
                                      try {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RoleSelectionScreen(),
                                            settings: const RouteSettings(name: '/role-selection'),
                                          ),
                                          (route) => false,
                                        );
                                      } catch (navError) {
                                        debugPrint('Navigation error during logout: $navError');
                                      }
                                    }
                                  }
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                              ),
                              elevation: 8,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white,
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'profile',
                                  padding: ResponsiveHelper.getResponsivePadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Container(
                                    padding: ResponsiveHelper.getResponsivePadding(
                                      context,
                                      all: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.surface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            ResponsiveHelper.getResponsiveSpacing(context, 8),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: AppTheme.primaryColor,
                                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                          ),
                                        ),
                                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                authProvider.userFullName ??
                                                    'Admin User',
                                                style: TextStyle(
                                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(
                                                    ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Admin',
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                                    color: AppTheme.secondaryColor,
                                                    fontWeight: FontWeight.w600,
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
                                const PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: 'settings',
                                  padding: ResponsiveHelper.getResponsivePadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          ResponsiveHelper.getResponsiveSpacing(context, 6),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.settings,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                                          size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'logout',
                                  padding: ResponsiveHelper.getResponsivePadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          ResponsiveHelper.getResponsiveSpacing(context, 6),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                          size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
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
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) =>
                  setState(() => _selectedIndex = index.clamp(0, 3)),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.secondary,
              unselectedItemColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
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
                  child: Icon(Icons.add,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                )
              : null,
        ),
      ),
    );
  }

  void _navigateToToolsWithFilter(String statusFilter) {
    setState(() {
      _selectedIndex = 1; // Tools tab
      // Replace the ToolsScreen with a filtered version
      _screens[1] = ToolsScreen(initialStatusFilter: statusFilter);
    });
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return ''; // Will show RGS logo instead
      case 1:
        return 'Tools';
      case 2:
        return 'Shared Tools';
      case 3:
        return 'Technicians';
      default:
        return '';
    }
  }
}

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final Function(String) onNavigateToToolsWithFilter;
  static const double _cardRadiusValue = 20;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onNavigateToToolsWithFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer4<SupabaseToolProvider, SupabaseTechnicianProvider,
        AuthProvider, ConnectivityProvider>(
      builder:
          (context, toolProvider, technicianProvider, authProvider, connectivityProvider, child) {
        final tools = toolProvider.tools;
        final technicians = technicianProvider.technicians;
        final isOffline = !connectivityProvider.isOnline;
        final totalTools = tools.length;
        final totalValue = toolProvider.getTotalValue();
        final toolsNeedingMaintenance =
            toolProvider.getToolsNeedingMaintenance();
        final availableTools = toolProvider.getAvailableTools();
        final assignedTools = toolProvider.getAssignedTools();

        final cardRadius = BorderRadius.circular(_cardRadiusValue);

        // Show offline skeleton when offline and not loading
        if (isOffline && !toolProvider.isLoading && !technicianProvider.isLoading) {
          return OfflineDashboardSkeleton(
            cardCount: 4,
            message: 'You are offline. Showing cached dashboard data.',
          );
        }

        return SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveIconSize(context, 52),
                              height: ResponsiveHelper.getResponsiveIconSize(context, 52),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, _cardRadiusValue)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondaryColor
                                        .withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  color: AppTheme.secondaryColor,
                                  size: ResponsiveHelper.getResponsiveIconSize(context, 26),
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()}, ${_getFirstName(authProvider.userFullName ?? 'Admin')}!',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                  Text(
                                    'Manage your HVAC tools and technicians',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
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

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                  Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        ResponsiveHelper.getGridCrossAxisCount(context),
                    crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
                    mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
                    childAspectRatio: ResponsiveHelper.isWeb ? 1.5 : 1.2,
                    children: [
                      _buildStatCard(
                        'Total Tools',
                        Text(
                          totalTools.toString(),
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icons.build,
                        Colors.blue,
                        context,
                        () => onNavigateToTab(1), // Navigate to Tools tab
                      ),
                      _buildStatCard(
                        'Technicians',
                        Text(
                          technicians.length.toString(),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icons.people,
                        Colors.green,
                        context,
                        () => onNavigateToTab(3), // Navigate to Technicians tab
                      ),
                      _buildStatCard(
                        'Total Value',
                        CurrencyFormatter.aedAmount(
                          totalValue,
                          decimalDigits: 0,
                          amountStyle: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                            letterSpacing: -0.5,
                          ),
                          aedStyle: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32) * 0.6,
                          ),
                        ),
                        Icons.attach_money,
                        Colors.orange,
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailScreen(
                              reportType: ReportType.financialSummary,
                              timePeriod: 'Last 30 Days',
                            ),
                          ),
                        ),
                      ),
                      _buildStatCard(
                        'Maintenance',
                        Text(
                          '${toolsNeedingMaintenance.length}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Icons.warning,
                        Colors.red,
                        context,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaintenanceScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Status Overview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                              builder: (context) => const ToolsScreen(isSelectionMode: true),
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
                        child: Consumer<PendingApprovalsProvider>(
                          builder: (context, provider, child) {
                            final pendingCount = provider.pendingCount;
                            return _buildQuickActionCardWithBadge(
                              'Authorize Users',
                              Icons.verified_user,
                              Colors.blue,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminApprovalScreen(),
                                ),
                              ),
                              context,
                              badgeCount: pendingCount,
                            );
                          },
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
                          'Settings',
                          Icons.settings,
                          Colors.grey,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
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
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Approvals',
                          Icons.approval,
                          Colors.amber,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ApprovalWorkflowsScreen(),
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
                          'Maintenance Schedule',
                          Icons.schedule,
                          Colors.teal,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MaintenanceScreen(),
                            ),
                          ),
                          context,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, Widget valueWidget, IconData icon, Color color,
      BuildContext context, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.getCardPadding(context),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).colorScheme.surface 
              : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, _cardRadiusValue)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large value centered, taking up center space
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: valueWidget),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            // Icon and name together at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 6)),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.8),
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      String status, String count, Color color, BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 4)),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).colorScheme.surface 
              : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, _cardRadiusValue)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  status,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.8),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_cardRadiusValue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(_cardRadiusValue),
          border: isDarkMode
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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

  Widget _buildQuickActionCardWithBadge(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context, {
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_cardRadiusValue),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(_cardRadiusValue),
          border: isDarkMode
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Admin';
    }
    return fullName.split(RegExp(r"\s+")).first;
  }
}
