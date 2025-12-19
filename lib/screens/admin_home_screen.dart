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
import 'package:shimmer/shimmer.dart';
import 'tools_screen.dart';
import 'technicians_screen.dart';
import 'add_tool_screen.dart';
import 'checkin_screen.dart';
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
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import '../models/user_role.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: Pending approvals are loaded in initState and refreshed periodically
    // No need to reload on every build to prevent constant refreshing

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Container(
        color: context.scaffoldBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
                  appBar: (_selectedIndex == 0)
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
                        if (authProvider.isLoading ||
                            authProvider.isLoggingOut) {
                          return IconButton(
                            icon: const Icon(Icons.account_circle_outlined),
                            onPressed: null,
                          );
                        }

                        return IconButton(
                          icon: const Icon(Icons.account_circle_outlined),
                          onPressed: () =>
                              _showProfileBottomSheet(context, authProvider),
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
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? 
                  Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.secondary,
              unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ??
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
    final fullName = authProvider.userFullName ?? 'Admin User';
    final roleLabel = authProvider.userRole.displayName;
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: context.cardDecoration,
      child: Row(
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
      return 'AD';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'AD';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

}

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final Function(String) onNavigateToToolsWithFilter;
  static const double _cardRadiusValue = 20;
  static const Color _dashboardGreen = Color(0xFF2E7D32);
  static const Color _skeletonBaseColor = Color(0xFFE6EAF1);
  static const Color _skeletonHighlightColor = Color(0xFFD8DBE0);

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
        // When offline, always show skeleton loading (no cached dashboard)
        // Otherwise show skeleton only when actually loading
        final isLoadingDashboard = isOffline || 
            toolProvider.isLoading || 
            technicianProvider.isLoading;
        final horizontalPadding =
            ResponsiveHelper.getResponsiveSpacing(context, 16);
        final topPadding = 0.0;
        final bottomPadding =
            ResponsiveHelper.getResponsiveSpacing(context, 20);

        final cardRadius = BorderRadius.circular(_cardRadiusValue);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context, 22),
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview of your tools, technicians, and approvals.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context, 12),
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  // Welcome Section
                  isLoadingDashboard
                      ? _buildGreetingSkeleton(context, cardRadius)
                      : Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(context.spacingLarge * 1.5),
                          decoration: context.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: ResponsiveHelper.getResponsiveIconSize(context, 52),
                                    height: ResponsiveHelper.getResponsiveIconSize(context, 52),
                                    decoration: BoxDecoration(
                                      color: _dashboardGreen
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(context.borderRadiusLarge),
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

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 26)),

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
                  isLoadingDashboard
                      ? _buildMetricsSkeleton(context)
                      : GridView.count(
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
                                style: statValueStyle.copyWith(color: Colors.blue),
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
                          style: statValueStyle.copyWith(color: _dashboardGreen),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icons.people,
                        _dashboardGreen,
                              context,
                              () => onNavigateToTab(3), // Navigate to Technicians tab
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

                  // Status Overview
                  isLoadingDashboard
                      ? _buildStatusOverviewSkeleton(context, cardRadius)
                      : Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(context.spacingLarge * 1.5),
                          decoration: context.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatusItem(
                                    'Available',
                                    availableTools.length.toString(),
                                    _dashboardGreen,
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

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),

                  // Quick Actions
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
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingSkeleton(BuildContext context, BorderRadius cardRadius) {
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context, 52);
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: cardRadius,
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: _skeletonBaseColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, _cardRadiusValue),
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonLine(
                    context,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  _buildSkeletonLine(
                    context,
                    widthFactor: 0.5,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 14),
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
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
        mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 16),
        childAspectRatio: ResponsiveHelper.isWeb ? 1.5 : 1.2,
        children: List.generate(
          4,
          (_) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, 18),
              vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
            ),
            decoration: context.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: _buildSkeletonLine(
                      context,
                      height: ResponsiveHelper.getResponsiveSpacing(context, 26),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Row(
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 32),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 32),
                      decoration: BoxDecoration(
                        color: _skeletonBaseColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Expanded(
                      child: _buildSkeletonLine(
                        context,
                        height: ResponsiveHelper.getResponsiveSpacing(context, 14),
                      ),
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
    return Shimmer.fromColors(
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(
              context,
              widthFactor: 0.35,
              height: ResponsiveHelper.getResponsiveSpacing(context, 14),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),
            Row(
              children: [
                Expanded(child: _buildStatusSkeletonTile(context)),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
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
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _skeletonBaseColor,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 8),
          ),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: context.cardDecoration,
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
        decoration: context.cardDecoration,
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
      borderRadius: BorderRadius.circular(context.borderRadiusLarge),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingLarge,
          vertical: context.spacingMedium,
        ),
        decoration: context.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: context.spacingSmall),
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
      borderRadius: BorderRadius.circular(context.borderRadiusLarge),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingLarge,
          vertical: context.spacingMedium,
        ),
        decoration: context.cardDecoration,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 22),
                  SizedBox(height: context.spacingSmall),
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
