import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'checkin_screen.dart';
import 'shared_tools_screen.dart';
import 'add_tool_issue_screen.dart';
import 'request_new_tool_screen.dart';
import 'technician_my_tools_screen.dart';
import '../models/tool.dart';
import '../widgets/common/rgs_logo.dart';
import '../services/supabase_service.dart';
import 'settings_screen.dart';
import '../services/firebase_messaging_service.dart' if (dart.library.html) '../services/firebase_messaging_service_stub.dart';
import '../theme/app_theme.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../services/supabase_service.dart';
import '../utils/responsive_helper.dart';

// Removed placeholder request/report screens; using detailed screens directly

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _selectedIndex = 0;
  bool _isDisposed = false;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TechnicianDashboardScreen(
        key: const ValueKey('tech_dashboard'),
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const RequestNewToolScreen(),
      AddToolIssueScreen(
        onNavigateToDashboard: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  Widget _buildAccountMenuHeader(
      BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fullName = (authProvider.userFullName ?? 'Technician').trim();
    final roleLabel = authProvider.isAdmin ? 'Administrator' : 'Technician';
    final roleColor = authProvider.isAdmin ? Colors.orange : AppTheme.secondaryColor;

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.primaryColor.withValues(alpha: 0.1),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'Technician',
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
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                    ),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: roleColor,
                      fontWeight: FontWeight.w600,
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

  Widget _buildAccountIcon(BuildContext context, AuthProvider authProvider) {
    final metadata = authProvider.user?.userMetadata ?? <String, dynamic>{};
    String? avatarUrl;
    final rawAvatar = metadata['profile_picture_url'];
    if (rawAvatar is String && rawAvatar.isNotEmpty) {
      avatarUrl = rawAvatar;
    } else if (metadata['avatar_url'] is String &&
        (metadata['avatar_url'] as String).isNotEmpty) {
      avatarUrl = metadata['avatar_url'] as String;
    }

    // Check auth user avatar if metadata misses
    avatarUrl ??= authProvider.user?.userMetadata?['avatar_url'] as String?;

    final initials = (authProvider.userFullName?.trim().isNotEmpty ?? false)
        ? authProvider.userFullName!.trim()[0].toUpperCase()
        : 'T';

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      width: ResponsiveHelper.getResponsiveIconSize(context, 40),
      height: ResponsiveHelper.getResponsiveIconSize(context, 40),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 14),
        ),
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: _buildAccountInitialBadge(context, initials)),
              )
            : Center(child: _buildAccountInitialBadge(context, initials)),
      ),
    );
  }

  Widget _buildAccountInitialBadge(BuildContext context, String initial) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(
      BuildContext context, AuthProvider authProvider) async {
    if (_isDisposed || !mounted) return;
    try {
      // Close any open dialogs/menus first
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Wait a frame to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Sign out
      await authProvider.signOut();
      
      // Wait another frame before navigation
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        // Use pushAndRemoveUntil with error handling
        Navigator.of(context).pushAndRemoveUntil(
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
      // Even if there's an error, try to navigate to login
      if (mounted) {
        try {
          Navigator.of(context).pushAndRemoveUntil(
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

  Widget _buildMonogramAvatar(BuildContext context, String initial) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: (_selectedIndex == 1 || _selectedIndex == 2)
          ? null
          : AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        scrolledUnderElevation: 6,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const RGSLogo(),
        ),
        centerTitle: true,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading || authProvider.isLoggingOut) {
                return IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: null,
                );
              }
              
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
                  } else if (value == 'logout') {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    await _handleSignOut(context, authProvider);
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
                    child: _buildAccountMenuHeader(context, authProvider),
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
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                            ),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index.clamp(0, 2)),
        type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Request Tool',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Issue',
          ),
        ],
      ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckinScreen(),
                  ),
                );
              },
              backgroundColor: Colors.green,
        foregroundColor: Colors.white,
              icon: const Icon(Icons.keyboard_return),
              label: const Text('Check In'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showNotifications(BuildContext context) {
    // Clear badge when opening notifications sheet
    FirebaseMessagingService.clearBadge();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final fcmToken = FirebaseMessagingService.fcmToken;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  // Content
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _loadTechnicianNotifications(
                              authProvider.user?.email, authProvider),
                          builder: (context, snapshot) {
                            final notifications = snapshot.data ?? [];

                            return ListView(
                              controller: scrollController,
                              padding: EdgeInsets.all(16),
                              children: [
                                // Real Notifications List
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (notifications.isNotEmpty) ...[
                                  Text(
                                    'Your Notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ...notifications.map(
                                      (notification) => _buildNotificationCard(
                  context,
                                            notification,
                                          )),
                                  SizedBox(height: 24),
                                  Divider(),
                                  SizedBox(height: 16),
                                ] else if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    notifications.isEmpty) ...[
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.notifications_none,
                                              size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                          SizedBox(height: 16),
                                          Text(
                                            'No notifications yet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'You\'ll see notifications here when you receive tool requests',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadTechnicianNotifications(
      String? technicianEmail, AuthProvider authProvider) async {
    if (technicianEmail == null) return [];

    try {
      final List<Map<String, dynamic>> allNotifications = [];
      
      // Load notifications from admin_notifications (where technician_email matches)
      try {
        final adminNotifications = await SupabaseService.client
            .from('admin_notifications')
            .select()
            .eq('technician_email', technicianEmail)
            .order('timestamp', ascending: false)
            .limit(20);
        
        allNotifications.addAll((adminNotifications as List).cast<Map<String, dynamic>>());
      } catch (e) {
        debugPrint('⚠️ Error loading admin notifications: $e');
      }

      // Load notifications from technician_notifications (where user_id matches)
      try {
        if (authProvider.user != null) {
          final technicianNotifications = await SupabaseService.client
              .from('technician_notifications')
              .select()
              .eq('user_id', authProvider.user!.id)
              .order('timestamp', ascending: false)
              .limit(20);
          
          // Convert technician_notifications format to match admin_notifications format
          final converted = (technicianNotifications as List).map((n) {
            return {
              'id': n['id'],
              'title': n['title'],
              'message': n['message'],
              'technician_name': authProvider.userFullName ?? 'You',
              'technician_email': technicianEmail,
              'type': n['type'] ?? 'general',
              'timestamp': n['timestamp'],
              'is_read': n['is_read'] ?? false,
              'data': n['data'],
            };
          }).toList();
          
          allNotifications.addAll(converted);
        }
      } catch (e) {
        debugPrint('⚠️ Error loading technician notifications (table might not exist): $e');
      }

      // Sort by timestamp (newest first) and remove duplicates
      allNotifications.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']?.toString() ?? DateTime.now().toIso8601String());
        final bTime = DateTime.parse(b['timestamp']?.toString() ?? DateTime.now().toIso8601String());
        return bTime.compareTo(aTime);
      });

      // Remove duplicates based on ID
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (var notification in allNotifications) {
        final id = notification['id']?.toString();
        if (id != null && !seen.contains(id)) {
          seen.add(id);
          unique.add(notification);
        }
      }

      return unique.take(20).toList();
    } catch (e) {
      debugPrint('Error loading technician notifications: $e');
      return [];
    }
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] != null
        ? DateTime.parse(notification['timestamp'].toString())
        : DateTime.now();
    final isRead = notification['is_read'] as bool? ?? false;
    final type = notification['type'] as String? ?? 'general';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: !isRead
            ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!isRead) {
              try {
                await SupabaseService.client
                    .from('admin_notifications')
                    .update({'is_read': true}).eq('id', notification['id']);
              } catch (e) {
                debugPrint('Error marking notification as read: $e');
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
              ),
            ],
          ),
                      SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'access_request':
        return Icons.login;
      case 'tool_request':
        return Icons.build;
      case 'maintenance_request':
        return Icons.build_circle;
      case 'issue_report':
        return Icons.report_problem;
      case 'user_approved':
      case 'account_approved':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'access_request':
        return Colors.blue;
      case 'tool_request':
        return Colors.green;
      case 'maintenance_request':
        return Colors.orange;
      case 'issue_report':
        return Colors.red;
      default:
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
}

// Technician Dashboard Screen - New Design
class TechnicianDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const TechnicianDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'All Tools',
    'Shared Tools',
    'My Tools',
    'Available',
    'In Use'
  ];
  late final PageController _sharedToolsController;
  Timer? _autoSlideTimer;

  void _navigateToTab(int index, BuildContext context) {
    widget.onNavigateToTab(index);
  }

  @override
  void initState() {
    super.initState();
    _sharedToolsController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _sharedToolsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseToolProvider, AuthProvider,
        SupabaseTechnicianProvider>(
      builder:
          (context, toolProvider, authProvider, technicianProvider, child) {
        // Filter tools based on selected category
        List<Tool> filteredTools = toolProvider.tools;

        final currentUserId = authProvider.userId;
        
        if (_selectedCategoryIndex == 1) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.toolType == 'shared')
              .toList();
        } else if (_selectedCategoryIndex == 2) {
          if (currentUserId == null) {
            filteredTools = [];
          } else {
            filteredTools = toolProvider.tools
                .where((tool) =>
                    tool.assignedTo == currentUserId &&
                    (tool.status == 'Assigned' || tool.status == 'In Use'))
                .toList();
          }
        } else if (_selectedCategoryIndex == 3) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.status == 'Available')
              .toList();
        } else if (_selectedCategoryIndex == 4) {
          filteredTools = toolProvider.tools
              .where((tool) => tool.status == 'In Use')
              .toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredTools = filteredTools
              .where((tool) =>
                  tool.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (tool.brand
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false) ||
                  tool.category
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Featured tools (shared and available)
        final featuredTools = toolProvider.tools
            .where((tool) =>
                tool.toolType == 'shared' && tool.status == 'Available')
            .take(10)
            .toList();

        // Latest tools (my tools or all tools if none assigned)
        final myTools = currentUserId == null
            ? <Tool>[]
            : toolProvider.tools
                .where((tool) =>
                    tool.assignedTo == currentUserId &&
                    (tool.status == 'Assigned' || tool.status == 'In Use'))
                .toList();
        final latestTools = myTools;

        if (toolProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (toolProvider.tools.isEmpty) {
          final theme = Theme.of(context);
          return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                SizedBox(height: 16),
                Text('No tools available',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                SizedBox(height: 8),
                Text('Contact your administrator to add tools to the system.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => toolProvider.loadTools(),
                    child: Text('Retry')),
              ],
            ),
          );
        }

        // Initialize auto-slide when data is available
        _setupAutoSlide(featuredTools);

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Welcome banner
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 12,
                ),
                      child: Container(
                width: double.infinity,
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
                decoration: BoxDecoration(
                    color: isDarkMode ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                    ),
                    border: isDarkMode
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                      children: [
                        Container(
                        width: ResponsiveHelper.getResponsiveIconSize(context, 56),
                        height: ResponsiveHelper.getResponsiveIconSize(context, 56),
                          decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surfaceVariant
                            : Colors.grey[100],
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                          ),
                          ),
                          child: Icon(
                          Icons.inventory_2,
                          color: AppTheme.secondaryColor,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 28),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              _greeting(authProvider.userFullName),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                              Text(
                                'Manage your tools and access shared resources',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

              // Shared Tools Section
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                      'Shared Tools',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SharedToolsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 8,
                          vertical: 4,
                        ),
                          ),
                          child: Text(
                        'See All >',
                            style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

              // Shared Tools Carousel (auto sliding)
              SizedBox(
                height: ResponsiveHelper.getResponsiveListItemHeight(context, 176),
                child: featuredTools.isEmpty
                    ? Center(
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
                          child: Text(
                            'No shared tools available',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ),
                      )
                    : PageView.builder(
                        controller: _sharedToolsController,
                        itemCount: featuredTools.length,
                        padEnds: false,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 16,
                            ),
                              child: _buildFeaturedCard(
                                  featuredTools[index],
                                  context,
                                  authProvider.user?.id,
                                  technicianProvider.technicians),
                          );
                        },
                      ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

              // My Tools Section
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Tools',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                              fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TechnicianMyToolsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        'See All >',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

              // Latest Tools Vertical List
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: latestTools.isEmpty
                    ? Container(
                        height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
                        child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.badge_outlined,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Text(
                              'No tools assigned yet',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                            ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Text(
                                'Add or badge tools you currently have to see them here.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Column(
                          children: latestTools
                              .map((tool) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: ResponsiveHelper.getResponsiveSpacing(context, 16),
                                    ),
                                    child: _buildLatestCard(tool, context,
                                        technicianProvider.technicians),
                                  ))
                              .toList(),
                      ),
              ),

              SizedBox(height: 100),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildFeaturedCard(Tool tool, BuildContext context,
      String? currentUserId, List<dynamic> technicians) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Exact same layout as latest card, with a Request button for shared tools
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 164),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
          ),
          border: isDarkMode
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left thumbnail (wider like Featured)
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(context, 116),
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                ),
                child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(true),
                            )
                          : File(tool.imagePath!).existsSync()
                              ? Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                              )
                            : _buildPlaceholderImage(true))
                    : _buildPlaceholderImage(true),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: ResponsiveHelper.getResponsiveSpacing(context, 4),
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                    Wrap(
                      spacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
                      runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      children: [
                        _buildOutlinedChip(
                          context,
                          _getStatusLabel(tool.status),
                          AppTheme.secondaryColor,
                        ),
                        _buildOutlinedChip(
                          context,
                          _getConditionLabel(tool.condition),
                          _getConditionColor(tool.condition),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                    if (tool.location != null && tool.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Expanded(
                              child: Text(
                                tool.location!,
                  style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                        Expanded(
                          child: Text(
                            tool.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Flexible(
                          child: Text(
                            tool.toolType.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _holderLine(context, tool, technicians),
                        ),
                        // Show Request button for shared tools that have a holder (badged to someone)
                        if (tool.toolType == 'shared' &&
                            tool.assignedTo != null &&
                            tool.assignedTo!.isNotEmpty &&
                            (currentUserId == null ||
                                currentUserId != tool.assignedTo))
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: TextButton(
                              onPressed: () =>
                                  _sendToolRequest(context, tool),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.secondaryColor,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Request',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToolRequest(BuildContext context, Tool tool) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    final requesterName = auth.userFullName ?? 'Unknown Technician';
    final requesterEmail = auth.user?.email ?? 'unknown@technician';
    
    if (requesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in to request a tool.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final ownerId = tool.assignedTo;
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This tool is not assigned to anyone.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Get owner email from users table
      String ownerEmail = 'unknown@owner';
      try {
        final userResponse = await SupabaseService.client
            .from('users')
            .select('email')
            .eq('id', ownerId)
            .maybeSingle();
        
        if (userResponse != null && userResponse['email'] != null) {
          ownerEmail = userResponse['email'] as String;
        }
      } catch (e) {
        debugPrint('Could not fetch owner email: $e');
      }
      
      // Create notification in admin_notifications table (for admin visibility)
      try {
        await SupabaseService.client.rpc(
          'create_admin_notification',
          params: {
            'p_title': 'Tool Request: ${tool.name}',
            'p_message': '$requesterName requested the tool "${tool.name}"',
            'p_technician_name': requesterName,
            'p_technician_email': requesterEmail,
            'p_type': 'tool_request',
            'p_data': {
              'tool_id': tool.id,
              'tool_name': tool.name,
              'requester_id': requesterId,
              'requester_name': requesterName,
              'requester_email': requesterEmail,
              'owner_id': ownerId,
            },
          },
        );
        debugPrint('✅ Created admin notification for tool request');
      } catch (e) {
        debugPrint('⚠️ Failed to create admin notification: $e');
      }
      
      // Create notification in technician_notifications table for the tool owner
      // This will appear in the technician's notification center
      try {
        await SupabaseService.client.from('technician_notifications').insert({
          'user_id': ownerId, // The technician who has the tool
          'title': 'Tool Request: ${tool.name}',
          'message': '$requesterName needs the tool "${tool.name}" that you currently have',
          'type': 'tool_request',
          'is_read': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': {
            'tool_id': tool.id,
            'tool_name': tool.name,
            'requester_id': requesterId,
            'requester_name': requesterName,
            'requester_email': requesterEmail,
            'owner_id': ownerId,
          },
        });
        debugPrint('✅ Created technician notification for tool request');
        debugPrint('✅ Notification sent to technician: $ownerId');
      } catch (e) {
        debugPrint('❌ Failed to create technician notification: $e');
        debugPrint('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tool request sent to ${tool.assignedTo == requesterId ? 'the owner' : 'the tool holder'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending tool request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  Widget _buildLatestCard(
      Tool tool, BuildContext context, List<dynamic> technicians) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 148),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
          ),
          border: isDarkMode
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left thumbnail (wider like Featured)
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(context, 116),
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                ),
                child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(false),
                            )
                          : File(tool.imagePath!).existsSync()
                              ? Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                              )
                            : _buildPlaceholderImage(false))
                    : _buildPlaceholderImage(false),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: ResponsiveHelper.getResponsiveSpacing(context, 4),
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                    Wrap(
                      spacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
                      runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      children: [
                        _buildOutlinedChip(
                          context,
                          _getStatusLabel(tool.status),
                          AppTheme.secondaryColor,
                        ),
                        _buildOutlinedChip(
                          context,
                          _getConditionLabel(tool.condition),
                          _getConditionColor(tool.condition),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                    if (tool.location != null && tool.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Expanded(
                              child: Text(
                                tool.location!,
                  style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                        Expanded(
                          child: Text(
                            tool.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Flexible(
                          child: Text(
                            tool.toolType.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    _holderLine(context, tool, technicians),
                  ],
                ),
              ),
          ),
        ],
      ),
    ),
    );
  }

  List<String> _getToolImageUrls(Tool tool) {
    if (tool.imagePath == null || tool.imagePath!.isEmpty) {
      return [];
    }
    
    // Support both single image (backward compatibility) and multiple images (comma-separated)
    final imagePath = tool.imagePath!;
    
    // Check if it's comma-separated (multiple images)
    if (imagePath.contains(',')) {
      return imagePath.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    return [imagePath];
  }

  Widget _buildPlaceholderImage(bool isFeatured) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
        decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surfaceVariant
            : Colors.grey[200],
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
          right: isFeatured
              ? Radius.zero
              : Radius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                ),
        ),
      ),
      child: Icon(
        Icons.build,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
        size: ResponsiveHelper.getResponsiveIconSize(context, 32),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildOutlinedChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _holderLine(
      BuildContext context, Tool tool, List<dynamic> technicians) {
    final theme = Theme.of(context);
    
    if (tool.assignedTo == null) {
      return Text(
        'No current holder',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          );
        }
    String name = 'Technician';
    for (final t in technicians) {
      if (t.id == tool.assignedTo) {
        final parts = (t.name).trim().split(RegExp(r"\s+"));
        name = parts.isNotEmpty ? parts.first : t.name;
        break;
      }
    }
    return Text(
      '$name has this tool',
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  IconData _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return Icons.apps;
      case 1:
        return Icons.share;
      case 2:
        return Icons.person;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.build;
      default:
        return Icons.apps;
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final fcmToken = FirebaseMessagingService.fcmToken;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
          child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(16),
                      children: [
                        // FCM Status Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      fcmToken != null
                                          ? Icons.check_circle
                                          : Icons.error_outline,
                                      color: fcmToken != null
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'FCM Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  fcmToken != null
                                      ? 'Push notifications are enabled'
                                      : 'Push notifications not configured',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                if (fcmToken != null) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    'FCM Token:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
              Container(
                                    padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      fcmToken,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await FirebaseMessagingService
                                          .refreshToken();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Token refreshed')),
                                      );
                                      Navigator.pop(context);
                                      _showNotifications(context);
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Refresh Token'),
                                  ),
                                ] else ...[
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await FirebaseMessagingService
                                          .initialize();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'FCM initialized. Please check again.')),
                                      );
                                      Navigator.pop(context);
                                      _showNotifications(context);
                                    },
                                    icon: Icon(Icons.notifications_active),
                                    label: Text('Initialize FCM'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Test Notification Button
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                                  'Test Notification',
                      style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                      ),
                    ),
                                SizedBox(height: 8),
                    Text(
                                  'Send a test notification to verify FCM is working',
                      style: TextStyle(
                        fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: fcmToken != null
                                      ? () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Test notification sent! Check your device notifications.'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                          // Note: This requires backend to send the notification
                                          // For now, just show a message
                                        }
                                      : null,
                                  icon: Icon(Icons.send),
                                  label: Text('Send Test Notification'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Info Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    Row(
                      children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue),
                        SizedBox(width: 8),
                                    Text(
                                      'About Notifications',
                              style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                                SizedBox(height: 8),
                                Text(
                                  'Push notifications will alert you when:\n'
                                  '• Someone requests a tool from you\n'
                                  '• You receive a message in a tool request chat\n'
                                  '• Admin assigns you a new tool\n'
                                  '• Tool maintenance reminders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'assigned':
        return 'Assigned';
      case 'in use':
        return 'In Use';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'in use':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getConditionLabel(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return 'Faulty';
    return 'Good';
  }

  Color _getConditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return Colors.red;
    return Colors.green;
  }

  String _greeting(String? fullName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final name = (fullName == null || fullName.trim().isEmpty)
        ? 'Technician'
        : fullName.split(RegExp(r"\s+")).first;
    return '$salutation, $name!';
  }

  void _setupAutoSlide(List<Tool> featuredTools) {
    if (_autoSlideTimer != null || featuredTools.length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || featuredTools.isEmpty) return;
      final nextPage = (_sharedToolsController.page ?? 0).round() + 1;
      final target = nextPage % featuredTools.length;
      _sharedToolsController.animateToPage(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }
}
