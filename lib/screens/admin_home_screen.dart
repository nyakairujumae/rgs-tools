import 'dart:async';
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
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/account_deletion_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'checkin_screen.dart';
import 'reports_screen.dart';
import 'report_detail_screen.dart';
import 'permanent_assignment_screen.dart';
import '../services/report_service.dart';
import '../services/last_route_service.dart';
import 'maintenance_screen.dart';
import 'cost_analytics_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'advanced_search_screen.dart';
import 'compliance_screen.dart';
import 'approval_workflows_screen.dart';
import 'shared_tools_screen.dart';
import 'admin_role_management_screen.dart';
import 'admin_management_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_notification_screen.dart';
import 'tool_issues_screen.dart';
import 'all_tool_history_screen.dart';
import 'technician_my_tools_screen.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import '../models/user_role.dart';
import '../models/admin_position.dart';
import '../services/admin_position_service.dart';
import 'package:intl/intl.dart';

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
  Timer? _notificationRefreshTimer;
  final TextEditingController _inviteNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  List<AdminPosition> _positions = [];
  bool _isLoadingPositions = false;
  String? _selectedPositionId;
  bool _canManageAdmins = false;
  String? _lastUserId;

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
      LastRouteService.saveLastRoute('/admin');
      _loadData();
      _loadInviteAdminData();
      // Refresh notifications every 30 seconds to update badges in real-time
      _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) {
          // Skip if already loading to prevent duplicate calls
          context.read<AdminNotificationProvider>().loadNotifications(skipIfLoading: true);
      }
    });
    });
  }


  Future<void> _loadData() async {
    if (_isDisposed) return;

    try {
      await Future.wait([
        context.read<SupabaseToolProvider>().loadTools(),
        context.read<SupabaseTechnicianProvider>().loadTechnicians(),
        context.read<PendingApprovalsProvider>().loadPendingApprovals(),
        context.read<AdminNotificationProvider>().loadNotifications(),
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
    _notificationRefreshTimer?.cancel();
    _isDisposed = true;
    _inviteNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadInviteAdminData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId == null) {
        setState(() {
          _canManageAdmins = false;
        });
        return;
      }

      AdminPosition? position = await AdminPositionService.getUserPosition(userId);
      if (position == null) {
        final metadataPositionId =
            authProvider.user?.userMetadata?['position_id'] as String?;
        if (metadataPositionId != null && metadataPositionId.isNotEmpty) {
          await AdminPositionService.updateUserPosition(userId, metadataPositionId);
          position = await AdminPositionService.getPositionById(metadataPositionId);
        } else {
          final fallback = await AdminPositionService.getPositionByName('Super Admin') ??
              await AdminPositionService.getPositionByName('CEO');
          if (fallback != null) {
            await AdminPositionService.updateUserPosition(userId, fallback.id);
            position = fallback;
          }
        }
      }

      final positionName = position?.name.toLowerCase();
      final isSuperAdmin = positionName == 'super admin' || positionName == 'ceo';
      final canManageAdmins = isSuperAdmin ||
          await AdminPositionService.userHasPermission(
            userId,
            'can_manage_admins',
          );
      if (!mounted) return;
      setState(() {
        _canManageAdmins = canManageAdmins;
      });

      if (canManageAdmins) {
        await _loadPositions();
      }
    } catch (e) {
      debugPrint('❌ Error loading admin invite data: $e');
    }
  }

  Future<void> _loadPositions() async {
    setState(() {
      _isLoadingPositions = true;
    });

    try {
      final positions = await AdminPositionService.getAllPositions();
      if (!mounted) return;
      setState(() {
        _positions = positions;
        if (_positions.isNotEmpty && _selectedPositionId == null) {
          _selectedPositionId = _positions.first.id;
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading admin positions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPositions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: Pending approvals are loaded in initState and refreshed periodically
    // No need to reload on every build to prevent constant refreshing

    final authProvider = context.watch<AuthProvider>();

    if (authProvider.userId != _lastUserId) {
      _lastUserId = authProvider.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _canManageAdmins = false;
        });
        if (authProvider.userId != null) {
          _loadInviteAdminData();
        }
      });
    }

    final isWebDesktop =
        ResponsiveHelper.isWeb && ResponsiveHelper.isDesktop(context);

    final contentScaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: (_selectedIndex == 0 && !isWebDesktop)
          ? AppBar(
                  toolbarHeight: 56,
                  backgroundColor: context.appBarBackground,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  leadingWidth: 64,
                  leading: Consumer<AdminNotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              visualDensity: VisualDensity.compact,
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
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: notificationProvider.unreadCount > 9 ? 4 : 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF28B82),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    notificationProvider.unreadCount > 99 
                                        ? '99+' 
                                        : '${notificationProvider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  actions: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final isDisabled = authProvider.isLoggingOut;
                        return IconButton(
                          icon: const Icon(Icons.account_circle_outlined),
                          onPressed: isDisabled
                              ? null
                              : () => _showProfileBottomSheet(context, authProvider),
                        );
                      },
                    ),
                  ],
                )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: isWebDesktop
          ? null
          : ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) =>
                    setState(() => _selectedIndex = index.clamp(0, 3)),
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                    Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                        Theme.of(context).colorScheme.surface,
                selectedItemColor: Theme.of(context).colorScheme.secondary,
                unselectedItemColor: Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedItemColor ??
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
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
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Container(
        color: context.scaffoldBackground,
        child: isWebDesktop
            ? SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWebSidebar(context),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF111318)
                            : const Color(0xFFF5F7FA),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildWebTopBar(context),
                            Expanded(child: contentScaffold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : contentScaffold,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // B2B web sidebar – light, minimal, brand colors
  // ---------------------------------------------------------------------------

  Widget _buildWebSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RGS Tools',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: border),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebarNavItem(context, 0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
                const SizedBox(height: 2),
                _buildSidebarNavItem(context, 1, 'Tools', Icons.build_outlined, Icons.build_rounded),
                const SizedBox(height: 2),
                _buildSidebarNavItem(context, 2, 'Shared Tools', Icons.share_outlined, Icons.share_rounded),
                const SizedBox(height: 2),
                _buildSidebarNavItem(context, 3, 'Technicians', Icons.people_outline, Icons.people_rounded),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: border),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebarRouteItem(context, 'Reports', Icons.analytics_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Maintenance', Icons.handyman_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Approvals', Icons.approval_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalWorkflowsScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Tool Issues', Icons.report_problem_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Tool History', Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AllToolHistoryScreen()));
                }),
              ],
            ),
          ),

          const Spacer(),

          Container(height: 1, color: border),
          const SizedBox(height: 8),

          Consumer<AdminNotificationProvider>(
            builder: (context, notificationProvider, child) {
              return _buildSidebarBottomItem(
                context,
                'Notifications',
                Icons.notifications_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminNotificationScreen()),
                  );
                },
                badge: notificationProvider.unreadCount,
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return _buildSidebarBottomItem(
                context,
                'Account',
                Icons.account_circle_outlined,
                onTap: () => _showProfileBottomSheet(context, authProvider),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);
    const titles = ['Dashboard', 'Tools', 'Shared Tools', 'Technicians'];
    final title = titles[_selectedIndex.clamp(0, 3)];
    final today = DateFormat('MMM d, yyyy').format(DateTime.now());

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            today,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    IconData selectedIcon,
  ) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index.clamp(0, 3)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBottomItem(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarRouteItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
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

  void _showProfileBottomSheet(
      BuildContext parentContext, AuthProvider authProvider) {
    final theme = Theme.of(parentContext);
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      isScrollControlled: true,
      isDismissible: true, // Enable dismiss by tapping outside
      enableDrag: true, // Enable drag to dismiss
      builder: (sheetContext) {
        // Use theme-aware background
        final surfaceColor = theme.colorScheme.surface;
        return DraggableScrollableSheet(
          expand: false, // Match technician implementation
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24), // Cleaner, more modern radius
                ),
                // Remove shadow for cleaner look
              ),
              child: SafeArea(
                top: false, // Don't add top padding, handle it manually
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 6),
                            _buildSectionLabel(parentContext, 'Account'),
                            const SizedBox(height: 12),
                            _buildAccountCard(
                                sheetContext, parentContext, authProvider),
                            const SizedBox(height: 20),
                            _buildSectionLabel(parentContext, 'Account Details'),
                            const SizedBox(height: 12),
                            _buildAccountDetails(parentContext, authProvider),
                            const SizedBox(height: 24),
                            _buildSectionLabel(parentContext, 'Preferences'),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              context: parentContext,
                              icon: Icons.build,
                              label: 'My Tools',
                              iconColor: AppTheme.primaryColor,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.push(
                                  parentContext,
                                  MaterialPageRoute(
                                    builder: (_) => const TechnicianMyToolsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (authProvider.isAdmin && _canManageAdmins) ...[
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context: parentContext,
                                icon: Icons.admin_panel_settings,
                                label: 'Manage Admins',
                                iconColor: AppTheme.secondaryColor,
                                backgroundColor:
                                    AppTheme.secondaryColor.withOpacity(0.12),
                                onTap: () {
                                  if (!parentContext.mounted) return;
                                  Navigator.of(parentContext)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => const AdminManagementScreen(),
                                        ),
                                      )
                                      .then((_) {
                                    if (Navigator.of(sheetContext).canPop()) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              context: parentContext,
                              icon: Icons.settings,
                              label: 'Settings',
                              iconColor:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                              backgroundColor: theme.colorScheme.onSurface
                                  .withOpacity(0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.push(
                                  parentContext,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildSectionLabel(parentContext, 'Security'),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              context: parentContext,
                              icon: Icons.delete_forever,
                              label: 'Delete Account',
                              iconColor: Colors.red,
                              iconPadding: 8,
                              backgroundColor: Colors.red.withOpacity(0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                AccountDeletionHelper.showDeleteAccountDialog(
                                  parentContext,
                                  authProvider,
                                );
                              },
                              showTrailingChevron: false,
                            ),
                            const SizedBox(height: 12),
                            _buildProfileOption(
                              context: parentContext,
                              icon: Icons.logout,
                              label: 'Logout',
                              iconColor: Colors.red,
                              iconPadding: 8,
                              backgroundColor: Colors.red.withOpacity(0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _performLogout(authProvider);
                              },
                              showTrailingChevron: false,
                            ),
                            // Bottom padding for safe scrolling
                            SizedBox(
                              height: MediaQuery.of(parentContext).viewInsets.bottom +
                                  24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext sheetContext, BuildContext parentContext, AuthProvider authProvider) {
    final theme = Theme.of(parentContext);
    final isDesktop = ResponsiveHelper.isDesktop(parentContext);
    final displayName = _resolveDisplayName(authProvider);
    final fullName = displayName ?? 'Account';
    final roleLabel = authProvider.userRole.displayName;
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Clean, minimal avatar
              Container(
                width: isDesktop ? 48 : 56,
                height: isDesktop ? 48 : 56,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name with subtle edit button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            style: TextStyle(
                              fontSize: isDesktop ? 17 : 19,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _showEditNameDialog(sheetContext, parentContext, authProvider),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit_outlined,
                                size: isDesktop ? 16 : 18,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 6 : 8),
                    // Clean role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: isDesktop ? 11 : 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.secondaryColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showEditNameDialog(
      BuildContext sheetContext, BuildContext parentContext, AuthProvider authProvider) {
    final nameController = TextEditingController(
      text: authProvider.userFullName ?? '',
    );
    final theme = Theme.of(parentContext);
    final isDesktop = ResponsiveHelper.isDesktop(parentContext);

    showDialog(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        ),
        title: Text(
          'Edit Name',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(fontSize: isDesktop ? 14 : 16),
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 16,
              vertical: isDesktop ? 12 : 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != authProvider.userFullName) {
                try {
                  await authProvider.updateUserName(newName);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Name updated successfully'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update name: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
    double iconPadding = 6,
    bool showTrailingChevron = true,
  }) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 10 : 12,
          vertical: isDesktop ? 10 : 12,
        ),
        decoration: context.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 6 : iconPadding),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(isDesktop ? 6 : 8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isDesktop ? 16 : 18,
              ),
            ),
            SizedBox(width: isDesktop ? 10 : 12),
            Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
            if (showTrailingChevron)
              Icon(
                Icons.chevron_right,
                size: isDesktop ? 18 : 20,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetails(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final email = authProvider.user?.email ?? 'Not available';
    final createdAt = authProvider.user?.createdAt;
    final memberSince = _formatMemberSince(createdAt);
    final roleLabel = authProvider.userRole.displayName;

    return Container(
      padding: EdgeInsets.all(context.spacingLarge),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountDetailRow(context, 'Email', email),
          SizedBox(height: isDesktop ? 8 : 10),
          _buildAccountDetailRow(context, 'Member Since', memberSince),
          SizedBox(height: isDesktop ? 8 : 10),
          _buildAccountDetailRow(context, 'Role', roleLabel),
        ],
      ),
    );
  }

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null) return 'Unknown';
    try {
      final parsed = DateTime.parse(createdAt);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _buildAccountDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isDesktop ? 100 : 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performLogout(AuthProvider authProvider) async {
    if (_isDisposed || !mounted) return;
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await authProvider.signOut();
      await Future.delayed(const Duration(milliseconds: 100));
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
      debugPrint('Logout error: $e');
      debugPrint('Stack trace: $stackTrace');
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

  String _getInitials(String? fullName) {
    final cleaned = fullName?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return '?';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'AD';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  String? _resolveDisplayName(AuthProvider authProvider) {
    final fullName = authProvider.userFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final email = authProvider.userEmail;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return null;
  }

}

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final Function(String) onNavigateToToolsWithFilter;
  static const double _cardRadiusValue = 12; // Apple/Jobber-style web (matches global theme)
  static const double _mobileCardRadiusValue = 16; // Keep mobile rounded
  static const Color _dashboardGreen = Color(0xFF2E7D32);
  static const Color _skeletonBaseColor = Color(0xFFE6EAF1);
  static const Color _skeletonHighlightColor = Color(0xFFD8DBE0);
  
  double _getCardRadius(BuildContext context) {
    return ResponsiveHelper.isWeb ? _cardRadiusValue : _mobileCardRadiusValue;
  }

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
        final statValueStyle = TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        );
        // Show skeleton ONLY when offline - for fresh app with no data, show empty states immediately
        // This prevents long loading screens that frustrate users
        final isLoadingDashboard = isOffline;
        final isWideLayout =
            ResponsiveHelper.isWeb && ResponsiveHelper.isDesktop(context);
        final horizontalPadding =
            ResponsiveHelper.getResponsiveSpacing(context, isWideLayout ? 24 : 16);
        final topPadding = 0.0;
        final bottomPadding =
            ResponsiveHelper.getResponsiveSpacing(context, 20);

        final cardRadius = BorderRadius.circular(_cardRadiusValue);
        final greetingCard = isLoadingDashboard
            ? _buildGreetingSkeleton(context, cardRadius)
            : _buildGreetingCard(context, authProvider);
        final statusOverviewCard = isLoadingDashboard
            ? _buildStatusOverviewSkeleton(context, cardRadius)
            : _buildStatusOverviewCard(
                context,
                availableCount: availableTools.length,
                assignedCount: assignedTools.length,
                showTitle: isWideLayout,
              );

        final screenWidth = MediaQuery.of(context).size.width;
        final contentPadding = isWideLayout ? (screenWidth > 1600 ? 48.0 : 32.0) : horizontalPadding;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            contentPadding,
            topPadding,
            contentPadding,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWideLayout) ...[
                SafeArea(
                  bottom: false,
                  minimum: const EdgeInsets.only(top: 32),
                  child: _buildWebDashboard(
                    context,
                    greetingCard: greetingCard,
                    isLoadingDashboard: isLoadingDashboard,
                    totalTools: totalTools,
                    technicianCount: technicians.length,
                    totalValue: totalValue,
                    maintenanceCount: toolsNeedingMaintenance.length,
                    availableCount: availableTools.length,
                    assignedCount: assignedTools.length,
                  ),
                ),
              ] else ...[
                  SafeArea(
                    bottom: false,
                    minimum: EdgeInsets.only(
                      top: ResponsiveHelper.getResponsiveSpacing(context, 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview of your tools, technicians, and approvals.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                    greetingCard,

                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 26),
                  ),

                  Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),

                  // Stats Grid - mobile uses grid
                  isLoadingDashboard
                      ? _buildMetricsSkeleton(context)
                      : GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
                              mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
                              childAspectRatio: 1.2,
                              children: [
                                _buildStatCard(
                                  'Total Tools',
                                  Text(
                                    totalTools.toString(),
                                    style: statValueStyle.copyWith(color: Colors.blue),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.build,
                                  Colors.blue,
                                  context,
                                  () => onNavigateToTab(1),
                                ),
                                _buildStatCard(
                                  'Technicians',
                                  Text(
                                    technicians.length.toString(),
                                    style: statValueStyle.copyWith(color: _dashboardGreen),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.people,
                                  _dashboardGreen,
                                  context,
                                  () => onNavigateToTab(3),
                                ),
                                _buildStatCard(
                                  'Total Value',
                                  CurrencyFormatter.formatCurrencyWidget(
                                    totalValue,
                                    decimalDigits: 0,
                                    style: statValueStyle.copyWith(color: Colors.orange),
                                    context: context,
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
                                    style: statValueStyle.copyWith(color: Colors.red),
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

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

                  // Status Overview (mobile only; web has it in top row)
                  if (!isWideLayout) ...[
                    statusOverviewCard,
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  ],

                  // Quick Actions (mobile only; web has it in side-by-side section above)
                  if (!isWideLayout) ...[
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                  ),
                  SizedBox(height: 16),
                  if (isLoadingDashboard)
                    _buildQuickActionsSkeleton(context)
                  else ...[
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
                            _dashboardGreen,
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
                    SizedBox(height: context.spacingMedium),
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
                        SizedBox(width: context.spacingMedium),
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
                    SizedBox(height: context.spacingMedium),
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
                        SizedBox(width: context.spacingMedium),
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
                    SizedBox(height: context.spacingMedium),
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
                        SizedBox(width: context.spacingMedium),
                        Expanded(
                          child: _buildQuickActionCard(
                            'Tool History',
                            Icons.history,
                            Colors.indigo,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllToolHistoryScreen(),
                              ),
                            ),
                            context,
                          ),
                        ),
                      ],
                    ),
                  ],  // end else quick actions
                  ],  // end if (!isWideLayout) Quick Actions section
                  ],  // end else (mobile Key Metrics + Quick Actions)
                ],
              ),
        );
      },
    );
  }

  /// Web: New dashboard layout – metric strip, status bar, action list
  Widget _buildWebDashboard(
    BuildContext context, {
    required Widget greetingCard,
    required bool isLoadingDashboard,
    required int totalTools,
    required int technicianCount,
    required double totalValue,
    required int maintenanceCount,
    required int availableCount,
    required int assignedCount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        greetingCard,
        const SizedBox(height: 32),
        if (isLoadingDashboard)
          _buildWebDashboardSkeleton(context)
        else ...[
        // Metric strip – single horizontal bar, 4 segments
        Container(
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(
              color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildMetricSegment(
                  context,
                  icon: Icons.build_rounded,
                  value: totalTools.toString(),
                  label: 'Total Tools',
                  color: AppTheme.primaryColor,
                  onTap: () => onNavigateToTab(1),
                  isFirst: true,
                ),
                _buildMetricSegment(
                  context,
                  icon: Icons.people_rounded,
                  value: technicianCount.toString(),
                  label: 'Technicians',
                  color: AppTheme.secondaryColor,
                  onTap: () => onNavigateToTab(3),
                  isFirst: false,
                ),
                _buildMetricSegment(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  value: CurrencyFormatter.formatCurrencyWhole(totalValue),
                  label: 'Total Value',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(
                        reportType: ReportType.financialSummary,
                        timePeriod: 'Last 30 Days',
                      ),
                    ),
                  ),
                  isFirst: false,
                ),
                _buildMetricSegment(
                  context,
                  icon: Icons.build_circle_rounded,
                  value: maintenanceCount.toString(),
                  label: 'Maintenance',
                  color: AppTheme.errorColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MaintenanceScreen(),
                    ),
                  ),
                  isFirst: false,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Two-column: status + actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status panel
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(
                        color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available',
                                    style: TextStyle(fontSize: 12, color: muted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    availableCount.toString(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Assigned',
                                    style: TextStyle(fontSize: 12, color: muted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    assignedCount.toString(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              if (availableCount + assignedCount > 0) ...[
                                Expanded(
                                  flex: availableCount,
                                  child: Container(
                                    height: 8,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                Expanded(
                                  flex: assignedCount,
                                  child: Container(
                                    height: 8,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ] else
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    color: onSurface.withValues(alpha: 0.1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Action list
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWebActionList(context),
                ],
              ),
            ),
          ],
        ),
        ], // end else
      ],
    );
  }

  Widget _buildWebDashboardSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSegment(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isFirst,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            border: isFirst
                ? null
                : Border(
                    left: BorderSide(color: border),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebActionList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildWebActionRow(
            context,
            'Add Tool',
            Icons.add_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddToolScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Assign Tool',
            Icons.person_add_rounded,
            AppTheme.secondaryColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ToolsScreen(isSelectionMode: true)),
            ),
            showDivider: true,
          ),
          Consumer<PendingApprovalsProvider>(
            builder: (context, provider, _) => _buildWebActionRow(
              context,
              'Authorize Users',
              Icons.verified_user_rounded,
              AppTheme.primaryColor,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalScreen())),
              showDivider: true,
              badgeCount: provider.pendingCount,
            ),
          ),
          _buildWebActionRow(
            context,
            'Reports',
            Icons.analytics_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Tool Issues',
            Icons.report_problem_rounded,
            AppTheme.errorColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Approvals',
            Icons.task_alt_rounded,
            AppTheme.warningColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalWorkflowsScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Maintenance Schedule',
            Icons.schedule_rounded,
            AppTheme.secondaryColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Tool History',
            Icons.history_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllToolHistoryScreen())),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWebActionRow(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool showDivider = true,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 50),
            color: border,
          ),
      ],
    );
  }

  /// Web: B2B metric cards – clean, minimal (kept for mobile/skeleton)
  Widget _buildWebStatsRow(
    BuildContext context, {
    required int totalTools,
    required int technicianCount,
    required double totalValue,
    required int maintenanceCount,
    required TextStyle statValueStyle,
  }) {
    const gap = 16.0;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildB2BStatCard(
            context,
            label: 'Total Tools',
            value: totalTools.toString(),
            accentColor: AppTheme.primaryColor,
            onTap: () => onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: _buildB2BStatCard(
            context,
            label: 'Technicians',
            value: technicianCount.toString(),
            accentColor: AppTheme.secondaryColor,
            onTap: () => onNavigateToTab(3),
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: _buildB2BStatCard(
            context,
            label: 'Total Value',
            valueWidget: CurrencyFormatter.formatCurrencyWidget(
              totalValue,
              decimalDigits: 0,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              context: context,
            ),
            accentColor: AppTheme.primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(
                  reportType: ReportType.financialSummary,
                  timePeriod: 'Last 30 Days',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: _buildB2BStatCard(
            context,
            label: 'Maintenance',
            value: maintenanceCount.toString(),
            accentColor: AppTheme.errorColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MaintenanceScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildB2BStatCard(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    valueWidget ?? Text(
                      value ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, AuthProvider authProvider) {
    final isWeb = ResponsiveHelper.isWeb;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = _getCardRadius(context);

    // Web: B2B minimal header
    if (isWeb) {
      final displayName = _resolveDisplayName(authProvider);
      final firstName = _getFirstName(displayName);
      final greeting = firstName.isEmpty
          ? '${_getGreeting()}!'
          : '${_getGreeting()}, $firstName!';
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          greeting,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    // Mobile: original card layout
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingLarge * 1.5,
        vertical: context.spacingLarge * 1.5,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveIconSize(context, 52),
            height: ResponsiveHelper.getResponsiveIconSize(context, 52),
            decoration: BoxDecoration(
              color: _dashboardGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.borderRadiusLarge),
            ),
            child: Center(
              child: Icon(
                Icons.admin_panel_settings,
                color: _dashboardGreen,
                size: ResponsiveHelper.getResponsiveIconSize(context, 26),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final displayName = _resolveDisplayName(authProvider);
                    final firstName = _getFirstName(displayName);
                    final greeting = firstName.isEmpty
                        ? '${_getGreeting()}!'
                        : '${_getGreeting()}, $firstName!';
                    return Text(
                      greeting,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    );
                  },
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  'Manage your HVAC tools and technicians',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard(
    BuildContext context, {
    required int availableCount,
    required int assignedCount,
    bool showTitle = false,
  }) {
    final isWebLayout = ResponsiveHelper.isWeb;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = _getCardRadius(context);

    // Web: B2B status overview – minimal table-style
    if (isWebLayout) {
      final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tool Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildB2BStatusRow('Available', availableCount.toString(), AppTheme.secondaryColor, theme),
                ),
                Container(width: 1, height: 32, color: border),
                Expanded(
                  child: _buildB2BStatusRow('Assigned', assignedCount.toString(), AppTheme.primaryColor, theme),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile: original style
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingLarge * 1.5,
        vertical: context.spacingLarge * 1.5,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildStatusItem(
                'Available',
                availableCount.toString(),
                _dashboardGreen,
                context,
              ),
              _buildStatusItem(
                'Assigned',
                assignedCount.toString(),
                Colors.blue,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildB2BQuickAction(context, 'Add Tool', Icons.add, AppTheme.primaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddToolScreen()));
        }),
        _buildB2BQuickAction(context, 'Assign Tool', Icons.person_add, AppTheme.secondaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(isSelectionMode: true)));
        }),
        Consumer<PendingApprovalsProvider>(
          builder: (context, provider, _) => _buildB2BQuickAction(
            context,
            'Authorize Users',
            Icons.verified_user,
            AppTheme.primaryColor,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalScreen())),
            badgeCount: provider.pendingCount,
          ),
        ),
        _buildB2BQuickAction(context, 'Reports', Icons.analytics, AppTheme.primaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
        }),
        _buildB2BQuickAction(context, 'Tool Issues', Icons.report_problem, AppTheme.errorColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen()));
        }),
        _buildB2BQuickAction(context, 'Approvals', Icons.approval, AppTheme.warningColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalWorkflowsScreen()));
        }),
        _buildB2BQuickAction(context, 'Maintenance Schedule', Icons.schedule, AppTheme.secondaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
        }),
        _buildB2BQuickAction(context, 'Tool History', Icons.history, AppTheme.primaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AllToolHistoryScreen()));
        }),
      ],
    );
  }

  Widget _buildB2BQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSkeleton(BuildContext context, BorderRadius cardRadius) {
    final isWeb = ResponsiveHelper.isWeb;
    final iconSize = isWeb ? 44.0 : ResponsiveHelper.getResponsiveIconSize(context, 52);
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 20 : 24,
          vertical: isWeb ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(_getCardRadius(context)),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: _skeletonBaseColor,
                borderRadius: BorderRadius.circular(isWeb ? 8 : 16),
              ),
            ),
            SizedBox(width: isWeb ? 14 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonLine(
                    context,
                    height: isWeb ? 18 : 20,
                  ),
                  SizedBox(height: isWeb ? 6 : 8),
                  _buildSkeletonLine(
                    context,
                    widthFactor: 0.5,
                    height: isWeb ? 13 : 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSkeleton(BuildContext context) {
    final isWeb = ResponsiveHelper.isWeb;
    
    // Web uses horizontal row skeleton
    if (isWeb && ResponsiveHelper.isDesktop(context)) {
      return Shimmer.fromColors(
        baseColor: _skeletonBaseColor,
        highlightColor: _skeletonHighlightColor,
        period: const Duration(milliseconds: 1500),
        child: Row(
          children: List.generate(4, (index) => [
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(_cardRadiusValue),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _skeletonBaseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonLine(context, widthFactor: 0.6, height: 12),
                          const SizedBox(height: 6),
                          _buildSkeletonLine(context, widthFactor: 0.4, height: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]).expand((x) => x).toList(),
        ),
      );
    }
    
    // Mobile uses grid skeleton
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: List.generate(
          4,
          (_) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: context.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: _buildSkeletonLine(context, height: 26),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _skeletonBaseColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSkeletonLine(context, height: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Column(
        children: [
          _buildQuickActionSkeletonRow(context, 2),
          SizedBox(height: context.spacingMedium),
          _buildQuickActionSkeletonRow(context, 2),
          SizedBox(height: context.spacingMedium),
          _buildQuickActionSkeletonRow(context, 1),
          SizedBox(height: context.spacingMedium),
          _buildQuickActionSkeletonRow(context, 2),
          SizedBox(height: context.spacingMedium),
          _buildQuickActionSkeletonRow(context, 1),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewSkeleton(
      BuildContext context, BorderRadius cardRadius) {
    final isWeb = ResponsiveHelper.isWeb;
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 20,
          vertical: isWeb ? 14 : 20,
        ),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(_getCardRadius(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(
              context,
              widthFactor: 0.35,
              height: isWeb ? 13 : 14,
            ),
            SizedBox(height: isWeb ? 10 : 18),
            Row(
              children: [
                Expanded(child: _buildStatusSkeletonTile(context)),
                SizedBox(width: isWeb ? 8 : 12),
                Expanded(child: _buildStatusSkeletonTile(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSkeletonTile(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 14),
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, _cardRadiusValue),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(
            context,
            height: ResponsiveHelper.getResponsiveSpacing(context, 22),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 10)),
          _buildSkeletonLine(
            context,
            widthFactor: 0.6,
            height: ResponsiveHelper.getResponsiveSpacing(context, 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionSkeletonRow(BuildContext context, int count) {
    final children = <Widget>[];
    for (var i = 0; i < count; i++) {
      children.add(Expanded(child: _buildQuickActionSkeletonTile(context)));
      if (i < count - 1) {
        children.add(SizedBox(width: context.spacingMedium));
      }
    }
    return Row(children: children);
  }

  Widget _buildQuickActionSkeletonTile(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingLarge,
        vertical: context.spacingMedium,
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 24),
            height: ResponsiveHelper.getResponsiveSpacing(context, 24),
            decoration: const BoxDecoration(
              color: _skeletonBaseColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
          _buildSkeletonLine(
            context,
            height: ResponsiveHelper.getResponsiveSpacing(context, 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(BuildContext context,
      {double? widthFactor, double height = 12}) {
    final isWeb = ResponsiveHelper.isWeb;
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _skeletonBaseColor,
          borderRadius: BorderRadius.circular(isWeb ? 4 : 8),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, Widget valueWidget, IconData icon, Color color,
      BuildContext context, VoidCallback? onTap) {
    final horizontalPadding =
        ResponsiveHelper.getResponsiveSpacing(context, 18);
    final verticalPadding =
        ResponsiveHelper.getResponsiveSpacing(context, 16);
    final isWebLayout = ResponsiveHelper.isWeb;
    final titleStyle = TextStyle(
      color: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.color
          ?.withValues(alpha: 0.8),
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final iconBadge = Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 6)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 8),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: ResponsiveHelper.getResponsiveIconSize(context, 16),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: context.cardDecoration,
        child: isWebLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      iconBadge,
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 10),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: valueWidget,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: valueWidget,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconBadge,
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 6),
                      ),
                      Flexible(
                        child: Text(
                          title,
                          style: titleStyle,
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
    final isWebLayout = ResponsiveHelper.isWeb;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = _getCardRadius(context);

    if (isWebLayout) {
      // Web: clean inline status with colour dot
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile: original card style
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              status,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildB2BStatusRow(String label, String count, Color accentColor, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isWebLayout = ResponsiveHelper.isWeb;
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = TextStyle(
      color: theme.textTheme.bodyLarge?.color,
      fontSize:
          ResponsiveHelper.getResponsiveFontSize(context, isWebLayout ? 13 : 12),
      fontWeight: FontWeight.w500,
    );
    final iconContainer = Container(
      width: ResponsiveHelper.getResponsiveSpacing(context, isWebLayout ? 40 : 36),
      height: ResponsiveHelper.getResponsiveSpacing(context, isWebLayout ? 40 : 36),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 10),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: ResponsiveHelper.getResponsiveIconSize(context, isWebLayout ? 20 : 18),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isWebLayout ? 14 : context.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isWebLayout ? 14 : context.borderRadiusLarge),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 16 : context.spacingLarge,
            vertical: isWebLayout ? 14 : context.spacingMedium,
          ),
          decoration: isWebLayout
              ? BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                )
              : context.cardDecoration,
          child: isWebLayout
              ? Row(
                  children: [
                    iconContainer,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 22),
                    SizedBox(height: context.spacingSmall),
                    Text(
                      title,
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
    final isWebLayout = ResponsiveHelper.isWeb;
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = TextStyle(
      color: theme.textTheme.bodyLarge?.color,
      fontSize:
          ResponsiveHelper.getResponsiveFontSize(context, isWebLayout ? 13 : 12),
      fontWeight: FontWeight.w500,
    );
    final iconContainer = Container(
      width: ResponsiveHelper.getResponsiveSpacing(context, isWebLayout ? 40 : 36),
      height: ResponsiveHelper.getResponsiveSpacing(context, isWebLayout ? 40 : 36),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 10),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: ResponsiveHelper.getResponsiveIconSize(context, isWebLayout ? 20 : 18),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isWebLayout ? 14 : context.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isWebLayout ? 14 : context.borderRadiusLarge),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 16 : context.spacingLarge,
            vertical: isWebLayout ? 14 : context.spacingMedium,
          ),
          decoration: isWebLayout
              ? BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                )
              : context.cardDecoration,
          child: Stack(
            alignment: isWebLayout ? Alignment.centerLeft : Alignment.center,
            children: [
              isWebLayout
                  ? Row(
                      children: [
                        iconContainer,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 22),
                        SizedBox(height: context.spacingSmall),
                        Text(
                          title,
                          style: textStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
              if (badgeCount > 0 && !isWebLayout)
                Positioned(
                  top: context.spacingMicro,
                  right: context.spacingMicro,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeCount > 9 ? 5 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
      return '';
    }
    return fullName.split(RegExp(r"\s+")).first;
  }

  String? _resolveDisplayName(AuthProvider authProvider) {
    final fullName = authProvider.userFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final email = authProvider.userEmail;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return null;
  }
}
