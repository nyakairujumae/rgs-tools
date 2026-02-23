import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_tool_provider.dart';
import '../../providers/supabase_technician_provider.dart';
import '../../providers/tool_issue_provider.dart';
import '../../providers/pending_approvals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/web/web_stat_cards.dart';
import '../../theme/app_theme.dart';
import '../../models/tool.dart';
import '../../models/tool_history.dart';
import '../../services/tool_history_service.dart';
import '../../screens/add_tool_screen.dart';
import '../../screens/assign_tool_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/tool_detail_screen.dart';
import '../../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

/// Professional admin dashboard for web desktop
class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({Key? key}) : super(key: key);

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  List<ToolHistory> _recentHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ToolHistoryService.getAllHistory(limit: 10);
      if (mounted) {
        setState(() {
          _recentHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<SupabaseToolProvider>().loadTools();
        await context.read<SupabaseTechnicianProvider>().loadTechnicians();
        await context.read<ToolIssueProvider>().loadIssues();
        await _loadRecentHistory();
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),

            // Stat Cards
            _buildStatCards(context),
            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // Two-column layout for activity and tools
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Activity (left)
                Expanded(
                  flex: 2,
                  child: _buildRecentActivity(context),
                ),
                const SizedBox(width: 24),

                // Tools Needing Attention (right)
                Expanded(
                  flex: 1,
                  child: _buildToolsNeedingAttention(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName =
        authProvider.user?.userMetadata?['full_name'] as String? ??
            authProvider.user?.email?.split('@').first ??
            'Admin';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s what\'s happening with your tools today',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildStatCards(BuildContext context) {
    final toolProvider = context.watch<SupabaseToolProvider>();
    final issueProvider = context.watch<ToolIssueProvider>();
    final approvalProvider = context.watch<PendingApprovalsProvider>();

    final totalTools = toolProvider.tools.length;
    final availableTools =
        toolProvider.tools.where((t) => t.status == 'Available').length;
    final checkedOutTools =
        toolProvider.tools.where((t) => t.status == 'Assigned').length;
    final openIssues = issueProvider.openIssues.length;
    final pendingApprovals = approvalProvider.pendingApprovals.length;

    final stats = [
      StatCardData(
        label: 'Total Tools',
        value: totalTools.toString(),
        icon: Icons.build,
        iconColor: AppTheme.primaryColor,
        subtitle: CurrencyFormatter.formatCurrency(toolProvider.getTotalValue()),
        onTap: () => Navigator.pushNamed(context, '/admin/tools'),
      ),
      StatCardData(
        label: 'Available',
        value: availableTools.toString(),
        icon: Icons.check_circle,
        iconColor: AppTheme.successColor,
        subtitle:
            '${((availableTools / (totalTools > 0 ? totalTools : 1)) * 100).toStringAsFixed(0)}% of total',
        onTap: () => Navigator.pushNamed(context, '/admin/tools'),
      ),
      StatCardData(
        label: 'Checked Out',
        value: checkedOutTools.toString(),
        icon: Icons.assignment,
        iconColor: AppTheme.warningColor,
        subtitle:
            '${((checkedOutTools / (totalTools > 0 ? totalTools : 1)) * 100).toStringAsFixed(0)}% of total',
        onTap: () => Navigator.pushNamed(context, '/admin/tools'),
      ),
      StatCardData(
        label: 'Open Issues',
        value: openIssues.toString(),
        icon: Icons.warning,
        iconColor: AppTheme.errorColor,
        subtitle: pendingApprovals > 0
            ? '$pendingApprovals pending approvals'
            : 'No pending approvals',
        onTap: () => Navigator.pushNamed(context, '/admin/issues'),
      ),
    ];

    return WebStatCards(stats: stats);
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionButton(
              icon: Icons.add,
              label: 'Add Tool',
              color: AppTheme.primaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddToolScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.assignment_turned_in,
              label: 'Assign Tool',
              color: AppTheme.secondaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AssignToolScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.assessment,
              label: 'View Reports',
              color: AppTheme.warningColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.sync,
              label: 'Refresh Data',
              color: Colors.blue,
              onPressed: () async {
                await context.read<SupabaseToolProvider>().loadTools();
                await context.read<SupabaseTechnicianProvider>().loadTechnicians();
                await context.read<ToolIssueProvider>().loadIssues();
                await _loadRecentHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data refreshed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppTheme.cardSurfaceColor(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.webDarkCardBorder
              : AppTheme.webLightCardBorder,
        ),
        boxShadow: AppTheme.getCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View All'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/history');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recentHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentHistory.length,
                separatorBuilder: (context, index) => Divider(
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                  height: 24,
                ),
                itemBuilder: (context, index) {
                  final history = _recentHistory[index];
                  return _ActivityItem(history: history);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsNeedingAttention(BuildContext context) {
    final toolProvider = context.watch<SupabaseToolProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppTheme.cardSurfaceColor(context);

    final toolsNeedingMaintenance = toolProvider.getToolsNeedingMaintenance();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.webDarkCardBorder
              : AppTheme.webLightCardBorder,
        ),
        boxShadow: AppTheme.getCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.priority_high,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (toolsNeedingMaintenance.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppTheme.successColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All good!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No tools need attention',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    toolsNeedingMaintenance.length > 5 ? 5 : toolsNeedingMaintenance.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tool = toolsNeedingMaintenance[index];
                  return _ToolAttentionItem(tool: tool);
                },
              ),
            if (toolsNeedingMaintenance.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/maintenance');
                  },
                  child: Text(
                      'View ${toolsNeedingMaintenance.length - 5} more'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ToolHistory history;

  const _ActivityItem({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getActionColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActionIcon(),
            color: _getActionColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.action,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                history.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                history.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getActionIcon() {
    final action = history.action.toLowerCase();
    if (action.contains('create') || action.contains('add')) {
      return Icons.add_circle;
    } else if (action.contains('assign')) {
      return Icons.assignment;
    } else if (action.contains('return')) {
      return Icons.assignment_return;
    } else if (action.contains('update') || action.contains('edit')) {
      return Icons.edit;
    } else if (action.contains('delete')) {
      return Icons.delete;
    }
    return Icons.info;
  }

  Color _getActionColor() {
    final action = history.action.toLowerCase();
    if (action.contains('create') || action.contains('add')) {
      return AppTheme.successColor;
    } else if (action.contains('assign')) {
      return AppTheme.primaryColor;
    } else if (action.contains('return')) {
      return AppTheme.secondaryColor;
    } else if (action.contains('delete')) {
      return AppTheme.errorColor;
    }
    return Colors.blue;
  }
}

class _ToolAttentionItem extends StatelessWidget {
  final Tool tool;

  const _ToolAttentionItem({required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailScreen(tool: tool),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.build_circle,
              color: AppTheme.warningColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Maintenance due',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
