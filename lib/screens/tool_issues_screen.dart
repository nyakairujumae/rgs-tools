import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../models/tool_issue.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import 'add_tool_issue_screen.dart';
import '../utils/responsive_helper.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auth_provider.dart';

class ToolIssuesScreen extends StatefulWidget {
  const ToolIssuesScreen({super.key});

  @override
  State<ToolIssuesScreen> createState() => _ToolIssuesScreenState();
}

class _ToolIssuesScreenState extends State<ToolIssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final VoidCallback _tabListener;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Recent';

  final List<String> _filters = [
    'All',
    'Open',
    'Critical',
    'Resolved',
  ];
  final List<String> _sortOptions = ['Recent', 'Priority', 'Type', 'Age'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabListener = () {
      if (!_tabController.indexIsChanging &&
          _tabController.index >= 0 &&
          _tabController.index < _filters.length) {
        setState(() {
          _selectedFilter = _filters[_tabController.index];
        });
      }
    };
    _tabController.addListener(_tabListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolIssueProvider>().loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kIsWeb ? 900 : double.infinity,
            ),
            child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildFilterPills(),
            Expanded(
              child: Consumer3<ToolIssueProvider, ConnectivityProvider, AuthProvider>(
                builder: (context, issueProvider, connectivityProvider, authProvider, child) {
                  final isOffline = !connectivityProvider.isOnline;
                  final isAdmin = authProvider.isAdmin;
                  final currentUserId = authProvider.userId;

                  List<ToolIssue> forUser(List<ToolIssue> all) {
                    if (isAdmin) return all;
                    return all.where((i) => i.reportedByUserId == currentUserId).toList();
                  }

                  Widget content;
                  if (issueProvider.isLoading) {
                    content = _buildIssuesSkeleton(context);
                  } else if (issueProvider.error != null) {
                    content = Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading issues',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              issueProvider.error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () => issueProvider.loadIssues(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.secondaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Retry'),
                              ),
                              if (issueProvider.error!.contains('Session expired') ||
                                  issueProvider.error!.contains('Please log in'))
                                const SizedBox(width: 16),
                              if (issueProvider.error!.contains('Session expired') ||
                                  issueProvider.error!.contains('Please log in'))
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/role-selection',
                                      (route) => false
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Sign In'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    content = TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIssuesList(forUser(issueProvider.issues)),
                        _buildIssuesList(forUser(issueProvider.openIssues)),
                        _buildIssuesList(forUser(issueProvider.criticalIssues)),
                        _buildIssuesList(forUser(issueProvider.resolvedIssues)),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(kIsWeb ? 24 : 16, 8, kIsWeb ? 24 : 16, 20),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddToolIssueScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Report New Issue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1);
    final highlight = isDark ? const Color(0xFF323232) : const Color(0xFFD8DBE0);

    Widget line(double w, {double h = 11}) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
          ),
        );

    Widget card() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(double.infinity, h: 13),
                      const SizedBox(height: 6),
                      line(140, h: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [line(70, h: 22), const SizedBox(width: 8), line(60, h: 22), const SizedBox(width: 8), line(55, h: 22)]),
            const SizedBox(height: 10),
            line(double.infinity, h: 10),
            const SizedBox(height: 5),
            line(200, h: 10),
            const SizedBox(height: 8),
            line(160, h: 9),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => card(),
    );
  }

  Widget _buildIssuesList(List<ToolIssue> issues) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No issues found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All tools are working properly!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort issues based on selected sort option
    final searchTerm = _searchQuery.trim().toLowerCase();
    final filteredIssues = searchTerm.isEmpty
        ? issues
        : issues.where((issue) {
            final haystack = [
              issue.toolName,
              issue.issueType,
              issue.reportedBy,
            ].join(' ').toLowerCase();
            return haystack.contains(searchTerm);
          }).toList();
    final sortedIssues = _sortIssues(filteredIssues);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return RefreshIndicator(
      onRefresh: () => context.read<ToolIssueProvider>().loadIssues(),
      color: AppTheme.secondaryColor,
      backgroundColor: context.scaffoldBackground,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16,
          isDesktop ? 20 : 16,
          isDesktop ? 24 : 16,
          120,
        ),
        itemCount: sortedIssues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final issue = sortedIssues[index];
          return _buildPremiumIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildPremiumIssueCard(ToolIssue issue) {
    final theme = Theme.of(context);
    final letter =
        issue.toolName.isNotEmpty ? issue.toolName[0].toUpperCase() : '?';
    final details = [
      '#${issue.toolId}',
      if (issue.location != null && issue.location!.isNotEmpty)
        issue.location!,
    ].join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showIssueDetails(issue),
      child: Container(
        decoration: context.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.toolName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildIssueTypePill(issue.issueType),
                _buildPriorityPill(issue.priority),
                _buildStatusOutlineChip(issue.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Reported by ${issue.reportedBy} • ${issue.ageText}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(ToolIssue originalIssue) {
    final authProvider = context.read<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final adminName = authProvider.userFullName ?? 'Admin';
    final adminId = authProvider.userId;

    var issue = originalIssue;

    // Auto-mark Seen when an admin first opens an Open issue
    if (isAdmin && issue.status == 'Open' && adminId != null) {
      context.read<ToolIssueProvider>().markSeen(issue.id!, adminName, adminId);
      issue = issue.copyWith(status: 'Seen', seenAt: DateTime.now(), seenBy: adminName);
    }

    final techName = issue.reportedBy.split('(').first.trim();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.info_outline, color: AppTheme.secondaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Issue Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tool', issue.toolName),
              _buildDetailRow('Type', issue.issueType),
              _buildDetailRow('Priority', issue.priority),
              _buildDetailRow('Status', issue.status),
              _buildDetailRow('Reported By', issue.reportedBy),
              _buildDetailRow('Reported At', _formatDateTime(issue.reportedAt)),
              if (issue.seenBy != null)
                _buildDetailRow('Seen By', issue.seenBy!),
              if (issue.seenAt != null)
                _buildDetailRow('Seen At', _formatDateTime(issue.seenAt!)),
              if (issue.resolutionType != null)
                _buildDetailRow('Resolution', issue.resolutionType!),
              if (issue.actionedByName != null)
                _buildDetailRow('Actioned By', issue.actionedByName!),
              if (issue.resolvedAt != null)
                _buildDetailRow('Resolved At', _formatDateTime(issue.resolvedAt!)),
              if (issue.resolution != null)
                _buildDetailRow('Notes', issue.resolution!),
              if (issue.location != null)
                _buildDetailRow('Location', issue.location!),
              if (issue.estimatedCost != null)
                _buildDetailRow('Est. Cost', CurrencyFormatter.formatCurrency(issue.estimatedCost!)),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              // ── Admin action area ──
              if (isAdmin && adminId != null && (issue.status == 'Seen' || issue.status == 'In Review')) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (issue.status == 'Seen')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Start Review'),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showActionDialog(
                          issue: issue,
                          action: 'in_review',
                          adminName: adminName,
                          adminId: adminId,
                          techName: techName,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF722ED1),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (issue.status == 'In Review') ...[
                  Text(
                    'Resolve as:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResolveButton(
                          label: 'Repaired',
                          icon: Icons.build_outlined,
                          color: const Color(0xFF52C41A),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showActionDialog(issue: issue, action: 'repaired', adminName: adminName, adminId: adminId, techName: techName);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildResolveButton(
                          label: 'Replaced',
                          icon: Icons.swap_horiz,
                          color: const Color(0xFF1890FF),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showActionDialog(issue: issue, action: 'replaced', adminName: adminName, adminId: adminId, techName: techName);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildResolveButton(
                          label: 'No Action',
                          icon: Icons.block,
                          color: Colors.grey,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _showActionDialog(issue: issue, action: 'no_action', adminName: adminName, adminId: adminId, techName: techName);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResolveButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showActionDialog({
    required ToolIssue issue,
    required String action,
    required String adminName,
    required String adminId,
    required String techName,
  }) {
    String title;
    String buttonLabel;
    Color buttonColor;
    String defaultMsg;

    switch (action) {
      case 'in_review':
        title = 'Start Review';
        buttonLabel = 'Start Review';
        buttonColor = const Color(0xFF722ED1);
        defaultMsg = "We've started reviewing your issue with the ${issue.toolName}. We'll keep you updated.";
        break;
      case 'repaired':
        title = 'Mark as Repaired';
        buttonLabel = 'Confirm Repaired';
        buttonColor = const Color(0xFF52C41A);
        defaultMsg = "Good news! The ${issue.toolName} has been repaired and is ready to use.";
        break;
      case 'replaced':
        title = 'Mark as Replaced';
        buttonLabel = 'Confirm Replaced';
        buttonColor = const Color(0xFF1890FF);
        defaultMsg = "The ${issue.toolName} has been replaced. Please collect the new one.";
        break;
      case 'no_action':
        title = 'No Action';
        buttonLabel = 'Confirm';
        buttonColor = Colors.grey;
        defaultMsg = "We've reviewed your report for the ${issue.toolName}. No action will be taken at this time.";
        break;
      default:
        return;
    }

    final msgController = TextEditingController(text: defaultMsg);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message to $techName:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: msgController,
              decoration: context.chatGPTInputDecoration.copyWith(
                hintText: 'Message to technician',
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final msg = msgController.text.trim();
              final provider = context.read<ToolIssueProvider>();
              switch (action) {
                case 'in_review':
                  provider.markInReview(issue.id!, adminName, adminId, messageToTech: msg);
                  break;
                case 'repaired':
                  provider.markRepaired(issue.id!, adminName, adminId, messageToTech: msg);
                  break;
                case 'replaced':
                  provider.markReplaced(issue.id!, adminName, adminId, messageToTech: msg);
                  break;
                case 'no_action':
                  provider.markNoAction(issue.id!, adminName, adminId, messageToTech: msg);
                  break;
              }
              Navigator.pop(dialogContext);
              AuthErrorHandler.showSuccessSnackBar(context, '$title successful');
            },
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter options
            Text('Filter by Status:'),
            SizedBox(height: 8),
            ..._filters.map((filter) => RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            )),
            
            Divider(),
            
            // Sort options
            Text('Sort by:'),
            SizedBox(height: 8),
            ..._sortOptions.map((sort) => RadioListTile<String>(
              title: Text(sort),
              value: sort,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  List<ToolIssue> _sortIssues(List<ToolIssue> issues) {
    switch (_selectedSort) {
      case 'Priority':
        return List.from(issues)..sort((a, b) => _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority)));
      case 'Type':
        return List.from(issues)..sort((a, b) => a.issueType.compareTo(b.issueType));
      case 'Age':
        return List.from(issues)..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      case 'Recent':
      default:
        return List.from(issues)..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    }
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'Critical': return 4;
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 0;
    }
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.appBarBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      leading: IconButton(
        icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        context.read<AuthProvider>().isAdmin ? 'Tool Issues' : 'My Reports',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final targetIndex = _filters.indexOf(filter);
                if (targetIndex >= 0 && targetIndex < _tabController.length) {
                  _tabController.animateTo(targetIndex);
                }
                setState(() => _selectedFilter = filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 24 : 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: context.chatGPTInputDecoration.copyWith(
          hintText: 'Search issues, tools, reporters...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildIssueTypePill(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getIssueTypeColor(type),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    final color = _getPriorityAccentColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getPriorityAccentColor(String priority) {
    switch (priority) {
      case 'Critical':
      case 'High':
        return const Color(0xFFFF4D4F);
      case 'Medium':
        return const Color(0xFFFAAD14);
      case 'Low':
        return const Color(0xFF52C41A);
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFFFF4D4F);
      case 'Seen':
        return const Color(0xFF1890FF);
      case 'In Review':
        return const Color(0xFF722ED1);
      case 'In Progress':
        return const Color(0xFFFAAD14);
      case 'Resolved':
        return const Color(0xFF52C41A);
      case 'Closed':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getIssueTypeColor(String type) {
    switch (type) {
      case 'Faulty': return Colors.red;
      case 'Lost': return Colors.orange;
      case 'Damaged': return Colors.purple;
      case 'Missing Parts': return Colors.blue;
      case 'Other': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
