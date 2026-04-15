import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_approvals_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/supabase_certification_provider.dart';
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
import 'calibration_screen.dart';
import 'compliance_screen.dart';
import 'technician_my_tools_screen.dart';
import 'admin_management_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/tool.dart';
import '../models/tool_history.dart';
import '../services/tool_history_service.dart';

class _MobileAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MobileAction(this.title, this.icon, this.color, this.onTap);
}

// Dashboard Screen for Admin
class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final Function(String) onNavigateToToolsWithFilter;
  static const double _cardRadiusValue = 12; // Apple/Jobber-style web (matches global theme)
  static const double _mobileCardRadiusValue = 16; // Keep mobile rounded
  static const Color _dashboardGreen = AppTheme.primaryColor;
  static Color _skeletonBase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1);
  }

  static Color _skeletonHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF323232) : const Color(0xFFD8DBE0);
  }
  
  double _getCardRadius(BuildContext context) {
    return ResponsiveHelper.isWeb ? _cardRadiusValue : _mobileCardRadiusValue;
  }

  /// Single source of truth for all mobile cards — white surface, hairline border (matches web).
  BoxDecoration _mobileCardDeco(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF141414) : Colors.white,
    borderRadius: BorderRadius.circular(_mobileCardRadiusValue),
    boxShadow: isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
  );

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
        final issueProvider = context.watch<ToolIssueProvider>();
        final certProvider = context.watch<SupabaseCertificationProvider>();
        final statValueStyle = TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        );
        final statValueStyleSmall = TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
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

        return RefreshIndicator(
          color: const Color(0xFF2E7D32),
          strokeWidth: 2.5,
          onRefresh: () async {
            await Future.wait<void>([
              toolProvider.loadTools(),
              technicianProvider.loadTechnicians(),
              connectivityProvider.recheckConnectivity(),
            ]);
          },
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    minimum: const EdgeInsets.only(top: 12),
                    child: greetingCard,
                  ),

                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                  ),

                  // Stats Grid - mobile uses grid
                  isLoadingDashboard
                      ? _buildMetricsSkeleton(context)
                      : GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 10),
                              mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 10),
                              childAspectRatio: 1.8,
                              children: [
                                _buildStatCard(
                                  'Total Tools',
                                  Text(
                                    totalTools.toString(),
                                    style: statValueStyle.copyWith(color: Colors.blue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.build,
                                  Colors.blue,
                                  context,
                                  () => onNavigateToTab(1),
                                  subtitle: CurrencyFormatter.formatCurrencyWhole(totalValue),
                                ),
                                _buildStatCard(
                                  'Available',
                                  Text(
                                    availableTools.length.toString(),
                                    style: statValueStyle.copyWith(color: const Color(0xFF059669)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.build,
                                  const Color(0xFF059669),
                                  context,
                                  () => onNavigateToToolsWithFilter('Available'),
                                  subtitle: totalTools > 0
                                      ? '${((availableTools.length / totalTools) * 100).round()}% of total'
                                      : '0% of total',
                                ),
                                _buildStatCard(
                                  'In Use',
                                  Text(
                                    assignedTools.length.toString(),
                                    style: statValueStyle.copyWith(color: const Color(0xFF7C3AED)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.build,
                                  const Color(0xFF7C3AED),
                                  context,
                                  () => onNavigateToToolsWithFilter('Assigned'),
                                  subtitle: '${toolsNeedingMaintenance.length} in maintenance',
                                ),
                                _buildStatCard(
                                  'Open Issues',
                                  Text(
                                    '${issueProvider.openIssuesCount}',
                                    style: statValueStyle.copyWith(
                                      color: issueProvider.criticalIssuesCount > 0
                                          ? Colors.red
                                          : Colors.amber.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icons.report_problem_rounded,
                                  issueProvider.criticalIssuesCount > 0 ? Colors.red : Colors.amber.shade700,
                                  context,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ToolIssuesScreen(),
                                    ),
                                  ),
                                  subtitle: issueProvider.criticalIssuesCount > 0
                                      ? '${issueProvider.criticalIssuesCount} critical'
                                      : 'No critical issues',
                                ),
                              ],
                            ),

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 10)),

                  // Secondary KPI row
                  isLoadingDashboard
                      ? _buildMetricsSkeleton(context, childAspectRatio: 2.0)
                      : GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 10),
                          mainAxisSpacing: ResponsiveHelper.getResponsiveGridSpacing(context, 10),
                          childAspectRatio: 2.0,
                          children: [
                            _buildStatCard(
                              'Compliance',
                              Text(
                                '${certProvider.complianceCerts.length}',
                                style: statValueStyleSmall.copyWith(
                                  color: certProvider.complianceCerts.any((c) => c.isExpired || c.isExpiringSoon)
                                      ? Colors.orange
                                      : const Color(0xFF059669),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icons.verified_rounded,
                              certProvider.complianceCerts.any((c) => c.isExpired || c.isExpiringSoon)
                                  ? Colors.orange
                                  : const Color(0xFF059669),
                              context,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplianceScreen())),
                              subtitle: () {
                                final alerts = certProvider.complianceCerts.where((c) => c.isExpired || c.isExpiringSoon).length;
                                return alerts > 0 ? '$alerts expiring/expired' : 'All valid';
                              }(),
                            ),
                            _buildStatCard(
                              'Calibration',
                              Text(
                                '${certProvider.calibrationCerts.length}',
                                style: statValueStyleSmall.copyWith(
                                  color: certProvider.calibrationCerts.any((c) => c.isExpired || c.isExpiringSoon)
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icons.precision_manufacturing_rounded,
                              certProvider.calibrationCerts.any((c) => c.isExpired || c.isExpiringSoon)
                                  ? Colors.red
                                  : Colors.blue,
                              context,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalibrationScreen())),
                              subtitle: () {
                                final due = certProvider.calibrationCerts.where((c) => c.isExpired || c.isExpiringSoon).length;
                                return due > 0 ? '$due due/overdue' : 'All current';
                              }(),
                            ),
                            _buildStatCard(
                              'Maintenance',
                              Text(
                                '${toolsNeedingMaintenance.length}',
                                style: statValueStyleSmall.copyWith(
                                  color: toolsNeedingMaintenance.isEmpty ? Colors.teal : Colors.orange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icons.build_rounded,
                              toolsNeedingMaintenance.isEmpty ? Colors.teal : Colors.orange,
                              context,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
                              subtitle: toolsNeedingMaintenance.isEmpty ? 'All healthy' : 'Need attention',
                            ),
                            _buildStatCard(
                              'Asset Value',
                              Text(
                                CurrencyFormatter.formatCurrencyWhole(totalValue),
                                style: statValueStyleSmall.copyWith(
                                  color: const Color(0xFF059669),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icons.account_balance_wallet_rounded,
                              const Color(0xFF059669),
                              context,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(reportType: ReportType.financialSummary, timePeriod: 'Last 30 Days'))),
                              subtitle: 'Across $totalTools tools',
                            ),
                          ],
                        ),

                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

                  // Quick Actions (mobile only; web has it in side-by-side section above)
                  if (!isWideLayout) ...[
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingDashboard)
                    _buildQuickActionsSkeleton(context)
                  else
                    _buildMobileQuickActionsGroup(context),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 28)),
                  const SizedBox(height: 4),
                  const _RecentActivityFeed(),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 28)),
                  Text(
                    'Needs Attention',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNeedsAttentionCard(
                    context,
                    issueProvider: issueProvider,
                    toolsNeedingMaintenance: toolsNeedingMaintenance,
                  ),
                  ],  // end if (!isWideLayout) Quick Actions section
                  ],  // end else (mobile Key Metrics + Quick Actions)
                ],
              ),
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
                              child: GestureDetector(
                                onTap: () => onNavigateToToolsWithFilter('Available'),
                                behavior: HitTestBehavior.opaque,
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
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => onNavigateToToolsWithFilter('Assigned'),
                                behavior: HitTestBehavior.opaque,
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
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
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
            'Requests',
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

    // Mobile: clean text header — matches web style
    final displayName = _resolveDisplayName(authProvider);
    final firstName = _getFirstName(displayName);
    final greeting = firstName.isEmpty
        ? '${_getGreeting()}!'
        : '${_getGreeting()}, $firstName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30),
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening with your tools today",
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
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
    final onSurface = theme.colorScheme.onSurface;
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

    // Mobile: single card with Assigned on top, divider, Available below
    final dividerColor = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _mobileCardDeco(isDark),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onNavigateToToolsWithFilter('Assigned'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text('Assigned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface.withValues(alpha: 0.6))),
                const Spacer(),
                Text(assignedCount.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.blue, letterSpacing: -0.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: dividerColor),
          ),
          GestureDetector(
            onTap: () => onNavigateToToolsWithFilter('Available'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _dashboardGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text('Available', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface.withValues(alpha: 0.6))),
                const Spacer(),
                Text(availableCount.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _dashboardGreen, letterSpacing: -0.5)),
              ],
            ),
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
        _buildB2BQuickAction(context, 'Reports', Icons.analytics, AppTheme.primaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
        }),
        _buildB2BQuickAction(context, 'Tool Issues', Icons.report_problem, AppTheme.errorColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen()));
        }),
        _buildB2BQuickAction(context, 'Requests', Icons.approval, AppTheme.warningColor, () {
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
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
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
                color: _skeletonBase(context),
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

  Widget _buildMetricsSkeleton(BuildContext context, {double childAspectRatio = 1.8}) {
    final isWeb = ResponsiveHelper.isWeb;
    
    // Web uses horizontal row skeleton
    if (isWeb && ResponsiveHelper.isDesktop(context)) {
      return Shimmer.fromColors(
        baseColor: _skeletonBase(context),
        highlightColor: _skeletonHighlight(context),
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
                        color: _skeletonBase(context),
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
    
    // Mobile uses grid skeleton — matches _buildMobileStatCardContent layout
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
      period: const Duration(milliseconds: 1500),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
        children: List.generate(
          6,
          (_) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: _mobileCardDeco(isDark),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSkeletonLine(context, widthFactor: 0.55, height: 8),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(context, widthFactor: 0.65, height: 20),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(context, widthFactor: 0.7, height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _skeletonBase(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
      period: const Duration(milliseconds: 1500),
      child: Column(
        children: [
          _buildQuickActionSkeletonRow(context, 2),
          const SizedBox(height: 12),
          _buildQuickActionSkeletonRow(context, 2),
          const SizedBox(height: 12),
          _buildQuickActionSkeletonRow(context, 2),
          const SizedBox(height: 12),
          _buildQuickActionSkeletonRow(context, 2),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewSkeleton(
      BuildContext context, BorderRadius cardRadius) {
    final isWeb = ResponsiveHelper.isWeb;
    return Shimmer.fromColors(
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
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
        children.add(const SizedBox(width: 12));
      }
    }
    return Row(children: children);
  }

  Widget _buildQuickActionSkeletonTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _mobileCardDeco(isDark),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _skeletonBase(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSkeletonLine(context, widthFactor: 0.55, height: 13),
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
          color: _skeletonBase(context),
          borderRadius: BorderRadius.circular(isWeb ? 4 : 8),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, Widget valueWidget, IconData icon, Color color,
      BuildContext context, VoidCallback? onTap, {String? subtitle}) {
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
    final iconBadge = isWebLayout
      ? Container(
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
        )
      : Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: isWebLayout ? EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ) : EdgeInsets.zero,
        decoration: isWebLayout ? context.cardDecoration : null,
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
            : _buildMobileStatCardContent(context, title, valueWidget, iconBadge, color, subtitle: subtitle),
      ),
    );
  }

  /// Mobile stat card — web-style: white surface, tinted icon badge, subtitle line.
  Widget _buildMobileStatCardContent(
    BuildContext context,
    String title,
    Widget valueWidget,
    Widget iconBadge,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _mobileCardDeco(isDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: valueWidget,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: onSurface.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          iconBadge,
        ],
      ),
    );
  }

  Widget _buildStatusItem(
      String status, String count, Color color, BuildContext context, {VoidCallback? onTap}) {
    final isWebLayout = ResponsiveHelper.isWeb;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = _getCardRadius(context);

    if (isWebLayout) {
      // Web: clean inline status with colour dot
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
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
        ),
      );
    }

    // Mobile: compact status with dot indicator
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
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

  /// Mobile-only: 2-column grid of quick action cards
  Widget _buildMobileQuickActionsGroup(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actions = <_MobileAction>[
      _MobileAction('My Tools', Icons.build, Colors.indigo, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianMyToolsScreen()));
      }),
      _MobileAction('Manage Admins', Icons.admin_panel_settings_rounded, AppTheme.secondaryColor, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManagementScreen()));
      }),
      _MobileAction('Add Tool', Icons.build, AppTheme.primaryColor, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddToolScreen()));
      }),
      _MobileAction('Assign Tool', Icons.person_add_rounded, _dashboardGreen, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen(isSelectionMode: true)));
      }),
      _MobileAction('Reports', Icons.analytics_rounded, Colors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
      }),
      _MobileAction('Tool Issues', Icons.report_problem_rounded, Colors.red, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen()));
      }),
      _MobileAction('Requests', Icons.approval_rounded, Colors.amber.shade700, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalWorkflowsScreen()));
      }),
      _MobileAction('Tool History', Icons.history_rounded, Colors.indigo, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AllToolHistoryScreen()));
      }),
    ];

    final allCards = <Widget>[
      for (final a in actions)
        _buildMobileActionGridCard(
          context,
          title: a.title,
          icon: a.icon,
          color: a.color,
          onTap: a.onTap,
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: allCards,
    );
  }

  Widget _buildMobileActionGridCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: _mobileCardDeco(isDark),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.badgeColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFEEEEF2),
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

  Widget _buildNeedsAttentionCard(
    BuildContext context, {
    required ToolIssueProvider issueProvider,
    required List<Tool> toolsNeedingMaintenance,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final urgentIssues = [
      ...issueProvider.criticalIssues.where((i) => i.isOpen || i.isInProgress),
      ...issueProvider.highPriorityIssues.where((i) => (i.isOpen || i.isInProgress) && !i.isCritical),
    ].take(3).toList();

    final maintenanceTools = toolsNeedingMaintenance.take(2).toList();

    final allEmpty = urgentIssues.isEmpty && maintenanceTools.isEmpty;

    final cardDeco = BoxDecoration(
      color: isDark ? const Color(0xFF141414) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
    final dividerColor = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;

    if (allEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: cardDeco,
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text('All good!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
            const SizedBox(height: 2),
            Text('No items need attention', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.45))),
          ],
        ),
      );
    }

    final tiles = <Widget>[];

    for (int i = 0; i < urgentIssues.length; i++) {
      final issue = urgentIssues[i];
      final isCritical = issue.isCritical;
      tiles.add(
        _buildAttentionTile(
          context,
          icon: Icons.warning_amber_rounded,
          iconColor: isCritical ? Colors.red : Colors.orange,
          title: issue.toolName,
          subtitle: '${issue.issueType} · ${issue.description.length > 50 ? '${issue.description.substring(0, 50)}…' : issue.description}',
          badge: isCritical ? 'Critical' : 'High',
          badgeColor: isCritical ? Colors.red : Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolIssuesScreen())),
        ),
      );
      if (i < urgentIssues.length - 1 || maintenanceTools.isNotEmpty) {
        tiles.add(Divider(height: 1, thickness: 1, indent: 56, endIndent: 16, color: dividerColor));
      }
    }

    for (int i = 0; i < maintenanceTools.length; i++) {
      final tool = maintenanceTools[i];
      tiles.add(
        _buildAttentionTile(
          context,
          icon: Icons.build_rounded,
          iconColor: Colors.deepOrange,
          title: tool.name,
          subtitle: 'Maintenance required',
          badge: 'Overdue',
          badgeColor: Colors.deepOrange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
        ),
      );
      if (i < maintenanceTools.length - 1) {
        tiles.add(Divider(height: 1, thickness: 1, indent: 56, endIndent: 16, color: dividerColor));
      }
    }

    return Container(
      decoration: cardDeco,
      child: Column(children: tiles),
    );
  }

  Widget _buildAttentionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
          ],
        ),
      ),
    );
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

// ──────────────────────────────────────────────
// Recent Activity Feed (mobile dashboard only)
// ──────────────────────────────────────────────

class _RecentActivityFeed extends StatefulWidget {
  const _RecentActivityFeed();

  @override
  State<_RecentActivityFeed> createState() => _RecentActivityFeedState();
}

class _RecentActivityFeedState extends State<_RecentActivityFeed> {
  static const int _activityFetchLimit = 1000;

  static Color _skeletonBase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1);
  }

  static Color _skeletonHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF323232) : const Color(0xFFD8DBE0);
  }

  (Color, IconData) _actionStyle(String action) {
    return switch (action) {
      'Assigned' || 'Accepted Assignment' => (Colors.blue, Icons.person_add_rounded),
      'Returned' || 'Released to Requester' => (AppTheme.primaryColor, Icons.assignment_return_rounded),
      'Maintenance' => (Colors.orange, Icons.build_rounded),
      'Created' => (AppTheme.primaryColor, Icons.add_circle_rounded),
      'Updated' || 'Edited' => (Colors.blueGrey, Icons.edit_rounded),
      'Status Changed' => (Colors.purple, Icons.swap_horiz_rounded),
      'Deleted' => (Colors.red, Icons.delete_rounded),
      'Transferred' => (Colors.teal, Icons.swap_horizontal_circle_rounded),
      _ => (Colors.blueGrey, Icons.history_rounded),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final cardDeco = BoxDecoration(
      color: isDark ? const Color(0xFF141414) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? AppTheme.webDarkCardBorder : AppTheme.webLightCardBorder,
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
    final dividerColor = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;

    return FutureBuilder<List<ToolHistory>>(
      // Fetch fresh data on every dashboard rebuild so new activities
      // (e.g., added tools) are visible immediately after returning.
      future: ToolHistoryService.getAllHistory(limit: _activityFetchLimit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(context, cardDeco);
        }

        final items = snapshot.data ?? [];
        return Container(
          decoration: cardDeco,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllToolHistoryScreen()),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                )
              else
                ...[
                  for (int i = 0; i < items.length; i++) ...[
                    _buildTile(context, items[i], onSurface, isDark),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 62,
                        endIndent: 16,
                        color: dividerColor,
                      ),
                  ],
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    ToolHistory entry,
    Color onSurface,
    bool isDark,
  ) {
    final (color, icon) = _actionStyle(entry.action);
    final performedByText = (entry.performedBy != null && entry.performedBy!.isNotEmpty)
        ? ' · ${entry.performedBy}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.toolName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.actionDisplayName}$performedByText',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, BoxDecoration cardDeco) {
    final base = _skeletonBase(context);
    final highlight = _skeletonHighlight(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1500),
      child: Container(
        decoration: cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row matching real card
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 64,
                    height: 12,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            ...List.generate(4, (i) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 100,
                              height: 10,
                              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 10,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
                if (i < 3) Divider(height: 1, thickness: 0.5, color: dividerColor, indent: 62),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
