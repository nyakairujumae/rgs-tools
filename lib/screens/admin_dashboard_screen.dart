import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../services/report_service.dart';
import 'tools_screen.dart';
import 'add_tool_screen.dart';
import 'checkin_screen.dart';
import 'reports_screen.dart';
import 'report_detail_screen.dart';
import 'maintenance_screen.dart';
import 'approval_workflows_screen.dart';
import 'tool_issues_screen.dart';
import 'all_tool_history_screen.dart';
import 'admin_approval_screen.dart';
import '../l10n/app_localizations.dart';

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final Function(String) onNavigateToToolsWithFilter;
  static const double _cardRadiusValue = 12; // Apple/Jobber-style web (matches global theme)
  static const double _mobileCardRadiusValue = 16; // Keep mobile rounded
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
        // Show skeleton only when actually loading (provider has no data yet)
        final isLoadingDashboard = toolProvider.isLoading && tools.isEmpty;
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
              if (isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Offline — showing cached data',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
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
                                    style: statValueStyle.copyWith(color: AppTheme.secondaryColor),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.people,
                                  AppTheme.secondaryColor,
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
                                    CupertinoPageRoute(
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
                                    CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                            AppTheme.secondaryColor,
                            () => Navigator.push(
                              context,
                              CupertinoPageRoute(
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
                                  CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                              CupertinoPageRoute(
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
                    CupertinoPageRoute(
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
                    CupertinoPageRoute(
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
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AddToolScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Assign Tool',
            Icons.person_add_rounded,
            AppTheme.secondaryColor,
            () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const ToolsScreen(isSelectionMode: true)),
            ),
            showDivider: true,
          ),
          Consumer<PendingApprovalsProvider>(
            builder: (context, provider, _) => _buildWebActionRow(
              context,
              'Authorize Users',
              Icons.verified_user_rounded,
              AppTheme.primaryColor,
              () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AdminApprovalScreen())),
              showDivider: true,
              badgeCount: provider.pendingCount,
            ),
          ),
          _buildWebActionRow(
            context,
            'Reports',
            Icons.analytics_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const ReportsScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Tool Issues',
            Icons.report_problem_rounded,
            AppTheme.errorColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const ToolIssuesScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Approvals',
            Icons.task_alt_rounded,
            AppTheme.warningColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const ApprovalWorkflowsScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Maintenance Schedule',
            Icons.schedule_rounded,
            AppTheme.secondaryColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const MaintenanceScreen())),
            showDivider: true,
          ),
          _buildWebActionRow(
            context,
            'Tool History',
            Icons.history_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AllToolHistoryScreen())),
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
              CupertinoPageRoute(
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
              CupertinoPageRoute(
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
              color: AppTheme.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.borderRadiusLarge),
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
                AppTheme.secondaryColor,
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
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const AddToolScreen()));
        }),
        _buildB2BQuickAction(context, 'Assign Tool', Icons.person_add, AppTheme.secondaryColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ToolsScreen(isSelectionMode: true)));
        }),
        Consumer<PendingApprovalsProvider>(
          builder: (context, provider, _) => _buildB2BQuickAction(
            context,
            'Authorize Users',
            Icons.verified_user,
            AppTheme.primaryColor,
            () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AdminApprovalScreen())),
            badgeCount: provider.pendingCount,
          ),
        ),
        _buildB2BQuickAction(context, 'Reports', Icons.analytics, AppTheme.primaryColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ReportsScreen()));
        }),
        _buildB2BQuickAction(context, 'Tool Issues', Icons.report_problem, AppTheme.errorColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ToolIssuesScreen()));
        }),
        _buildB2BQuickAction(context, 'Approvals', Icons.approval, AppTheme.warningColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ApprovalWorkflowsScreen()));
        }),
        _buildB2BQuickAction(context, 'Maintenance Schedule', Icons.schedule, AppTheme.secondaryColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const MaintenanceScreen()));
        }),
        _buildB2BQuickAction(context, 'Tool History', Icons.history, AppTheme.primaryColor, () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const AllToolHistoryScreen()));
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
        decoration: isWebLayout
            ? context.cardDecoration
            : context.cardDecoration.copyWith(
                border: Border(
                  left: BorderSide(color: color, width: 3.5),
                  top: BorderSide(color: AppTheme.getCardBorderSubtle(context), width: 0.5),
                  right: BorderSide(color: AppTheme.getCardBorderSubtle(context), width: 0.5),
                  bottom: BorderSide(color: AppTheme.getCardBorderSubtle(context), width: 0.5),
                ),
              ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      iconBadge,
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                      ),
                      Flexible(
                        child: Text(
                          title,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 10),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: valueWidget,
                      ),
                    ),
                  ),
                ],
              ),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
                              color: AppTheme.badgeColor,
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
