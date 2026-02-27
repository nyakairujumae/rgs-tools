import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/web/web_sidebar.dart';
import '../../widgets/web/web_app_bar.dart';
import './web_shell.dart';
import '../../providers/admin_notification_provider.dart';
import '../../providers/pending_approvals_provider.dart';
import '../../providers/tool_issue_provider.dart';
import '../admin/admin_dashboard_web.dart';
import '../admin/tools_management_web.dart';
import '../../screens/admin_home_screen.dart';
import '../../screens/tools_screen.dart';
import '../../screens/technicians_screen.dart';
import '../../screens/shared_tools_screen.dart';
import '../../screens/tool_issues_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/approval_workflows_screen.dart';
import '../../screens/maintenance_screen.dart';
import '../../screens/all_tool_history_screen.dart';

/// Admin web layout with sidebar navigation
/// Wraps admin screens in the WebShell with admin-specific navigation
class AdminWebLayout extends StatefulWidget {
  final int initialRoute;

  const AdminWebLayout({
    Key? key,
    this.initialRoute = 0,
  }) : super(key: key);

  @override
  State<AdminWebLayout> createState() => _AdminWebLayoutState();
}

class _AdminWebLayoutState extends State<AdminWebLayout> {
  late int _selectedIndex;
  late String _currentRoute;

  // Map of routes to screen indices
  final Map<String, int> _routeToIndex = {
    '/admin': 0,
    '/admin/dashboard': 0,
    '/admin/tools': 1,
    '/admin/technicians': 2,
    '/admin/shared': 3,
    '/admin/issues': 4,
    '/admin/reports': 5,
    '/admin/approvals': 6,
    '/admin/maintenance': 7,
    '/admin/history': 8,
  };

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialRoute;
    _currentRoute = _indexToRoute(_selectedIndex);
  }

  String _indexToRoute(int index) {
    switch (index) {
      case 0:
        return '/admin/dashboard';
      case 1:
        return '/admin/tools';
      case 2:
        return '/admin/technicians';
      case 3:
        return '/admin/shared';
      case 4:
        return '/admin/issues';
      case 5:
        return '/admin/reports';
      case 6:
        return '/admin/approvals';
      case 7:
        return '/admin/maintenance';
      case 8:
        return '/admin/history';
      default:
        return '/admin/dashboard';
    }
  }

  void _navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _currentRoute = _indexToRoute(index);
    });
  }

  List<WebNavItem> _getNavItems(BuildContext context) {
    final notificationProvider = context.watch<AdminNotificationProvider>();
    final approvalsProvider = context.watch<PendingApprovalsProvider>();
    final issueProvider = context.watch<ToolIssueProvider>();

    final unreadCount = notificationProvider.unreadCount;
    final pendingApprovalsCount = approvalsProvider.pendingApprovals.length;
    final openIssuesCount = issueProvider.openIssues.length;

    return [
      const WebNavItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/admin/dashboard',
      ),
      const WebNavItem(
        icon: Icons.build,
        label: 'Tools',
        route: '/admin/tools',
      ),
      const WebNavItem(
        icon: Icons.people,
        label: 'Technicians',
        route: '/admin/technicians',
      ),
      const WebNavItem(
        icon: Icons.share,
        label: 'Shared Tools',
        route: '/admin/shared',
      ),
      WebNavItem(
        icon: Icons.warning,
        label: 'Issues',
        route: '/admin/issues',
        badge: openIssuesCount > 0 ? openIssuesCount : null,
      ),
      const WebNavItem(
        icon: Icons.assessment,
        label: 'Reports',
        route: '/admin/reports',
      ),
      WebNavItem(
        icon: Icons.check_circle,
        label: 'Approvals',
        route: '/admin/approvals',
        badge: pendingApprovalsCount > 0 ? pendingApprovalsCount : null,
      ),
      const WebNavItem(
        icon: Icons.build_circle,
        label: 'Maintenance',
        route: '/admin/maintenance',
      ),
      const WebNavItem(
        icon: Icons.history,
        label: 'History',
        route: '/admin/history',
      ),
    ];
  }

  Widget _getScreen(int index) {
    // Web-optimized screens for admin
    switch (index) {
      case 0:
        // Dashboard - web-optimized dashboard
        return const AdminDashboardWeb();
      case 1:
        // Equipment - enterprise data table
        return const ToolsManagementWeb();
      case 2:
        return const TechniciansScreen();
      case 3:
        return const SharedToolsScreen();
      case 4:
        return const ToolIssuesScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const ApprovalWorkflowsScreen();
      case 7:
        return const MaintenanceScreen();
      case 8:
        return const AllToolHistoryScreen();
      default:
        return const Center(child: Text('Screen not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      currentRoute: _currentRoute,
      navItems: _getNavItems(context),
      sidebarFooter: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SidebarThemeToggle(collapsed: false),
          SidebarUserProfile(collapsed: false),
        ],
      ),
      child: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _getScreen(_selectedIndex),
            settings: settings,
          );
        },
      ),
    );
  }
}
