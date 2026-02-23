import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import 'admin_dashboard_screen.dart';
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
import '../screens_web/layouts/admin_web_layout.dart';
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
import '../utils/logger.dart';
import '../l10n/app_localizations.dart';

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
                            CupertinoPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        });
                      } catch (e) {
                        // Silent error handling
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            CupertinoPageRoute(
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
      final toolProvider = context.read<SupabaseToolProvider>();
      final techProvider = context.read<SupabaseTechnicianProvider>();
      await Future.wait([
        toolProvider.loadTools(),
        techProvider.loadTechnicians(),
        context.read<PendingApprovalsProvider>().loadPendingApprovals(),
        context.read<AdminNotificationProvider>().loadNotifications(),
      ]);
      // Subscribe to realtime after initial load
      toolProvider.subscribeToRealtime();
      techProvider.subscribeToRealtime();
    } catch (e) {
      Logger.debug('Error loading admin data: $e');
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
    context.read<SupabaseToolProvider>().unsubscribeFromRealtime();
    context.read<SupabaseTechnicianProvider>().unsubscribeFromRealtime();
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
      Logger.debug('❌ Error loading admin invite data: $e');
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
      Logger.debug('❌ Error loading admin positions: $e');
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

    // Intercept for desktop web - use web-optimized layout
    if (ResponsiveHelper.isDesktopLayout(context)) {
      return AdminWebLayout(initialRoute: _selectedIndex);
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
                                  CupertinoPageRoute(
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
                                    color: AppTheme.badgeColor,
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
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard),
                    label: AppLocalizations.of(context).adminHome_dashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.build),
                    label: AppLocalizations.of(context).adminHome_tools,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.share),
                    label: AppLocalizations.of(context).adminHome_sharedTools,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people),
                    label: AppLocalizations.of(context).adminHome_technicians,
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
            : (defaultTargetPlatform == TargetPlatform.android
                ? contentScaffold
                : SafeArea(
                    child: contentScaffold,
                  )),
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
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const ReportsScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Maintenance', Icons.handyman_outlined, () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const MaintenanceScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Approvals', Icons.approval_outlined, () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const ApprovalWorkflowsScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Tool Issues', Icons.report_problem_outlined, () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const ToolIssuesScreen()));
                }),
                const SizedBox(height: 2),
                _buildSidebarRouteItem(context, 'Tool History', Icons.history, () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => const AllToolHistoryScreen()));
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
                    CupertinoPageRoute(builder: (context) => const AdminNotificationScreen()),
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
    final l10n = AppLocalizations.of(context);
    final titles = [l10n.adminHome_dashboard, l10n.adminHome_tools, l10n.adminHome_sharedTools, l10n.adminHome_technicians];
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border(left: BorderSide(color: primary, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
                    color: AppTheme.badgeColor,
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
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                                  CupertinoPageRoute(
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
                                        CupertinoPageRoute(
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
                                  CupertinoPageRoute(
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
                                color: theme.colorScheme.onSurface.withOpacity(0.55),
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
                color: theme.colorScheme.onSurface.withOpacity(0.5),
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
          CupertinoPageRoute(
            builder: (context) => const RoleSelectionScreen(),
            settings: const RouteSettings(name: '/role-selection'),
          ),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      Logger.debug('Logout error: $e');
      Logger.debug('Stack trace: $stackTrace');
      if (mounted) {
        try {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(
              builder: (context) => const RoleSelectionScreen(),
              settings: const RouteSettings(name: '/role-selection'),
            ),
            (route) => false,
          );
        } catch (navError) {
          Logger.debug('Navigation error during logout: $navError');
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
