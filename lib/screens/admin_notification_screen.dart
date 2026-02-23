import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import 'admin_approval_screen.dart';
import 'approval_workflows_screen.dart';
import 'tool_issues_screen.dart';
import 'maintenance_screen.dart';
import '../services/firebase_messaging_service.dart';
import '../services/badge_service.dart';
import '../widgets/common/loading_widget.dart';
import '../l10n/app_localizations.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminNotificationProvider>().loadNotifications();
      // Sync badge with database when opening notifications
      await BadgeService.syncBadgeWithDatabase(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 20,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => NavigationHelper.safePop(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Consumer<AdminNotificationProvider>(
                    builder: (context, provider, child) {
                      if (provider.unreadCount > 0) {
                        return TextButton(
                          onPressed: () async {
                            await provider.markAllAsRead();
                            // Sync badge after marking all as read
                            await BadgeService.syncBadgeWithDatabase(context);
                            AuthErrorHandler.showSuccessSnackBar(context, 'All notifications marked as read');
                          },
                          child: Text(
                            'Mark All Read',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            // Filter chips
            Container(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.getResponsiveSpacing(context, 16),
                0,
                ResponsiveHelper.getResponsiveSpacing(context, 16),
                ResponsiveHelper.getResponsiveSpacing(context, 12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    ...NotificationType.values.map((type) => 
                      Padding(
                        padding: EdgeInsets.only(right: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        child: _buildFilterChip(type.displayName, type),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        
            // Notifications list
            Expanded(
              child: Consumer<AdminNotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return _buildNotificationsSkeleton(context);
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading notifications',
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
                              provider.error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => provider.loadNotifications(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.secondaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredNotifications = _selectedFilter == null
                      ? provider.notifications
                      : provider.getNotificationsByType(_selectedFilter!);

                  if (filteredNotifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see technician requests here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadNotifications();
                      await BadgeService.syncBadgeWithDatabase(context);
                    },
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    color: AppTheme.secondaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return _buildNotificationCard(notification, provider);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationType? type) {
    final isSelected = _selectedFilter == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        showCheckmark: false,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? AppTheme.secondaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? type : null;
          });
        },
        backgroundColor: context.cardBackground,
        selectedColor: AppTheme.secondaryColor.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(
          color: isSelected
              ? AppTheme.secondaryColor
              : Colors.black.withOpacity(0.04),
          width: isSelected ? 1.2 : 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildNotificationsSkeleton(BuildContext context) {
    return const ListSkeletonLoader(
      itemCount: 6,
      itemHeight: 110,
    );
  }

  Widget _buildNotificationCard(AdminNotification notification, AdminNotificationProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      decoration: context.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await provider.markAsRead(notification.id);
              // Sync badge after marking as read
              await BadgeService.syncBadgeWithDatabase(context);
            }
            if (!_navigateToScreenForType(notification)) {
              _showNotificationDetails(notification);
            }
          },
          borderRadius: BorderRadius.circular(18), // Match card decoration borderRadius
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            notification.technicianName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu Button
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'mark_read':
                        await provider.markAsRead(notification.id);
                        // Sync badge after marking as read
                        await BadgeService.syncBadgeWithDatabase(context);
                        break;
                      case 'delete':
                        await provider.removeNotification(notification.id);
                        // Sync badge after deleting
                        await BadgeService.syncBadgeWithDatabase(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.accessRequest:
        return Icons.login;
      case NotificationType.toolRequest:
        return Icons.build;
      case NotificationType.toolAssignment:
        return Icons.assignment_ind;
      case NotificationType.maintenanceRequest:
        return Icons.build_circle;
      case NotificationType.issueReport:
        return Icons.report_problem;
      case NotificationType.userApproved:
        return Icons.check_circle;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.accessRequest:
        return Colors.blue;
      case NotificationType.toolRequest:
        return Colors.green;
      case NotificationType.toolAssignment:
        return Colors.orange;
      case NotificationType.maintenanceRequest:
        return Colors.orange;
      case NotificationType.issueReport:
        return Colors.red;
      case NotificationType.userApproved:
        return Colors.green;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showNotificationDetails(AdminNotification notification) {
    final theme = Theme.of(context);
    final notificationColor = _getNotificationColor(notification.type);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notificationColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: notificationColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(
              'Technician Details:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Name: ${notification.technicianName}',
              style: TextStyle(
                fontSize: 13,
                color: context.secondaryTextColor,
              ),
            ),
            Text(
              'Email: ${notification.technicianEmail}',
              style: TextStyle(
                fontSize: 13,
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: context.hintTextColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToScreenForType(notification);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  /// Returns true if navigated to a screen, false if no screen (show dialog instead)
  bool _navigateToScreenForType(AdminNotification notification) {
    final navigator = Navigator.of(context);
    Widget? targetScreen;
    switch (notification.type) {
      case NotificationType.accessRequest:
        targetScreen = const AdminApprovalScreen();
        break;
      case NotificationType.toolRequest:
        targetScreen = const ApprovalWorkflowsScreen();
        break;
      case NotificationType.maintenanceRequest:
        targetScreen = const MaintenanceScreen();
        break;
      case NotificationType.issueReport:
        targetScreen = const ToolIssuesScreen();
        break;
      case NotificationType.toolAssignment:
      case NotificationType.userApproved:
      case NotificationType.general:
        return false;
    }
    if (targetScreen != null) {
      navigator.push(CupertinoPageRoute(builder: (_) => targetScreen!));
      return true;
    }
    return false;
  }

}
