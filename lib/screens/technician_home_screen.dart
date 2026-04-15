import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'checkin_screen.dart';
import 'shared_tools_screen.dart';
import 'add_tool_issue_screen.dart';
import 'tool_issues_screen.dart';
import 'calibration_screen.dart';
import 'compliance_screen.dart';
import 'maintenance_screen.dart';
import 'add_tool_screen.dart';
import 'request_new_tool_screen.dart';
import 'technician_add_tool_screen.dart';
import 'technician_my_tools_screen.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_name_service.dart';
import 'settings_screen.dart';
import '../services/firebase_messaging_service.dart' if (dart.library.html) '../services/firebase_messaging_service_stub.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_card.dart';
import '../services/badge_service.dart';
import '../services/last_route_service.dart';
import '../providers/admin_notification_provider.dart';
import '../providers/technician_notification_provider.dart';
import '../models/admin_notification.dart';
import '../models/technician_notification.dart';
import '../utils/responsive_helper.dart';
import '../utils/auth_error_handler.dart';
import '../services/tool_history_service.dart';
import '../models/tool_history.dart';
import 'all_tool_history_screen.dart';
import '../utils/account_deletion_helper.dart';
import '../models/user_role.dart';
import '../providers/supabase_certification_provider.dart';
import '../providers/tool_issue_provider.dart';
import '../widgets/common/loading_widget.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';

// Removed placeholder request/report screens; using detailed screens directly

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  /// Set to true before navigating here from a push notification tap so the
  /// notification center (bottom sheet) auto-opens once the screen is ready.
  static bool openNotificationsOnLoad = false;

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> with WidgetsBindingObserver {
  int _unreadNotificationCount = 0;
  Timer? _notificationRefreshTimer;
  int _selectedIndex = 0;
  bool _isDisposed = false;
  int _notificationRefreshKey = 0;
  late final List<Widget> _screens;
  TechnicianNotificationProvider? _notificationProviderRef;
  final LocalCacheService _cache = LocalCacheService();
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      TechnicianDashboardScreen(
        key: const ValueKey('tech_dashboard'),
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const TechnicianMyToolsScreen(),
      const SharedToolsScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LastRouteService.saveLastRoute('/technician');

      // Refresh badge count immediately — don't wait for provider to finish loading
      _refreshUnreadCount();

      // Listen to notification provider for real-time badge updates
      _notificationProviderRef = context.read<TechnicianNotificationProvider>();
      _notificationProviderRef!.addListener(_onNotificationProviderChanged);

      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
      context.read<SupabaseCertificationProvider>().loadAll();
      // Load notifications from provider (will set up realtime subscription)
      await context.read<TechnicianNotificationProvider>().loadNotifications();
      // Sync badge with database when screen initializes (like admin section)
      await BadgeService.syncBadgeWithDatabase(context);
      // Refresh again after provider finishes for accuracy
      _refreshUnreadCount();

      // Auto-open notification center if launched from a push notification tap
      if (TechnicianHomeScreen.openNotificationsOnLoad) {
        TechnicianHomeScreen.openNotificationsOnLoad = false;
        // Small delay to let the screen settle before presenting the sheet
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted && !_isDisposed) {
          _showNotifications(context);
        }
      }

      // Refresh unread count and sync badge every 30 seconds (like admin section)
      _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) {
          _refreshUnreadCount();
          BadgeService.syncBadgeWithDatabase(context).catchError((e) {
            debugPrint('⚠️ Error syncing badge: $e');
          });
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed && mounted) {
      // Auto-open notification center if triggered from a background notification tap
      if (TechnicianHomeScreen.openNotificationsOnLoad) {
        TechnicianHomeScreen.openNotificationsOnLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) _showNotifications(context);
        });
      }
      // Sync badge when app comes back to foreground (like admin section)
      BadgeService.syncBadgeWithDatabase(context).catchError((e) {
        debugPrint('⚠️ Error syncing badge on resume: $e');
      });
      _refreshUnreadCount();
      // Refresh tools only when app resumes (user returns to app)
      context.read<SupabaseToolProvider>().loadTools().catchError((e) {
        debugPrint('⚠️ Error refreshing tools on resume: $e');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationProviderRef?.removeListener(_onNotificationProviderChanged);
    _isDisposed = true;
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  /// Called when the TechnicianNotificationProvider changes (new notification, mark read, etc.)
  void _onNotificationProviderChanged() {
    if (mounted && !_isDisposed) {
      // Use the provider's count for the technician_notifications portion,
      // then refresh the full count (which includes admin_notifications too)
      _refreshUnreadCount();
    }
  }

  Future<void> _refreshUnreadCount() async {
    if (_isDisposed || !mounted) return;
    final count = await _getUnreadNotificationCount(context);
    if (mounted && !_isDisposed) {
      setState(() {
        _unreadNotificationCount = count;
      });
      // Sync OS badge with database count
      BadgeService.updateBadge(count).catchError((e) {
        debugPrint('⚠️ Error updating badge: $e');
      });
    }
  }

  Widget _buildAccountMenuHeader(
      BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final displayName = _resolveDisplayName(authProvider);
    final fullName = (displayName ?? 'Account').trim();
    final roleLabel = authProvider.isAdmin ? 'Administrator' : 'Technician';
    final roleColor = authProvider.isAdmin ? AppTheme.warningColor : AppTheme.secondaryColor;

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 12,
      ),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
        border: Border.all(
          color: context.cardBorder, // ChatGPT-style: #E5E5E5
          width: 1,
        ),
        boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveSpacing(context, 8),
            ),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 12),
              ),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.secondaryColor,
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
                  fullName,
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
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 14),
        ),
        boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
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

  void _showProfileBottomSheet(
      BuildContext parentContext, AuthProvider authProvider) {
    final theme = Theme.of(parentContext);
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        final surfaceColor = theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              backgroundColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.12),
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
                              label: 'Request Account Deletion',
                              iconColor: Colors.red,
                              iconPadding: 8,
                              backgroundColor: Colors.red.withValues(alpha: 0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                AccountDeletionHelper.showDeletionRequestDialog(
                                  parentContext,
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
                              backgroundColor: Colors.red.withValues(alpha: 0.12),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _handleSignOut(parentContext, authProvider);
                              },
                              showTrailingChevron: false,
                            ),
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
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
      decoration: AppTheme.groupedCardDecoration(parentContext, radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 48 : 56,
            height: isDesktop ? 48 : 56,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.08),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != authProvider.userFullName) {
                try {
                  await authProvider.updateUserName(newName);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    AuthErrorHandler.showSuccessSnackBar(parentContext, 'Name updated successfully');
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    AuthErrorHandler.showErrorSnackBar(parentContext, 'Failed to update name: ${e.toString()}');
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
            child: const Text('Save'),
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
        decoration: AppTheme.groupedCardDecoration(context, radius: isDesktop ? 10 : 12),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
      decoration: AppTheme.groupedCardDecoration(context, radius: 16),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? fullName) {
    final cleaned = fullName?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return '?';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
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
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.scaffoldBackground,
        appBar: (_selectedIndex == 1 || _selectedIndex == 2)
          ? null
          : AppBar(
        backgroundColor: context.appBarBackground,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotificationCount > 0,
              label: Text(
                _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              backgroundColor: AppTheme.badgeColor,
              textColor: Colors.white,
              child: const Icon(Icons.notifications_outlined, size: 24),
            ),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),
        ),
        title: _selectedIndex == 0
            ? null
            : Text(
                [
                  '',
                  'My tools',
                  'Shared tools',
                ][_selectedIndex.clamp(0, 2)],
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isDisabled = authProvider.isLoggingOut;
              return IconButton(
                icon: const Icon(Icons.account_circle, size: 24),
                onPressed: isDisabled
                    ? null
                    : () => _showProfileBottomSheet(context, authProvider),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: context.scaffoldBackground,
        child: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      ),
      bottomNavigationBar: _buildTechBottomNav(context),
    );
  }

  Widget _buildTechBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final onSurface = theme.colorScheme.onSurface;
    final green = AppTheme.secondaryColor;

    final items = [
      (0, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Dashboard'),
      (1, Icons.handyman_rounded, Icons.handyman_outlined, 'My Tools'),
      (2, Icons.groups_2_rounded, Icons.groups_2_outlined, 'Shared'),
      (3, Icons.keyboard_return_rounded, Icons.keyboard_return_outlined, 'Return'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
        child: Row(
          children: items.map((item) {
            final (idx, activeIcon, inactiveIcon, label) = item;
            final isSelected = _selectedIndex == idx;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (idx == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinScreen()),
                    );
                  } else {
                    setState(() => _selectedIndex = idx.clamp(0, 2));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          size: 20,
                          color: isSelected ? green : onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? green : onSurface.withValues(alpha: 0.38),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 16 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) async {
    // Sync badge with database when opening notifications (like admin section)
    await BadgeService.syncBadgeWithDatabase(context);
    // Clear badge when opening notifications sheet
    FirebaseMessagingService.clearBadge();
    // Refresh unread count
    _refreshUnreadCount();
    // Explicitly reload notifications to ensure they're up to date
    try {
      final notificationProvider = context.read<TechnicianNotificationProvider>();
      await notificationProvider.loadNotifications(skipIfLoading: false);
      debugPrint('✅ Reloaded notifications when opening notification center');
    } catch (e) {
      debugPrint('⚠️ Could not reload notifications: $e');
    }
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Container(
                          decoration: context.cardDecoration,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  // Content
                  Expanded(
                    child: Consumer2<AuthProvider, TechnicianNotificationProvider>(
                      builder: (context, authProvider, notificationProvider, child) {
                        // Combine technician notifications from provider with admin notifications
                        final technicianNotifications = notificationProvider.notifications;
                        final technicianEmail = authProvider.user?.email;
                        
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              key: ValueKey(_notificationRefreshKey),
                              future: _loadAdminNotificationsForTechnician(technicianEmail),
                              builder: (context, adminSnapshot) {
                                // Convert technician notifications to map format
                                final techNotifications = technicianNotifications.map((n) {
                                  return {
                                    'id': n.id,
                                    'title': n.title,
                                    'message': n.message,
                                    'technician_name': authProvider.userFullName ?? 'You',
                                    'technician_email': technicianEmail ?? '',
                                    'type': n.type.value,
                                    'timestamp': n.timestamp.toIso8601String(),
                                    'is_read': n.isRead,
                                    'data': n.data,
                                  };
                                }).toList();
                                
                                // Combine with admin notifications
                                final adminNotifications = adminSnapshot.data ?? [];
                                final allNotifications = [...techNotifications, ...adminNotifications];
                                
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
                                
                                final notifications = unique.take(20).toList();

                                return RefreshIndicator(
                              onRefresh: () async {
                                // Reload notifications from provider
                                await notificationProvider.loadNotifications();
                                // Reload tools to catch updates from other users (e.g., badging)
                                await context.read<SupabaseToolProvider>().loadTools();
                                // Clear name cache to ensure fresh data
                                UserNameService.clearCache();
                                await BadgeService.syncBadgeWithDatabase(context);
                                _refreshUnreadCount();
                                // Trigger rebuild by incrementing key and calling setState
                                _notificationRefreshKey++;
                                setState(() {});
                              },
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white,
                              color: AppTheme.secondaryColor,
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                children: [
                                  // Real Notifications List
                                  if (adminSnapshot.connectionState ==
                                      ConnectionState.waiting || notificationProvider.isLoading)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                                        ),
                                      ),
                                    )
                                  else if (notifications.isNotEmpty) ...[
                                    ...notifications.map(
                                        (notification) => _buildNotificationCard(
                                          context,
                                          notification,
                                          () {
                                            // Update notification and trigger rebuild
                                            _notificationRefreshKey++;
                                            // Also refresh unread count
                                            _refreshUnreadCount();
                                          },
                                        )),
                                    const SizedBox(height: 16),
                                  ] else if (adminSnapshot.connectionState ==
                                          ConnectionState.done &&
                                      !notificationProvider.isLoading &&
                                      notifications.isEmpty) ...[
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.notifications_none_outlined,
                                              size: 64,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No notifications',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'You\'ll see notifications here when you receive tool requests',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ],
                              ),
                                );
                              },
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

  /// Get unread notification count for technician
  Future<int> _getUnreadNotificationCount(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final technicianEmail = authProvider.user?.email;
      if (technicianEmail == null) return 0;

      int unreadCount = 0;

      // Count unread from admin_notifications
      try {
        final adminNotifications = await SupabaseService.client
            .from('admin_notifications')
            .select('is_read')
            .eq('technician_email', technicianEmail);
        
        unreadCount += (adminNotifications as List)
            .where((n) => (n['is_read'] as bool?) != true)
            .length;
      } catch (e) {
        debugPrint('⚠️ Error counting admin notifications: $e');
      }

      // Count unread from technician_notifications
      try {
        if (authProvider.user != null) {
          final technicianNotifications = await SupabaseService.client
              .from('technician_notifications')
              .select('is_read')
              .eq('user_id', authProvider.user!.id);
          
          unreadCount += (technicianNotifications as List)
              .where((n) => (n['is_read'] as bool?) != true)
              .length;
        }
      } catch (e) {
        debugPrint('⚠️ Error counting technician notifications: $e');
      }

      return unreadCount;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Load admin notifications for technician (where technician_email matches)
  Future<List<Map<String, dynamic>>> _loadAdminNotificationsForTechnician(
      String? technicianEmail) async {
    if (technicianEmail == null) return [];

    final isOnline = _connectivity.isOnline;

    if (!isOnline) {
      // Offline – use cached admin notifications and filter by technician_email
      final cached = await _cache.getCachedAdminNotifications();
      return cached
          .where((n) =>
              n.technicianEmail.toLowerCase() ==
              technicianEmail.toLowerCase())
          .map((n) => n.toJson())
          .toList();
    }

    try {
      final adminNotifications = await SupabaseService.client
          .from('admin_notifications')
          .select()
          .eq('technician_email', technicianEmail)
          .order('timestamp', ascending: false)
          .limit(20);
      
      return (adminNotifications as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('⚠️ Error loading admin notifications for technician: $e');
      // Fallback to cache on error
      final cached = await _cache.getCachedAdminNotifications();
      return cached
          .where((n) =>
              n.technicianEmail.toLowerCase() ==
              technicianEmail.toLowerCase())
          .map((n) => n.toJson())
          .toList();
    }
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification, VoidCallback? onNotificationUpdated) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] != null
        ? _parseTimestampValue(notification['timestamp'])
        : DateTime.now();
    final isRead = notification['is_read'] as bool? ?? false;
    final type = notification['type'] as String? ?? 'general';

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      decoration: context.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Mark as read first
            if (!isRead) {
              try {
                final notificationId = notification['id']?.toString();
                if (notificationId != null) {
                  // Try admin_notifications first
                  try {
                    final result = await SupabaseService.client
                        .from('admin_notifications')
                        .update({'is_read': true})
                        .eq('id', notificationId)
                        .select();
                    if (result.isEmpty) {
                      // If no rows updated, try technician_notifications
                      await SupabaseService.client
                          .from('technician_notifications')
                          .update({'is_read': true})
                          .eq('id', notificationId);
                    }
                  } catch (e) {
                    // If that fails, try technician_notifications
                    try {
                      await SupabaseService.client
                          .from('technician_notifications')
                          .update({'is_read': true})
                          .eq('id', notificationId);
                    } catch (e2) {
                      debugPrint('Error marking notification as read: $e2');
                    }
                  }
                  
                  // Update local notification state immediately
                  notification['is_read'] = true;
                  
                  // Sync badge after marking as read
                  await BadgeService.syncBadgeWithDatabase(context);
                  // Refresh unread count
                  _refreshUnreadCount();
                  
                  // Trigger UI refresh
                  if (onNotificationUpdated != null) {
                    onNotificationUpdated();
                  }
                }
              } catch (e) {
                debugPrint('Error marking notification as read: $e');
              }
            }
            
            // Show notification details
            _showNotificationDetails(context, notification);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
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
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            ],
                          ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
      case 'tool_released':
        return Icons.move_to_inbox;
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
      case 'tool_released':
        return Colors.teal;
      case 'maintenance_request':
        return Colors.orange;
      case 'issue_report':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Parse a timestamp value from Supabase, handling UTC correctly.
  DateTime _parseTimestampValue(dynamic value) {
    if (value == null) return DateTime.now();
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc) return parsed.toLocal();
    // No timezone info — Supabase stores in UTC, so force UTC then convert
    return DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second,
      parsed.millisecond, parsed.microsecond,
    ).toLocal();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Use absolute difference to handle minor clock skew (future timestamps)
    final diff = difference.isNegative ? Duration.zero : difference;
    if (diff.inSeconds < 10) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _showNotificationDetails(BuildContext context, Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] != null
        ? _parseTimestampValue(notification['timestamp'])
        : DateTime.now();
    final type = notification['type'] as String? ?? 'general';
    final rawData = notification['data'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : null;
    final notificationColor = _getNotificationColor(type);
    final authProvider = context.read<AuthProvider>();
    final isToolRequestForCurrentHolder = type == 'tool_request' &&
        data != null &&
        (data['owner_id']?.toString() == authProvider.userId) &&
        data['action_taken'] == null;
    final isToolReleasedForCurrentUser = type == 'tool_released' &&
        data != null &&
        data['released_by_id'] != null &&
        data['action_taken'] == null &&
        data['accepted_by_id'] == null &&
        data['declined_by_id'] == null;
    final isToolAssignedForCurrentUser = (type == 'tool_assigned' || type == 'tool_assignment') &&
        data != null &&
        data['tool_id'] != null &&
        data['action_taken'] == null;
    final requesterName = data?['requester_name']?.toString() ?? 'the requester';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: notificationColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: notificationColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              if (data != null && data.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Text(
                  'Details:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                if (data['tool_name'] != null)
                  _buildDetailRow(
                    context,
                    'Tool',
                    data['tool_name'].toString(),
                    Icons.build,
                  ),
                if (data['requester_name'] != null)
                  _buildDetailRow(
                    context,
                    'Requested by',
                    data['requester_name'].toString(),
                    Icons.person,
                  ),
                if (data['released_by_name'] != null)
                  _buildDetailRow(
                    context,
                    'Released by',
                    data['released_by_name'].toString(),
                    Icons.person_outline,
                  ),
                if (data['requester_email'] != null)
                  _buildDetailRow(
                    context,
                    'Email',
                    data['requester_email'].toString(),
                    Icons.email,
                  ),
              ],
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              Divider(color: Colors.grey.withValues(alpha: 0.2)),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              // Show completed status if action was already taken
              if (data != null && data['action_taken'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: data['action_taken'] == 'declined'
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: data['action_taken'] == 'declined'
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        data['action_taken'] == 'declined'
                            ? Icons.cancel_outlined
                            : Icons.check_circle_outline,
                        size: 16,
                        color: data['action_taken'] == 'declined' ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['action_taken'] == 'declined'
                            ? 'You declined this'
                            : data['action_taken'] == 'released'
                                ? 'You released this tool'
                                : 'You accepted this',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: data['action_taken'] == 'declined' ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Accept/Decline buttons for tool assignment
              if (isToolAssignedForCurrentUser) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _declineAssignedTool(context, data!, notification);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _acceptAssignedTool(context, data!, notification);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isToolRequestForCurrentHolder)
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _releaseToolToRequester(context, data!, notification);
              },
              icon: const Icon(Icons.handshake, size: 18),
              label: Text('Release to $requesterName'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          if (isToolReleasedForCurrentUser) ...[
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _declineReleasedTool(context, data!, notification);
              },
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Decline'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _acceptReleasedTool(context, data!, notification);
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Accept ${data?['tool_name'] ?? 'Tool'}'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
          if (!isToolAssignedForCurrentUser && !isToolReleasedForCurrentUser && !isToolRequestForCurrentHolder)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Patches the notification's data field in the DB with [updates] so that
  /// re-opening it reflects the new state (e.g. action_taken, accepted_by_id).
  Future<void> _markNotificationActedOn(
    Map<String, dynamic> notification,
    Map<String, dynamic> updates,
  ) async {
    final notificationId = notification['id']?.toString();
    if (notificationId == null) return;
    final currentData = notification['data'];
    final mergedData = {
      if (currentData is Map) ...Map<String, dynamic>.from(currentData),
      ...updates,
    };
    try {
      // Try technician_notifications first (most tool-action notifications land here)
      final result = await SupabaseService.client
          .from('technician_notifications')
          .update({'data': mergedData})
          .eq('id', notificationId)
          .select();
      if ((result as List).isEmpty) {
        await SupabaseService.client
            .from('admin_notifications')
            .update({'data': mergedData})
            .eq('id', notificationId);
      }
    } catch (_) {}
  }

  Future<void> _releaseToolToRequester(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic> notification,
  ) async {
    final toolId = data['tool_id']?.toString();
    final requesterId = data['requester_id']?.toString();
    final requesterName = data['requester_name']?.toString() ?? 'Requester';
    final toolName = data['tool_name']?.toString() ?? 'Tool';
    final authProvider = context.read<AuthProvider>();
    final holderName = authProvider.userFullName ?? 'A technician';

    if (toolId == null || requesterId == null) {
      if (context.mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Missing tool or requester information. Cannot release.',
        );
      }
      return;
    }

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      Tool? existingTool = toolProvider.getToolById(toolId);
      if (existingTool == null) {
        final res = await SupabaseService.client
            .from('tools')
            .select()
            .eq('id', toolId)
            .maybeSingle();
        if (res != null) {
          existingTool = Tool.fromMap(Map<String, dynamic>.from(res as Map));
        }
      }
      if (existingTool == null) {
        if (context.mounted) {
          AuthErrorHandler.showErrorSnackBar(
            context,
            'Tool not found. It may have been removed.',
          );
        }
        return;
      }

      // Set status to Pending Acceptance — requester must accept before tool is assigned
      await SupabaseService.client.from('tools').update({
        'status': 'Pending Acceptance',
        'assigned_to': requesterId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', toolId);

      await ToolHistoryService.record(
        toolId: toolId,
        toolName: toolName,
        action: ToolHistoryActions.releasedToRequester,
        description: '$holderName offered $toolName to $requesterName (pending acceptance)',
        oldValue: authProvider.userId,
        newValue: requesterId,
        performedById: authProvider.userId,
        performedByName: holderName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        metadata: {'requester_id': requesterId, 'requester_name': requesterName},
      );

      await toolProvider.loadTools();

      UserNameService.clearCacheForUser(requesterId);

      await SupabaseService.client.from('technician_notifications').insert({
        'user_id': requesterId,
        'title': 'Tool Assignment: $toolName',
        'message': '$holderName wants to release the $toolName to you. Please accept or decline.',
        'type': 'tool_assigned',
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'tool_id': toolId,
          'tool_name': toolName,
          'assigned_by_name': holderName,
          'assigned_by_id': authProvider.userId,
          'assignment_type': 'release',
        },
      });

      try {
        await PushNotificationService.sendToUser(
          userId: requesterId,
          title: 'Tool Assignment: $toolName',
          body: '$holderName wants to release the $toolName to you. Tap to accept or decline.',
          data: {
            'type': 'tool_assigned',
            'tool_id': toolId,
            'tool_name': toolName,
            'assigned_by_name': holderName,
            'assigned_by_id': authProvider.userId ?? '',
          },
        );
      } catch (_) {}

      await _markNotificationActedOn(notification, {'action_taken': 'released'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Release offer sent to $requesterName. Waiting for their acceptance.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to release tool: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _acceptReleasedTool(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic> notification,
  ) async {
    final toolId = data['tool_id']?.toString();
    final toolName = data['tool_name']?.toString() ?? 'Tool';
    final releasedByName = data['released_by_name']?.toString() ?? 'A technician';
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final currentUserName = authProvider.userFullName ?? 'A technician';

    if (toolId == null || currentUserId == null) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Missing tool or user information.');
      return;
    }

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      Tool? existingTool = toolProvider.getToolById(toolId);
      if (existingTool == null) {
        final res = await SupabaseService.client.from('tools').select().eq('id', toolId).maybeSingle();
        if (res != null) existingTool = Tool.fromMap(Map<String, dynamic>.from(res as Map));
      }
      if (existingTool == null) {
        if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Tool not found.');
        return;
      }

      if (existingTool.assignedTo != null && existingTool.assignedTo!.isNotEmpty && existingTool.assignedTo != currentUserId) {
        if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'This tool has already been assigned to someone else.');
        return;
      }

      final updatedTool = existingTool.copyWith(assignedTo: currentUserId, status: 'In Use', updatedAt: DateTime.now().toIso8601String());
      await toolProvider.updateTool(updatedTool);

      await ToolHistoryService.record(
        toolId: toolId, toolName: toolName,
        action: ToolHistoryActions.acceptedAssignment,
        description: '$currentUserName accepted the $toolName (released by $releasedByName)',
        oldValue: 'Pending Acceptance', newValue: 'In Use',
        performedById: currentUserId, performedByName: currentUserName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        metadata: {'released_by_name': releasedByName, 'released_by_id': data['released_by_id']?.toString()},
      );

      await toolProvider.loadTools();
      UserNameService.clearCacheForUser(currentUserId);

      // Notify the holder that requester accepted
      final releasedById = data['released_by_id']?.toString();
      if (releasedById != null) {
        try {
          await SupabaseService.client.from('technician_notifications').insert({
            'user_id': releasedById,
            'title': 'Release Accepted: $toolName',
            'message': '$currentUserName has accepted the $toolName. The tool is now assigned to them.',
            'type': 'tool_released',
            'is_read': false,
            'timestamp': DateTime.now().toIso8601String(),
            'data': {
              'tool_id': toolId,
              'tool_name': toolName,
              'accepted_by_id': currentUserId,
              'accepted_by_name': currentUserName,
            },
          });
        } catch (_) {}

        try {
          await PushNotificationService.sendToUser(
            userId: releasedById,
            title: 'Release Accepted: $toolName',
            body: '$currentUserName has accepted the $toolName.',
            data: {'type': 'tool_released', 'tool_id': toolId, 'tool_name': toolName},
          );
        } catch (_) {}
      }

      await _markNotificationActedOn(notification, {'action_taken': 'accepted', 'accepted_by_id': currentUserId});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have accepted the $toolName. It is now assigned to you.'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Failed to accept tool: ${e.toString()}');
    }
  }

  Future<void> _declineReleasedTool(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic> notification,
  ) async {
    final toolId = data['tool_id']?.toString();
    final toolName = data['tool_name']?.toString() ?? 'Tool';
    final releasedByName = data['released_by_name']?.toString() ?? 'A technician';
    final releasedById = data['released_by_id']?.toString();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final currentUserName = authProvider.userFullName ?? 'A technician';

    if (toolId == null || currentUserId == null) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Missing tool or user information.');
      return;
    }

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      await toolProvider.declineAssignment(toolId);

      await ToolHistoryService.record(
        toolId: toolId, toolName: toolName,
        action: ToolHistoryActions.declinedAssignment,
        description: '$currentUserName declined the release of $toolName (offered by $releasedByName)',
        oldValue: 'Pending Acceptance', newValue: 'Available',
        performedById: currentUserId, performedByName: currentUserName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        metadata: {'released_by_name': releasedByName, 'released_by_id': releasedById},
      );

      await toolProvider.loadTools();

      // Notify the holder that requester declined
      if (releasedById != null) {
        try {
          await SupabaseService.client.from('technician_notifications').insert({
            'user_id': releasedById,
            'title': 'Release Declined: $toolName',
            'message': '$currentUserName has declined the $toolName. The tool is now available.',
            'type': 'tool_released',
            'is_read': false,
            'timestamp': DateTime.now().toIso8601String(),
            'data': {
              'tool_id': toolId,
              'tool_name': toolName,
              'declined_by_id': currentUserId,
              'declined_by_name': currentUserName,
            },
          });
        } catch (_) {}

        try {
          await PushNotificationService.sendToUser(
            userId: releasedById,
            title: 'Release Declined: $toolName',
            body: '$currentUserName has declined the $toolName. It is now available.',
            data: {'type': 'tool_released', 'tool_id': toolId, 'tool_name': toolName},
          );
        } catch (_) {}
      }

      await _markNotificationActedOn(notification, {'action_taken': 'declined', 'declined_by_id': currentUserId});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You declined the $toolName. It is now available.'), backgroundColor: Colors.orange, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Failed to decline tool: ${e.toString()}');
    }
  }

  Future<void> _acceptAssignedTool(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic> notification,
  ) async {
    final toolId = data['tool_id']?.toString();
    final toolName = data['tool_name']?.toString() ?? 'Tool';
    final assignedByName = data['assigned_by_name']?.toString() ?? 'Admin';
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final currentUserName = authProvider.userFullName ?? 'A technician';

    if (toolId == null || currentUserId == null) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Missing tool or user information.');
      return;
    }

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      Tool? existingTool = toolProvider.getToolById(toolId);
      if (existingTool == null) {
        final res = await SupabaseService.client.from('tools').select().eq('id', toolId).maybeSingle();
        if (res != null) existingTool = Tool.fromMap(Map<String, dynamic>.from(res as Map));
      }
      if (existingTool == null) {
        if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Tool not found.');
        return;
      }

      if (existingTool.assignedTo != null && existingTool.assignedTo!.isNotEmpty && existingTool.assignedTo != currentUserId) {
        if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'This tool has been reassigned to someone else.');
        return;
      }

      final updatedTool = existingTool.copyWith(assignedTo: currentUserId, status: 'In Use', updatedAt: DateTime.now().toIso8601String());
      await toolProvider.updateTool(updatedTool);

      await ToolHistoryService.record(
        toolId: toolId, toolName: toolName,
        action: ToolHistoryActions.acceptedAssignment,
        description: '$currentUserName accepted tool assignment of $toolName (assigned by $assignedByName)',
        oldValue: 'Pending Acceptance', newValue: 'In Use',
        performedById: currentUserId, performedByName: currentUserName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        metadata: {'assigned_by_name': assignedByName, 'assigned_by_id': data['assigned_by_id']?.toString()},
      );

      await toolProvider.loadTools();
      UserNameService.clearCacheForUser(currentUserId);

      await _markNotificationActedOn(notification, {'action_taken': 'accepted', 'accepted_by_id': currentUserId});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have accepted the $toolName. It is now assigned to you.'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Failed to accept tool: ${e.toString()}');
    }
  }

  Future<void> _declineAssignedTool(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic> notification,
  ) async {
    final toolId = data['tool_id']?.toString();
    final toolName = data['tool_name']?.toString() ?? 'Tool';
    final assignedByName = data['assigned_by_name']?.toString() ?? 'Admin';
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final currentUserName = authProvider.userFullName ?? 'A technician';

    if (toolId == null || currentUserId == null) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Missing tool or user information.');
      return;
    }

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      await toolProvider.declineAssignment(toolId);

      await ToolHistoryService.record(
        toolId: toolId, toolName: toolName,
        action: ToolHistoryActions.declinedAssignment,
        description: '$currentUserName declined tool assignment of $toolName (assigned by $assignedByName)',
        oldValue: 'Pending Acceptance', newValue: 'Available',
        performedById: currentUserId, performedByName: currentUserName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        metadata: {'assigned_by_name': assignedByName},
      );

      await toolProvider.loadTools();

      // Notify admins
      try {
        await SupabaseService.client.rpc('create_admin_notification', params: {
          'p_title': 'Assignment Declined: $toolName',
          'p_message': '$currentUserName declined the assignment of $toolName.',
          'p_type': 'tool_assignment',
          'p_technician_name': currentUserName,
          'p_technician_email': authProvider.userEmail ?? '',
          'p_data': {
            'tool_id': toolId,
            'tool_name': toolName,
            'technician_name': currentUserName,
            'action': 'declined',
          },
        });
      } catch (_) {}

      try {
        await PushNotificationService.sendToAdmins(
          title: 'Assignment Declined: $toolName',
          body: '$currentUserName declined the assignment of $toolName.',
          data: {'type': 'tool_assignment', 'tool_id': toolId, 'tool_name': toolName},
          fromUserId: currentUserId,
        );
      } catch (_) {}

      await _markNotificationActedOn(notification, {'action_taken': 'declined', 'declined_by_id': currentUserId});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You declined the assignment of $toolName.'), backgroundColor: Colors.orange, duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (context.mounted) AuthErrorHandler.showErrorSnackBar(context, 'Failed to decline tool: ${e.toString()}');
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveIconSize(context, 14),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  List<Tool> _lastFeaturedTools = [];

  void _navigateToTab(int index, BuildContext context) {
    widget.onNavigateToTab(index);
  }

  Future<void> _openAddTool(
    BuildContext context,
    AuthProvider authProvider,
    SupabaseToolProvider toolProvider,
  ) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => authProvider.isAdmin
            ? const AddToolScreen(isFromMyTools: true)
            : const TechnicianAddToolScreen(),
      ),
    );
    if (added == true && mounted) {
      await toolProvider.loadTools();
    }
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

  void _setupAutoSlide(List<Tool> featuredTools) {
    // Don't setup auto-slide if there's only one or no tools
    if (featuredTools.length <= 1) {
      debugPrint('⏸️ Auto-slide disabled: ${featuredTools.length} tool(s)');
      _autoSlideTimer?.cancel();
      _autoSlideTimer = null;
      return;
    }
    
    // Only setup if the list actually changed OR timer is not running
    final toolsChanged = _lastFeaturedTools.length != featuredTools.length ||
        !_lastFeaturedTools.every((tool) => featuredTools.any((t) => t.id == tool.id));
    
    // Check if timer is actually active (not just exists)
    final timerIsActive = _autoSlideTimer != null && _autoSlideTimer!.isActive;
    
    if (!toolsChanged && timerIsActive) {
      debugPrint('✅ Auto-slide already running, skipping setup');
      return; // List hasn't changed and timer is active, don't reset
    }
    
    _lastFeaturedTools = List.from(featuredTools);
    
    // Cancel existing timer if any
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    
    // Wait for next frame to ensure PageController is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || featuredTools.isEmpty) return;
      
      // Double-check controller is ready
      if (!_sharedToolsController.hasClients) {
        debugPrint('⏳ PageController not ready, retrying...');
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _sharedToolsController.hasClients) {
            _startAutoSlideTimer(featuredTools);
          } else {
            // If still not ready, try again after another delay
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted && _sharedToolsController.hasClients) {
                _startAutoSlideTimer(featuredTools);
              }
            });
          }
        });
        return;
      }
      
      _startAutoSlideTimer(featuredTools);
    });
  }

  void _startAutoSlideTimer(List<Tool> featuredTools) {
    if (!mounted || featuredTools.isEmpty) return;
    
    // Cancel any existing timer first
    _autoSlideTimer?.cancel();
    
    // Setup new timer - start immediately, then repeat every 4 seconds
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _performAutoSlide(featuredTools, timer);
    });
    
    // Also trigger the first slide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _autoSlideTimer != null) {
        _performAutoSlide(featuredTools, null);
      }
    });
    
    debugPrint('✅ Auto-slide timer started for ${featuredTools.length} tools');
  }

  void _performAutoSlide(List<Tool> featuredTools, Timer? timer) {
    if (!mounted || featuredTools.isEmpty) {
      timer?.cancel();
      _autoSlideTimer = null;
      debugPrint('🛑 Auto-slide timer cancelled: widget disposed or no tools');
      return;
    }
    
    // Check if controller is attached
    if (!_sharedToolsController.hasClients) {
      debugPrint('⏸️ PageController not attached, will retry setup...');
      // Try to restart the timer setup if controller becomes available
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _sharedToolsController.hasClients && _autoSlideTimer == null) {
          debugPrint('🔄 PageController now available, restarting auto-slide...');
          _startAutoSlideTimer(featuredTools);
        }
      });
      return; // Skip this iteration, try again next time
    }
    
    try {
      final currentPage = _sharedToolsController.page ?? 0;
      final nextPage = (currentPage.round() + 1) % featuredTools.length;
      
      debugPrint('🔄 Auto-sliding from page ${currentPage.round()} to $nextPage (of ${featuredTools.length})');
      
      _sharedToolsController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('❌ Error in auto-slide: $e');
      // If there's an error, try to restart the timer
      if (mounted && _autoSlideTimer != null) {
        _autoSlideTimer?.cancel();
        _autoSlideTimer = null;
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && _sharedToolsController.hasClients) {
            _startAutoSlideTimer(featuredTools);
          }
        });
      }
    }
  }

  // ── Greeting helpers ──────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.split(RegExp(r'\s+')).first;
  }

  BoxDecoration _mobileCardDeco(bool isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: const Color(0xFF2A2A2A)) : null,
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

  Widget _buildGreetingCard(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final displayName = _resolveDisplayName(authProvider);
    final firstName = _getFirstName(displayName);
    final greeting =
        firstName.isEmpty ? '${_getGreeting()}!' : '${_getGreeting()}, $firstName';
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

  Widget _buildStatCards(
    BuildContext context, {
    required void Function(String label) onCardTap,
    required int totalTools,
    required int availableCount,
    required int sharedCount,
    required int complianceActionCount,
    required int calibrationDueCount,
    required int maintenanceCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cards = <Map<String, dynamic>>[
      {
        'label': 'Total Tools',
        'count': totalTools,
        'icon': Icons.build_rounded,
        'color': Colors.blue,
        'subtitle': totalTools == 0 ? 'No assigned tools' : '$totalTools assigned',
      },
      {
        'label': 'Available',
        'count': availableCount,
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF059669),
        'subtitle': totalTools > 0
            ? '${((availableCount / totalTools) * 100).round()}% of total'
            : '0% of total',
      },
      {
        'label': 'Shared',
        'count': sharedCount,
        'icon': Icons.groups_2_rounded,
        'color': const Color(0xFF7C3AED),
        'subtitle': sharedCount == 1 ? '1 shared tool' : '$sharedCount shared tools',
      },
      {
        'label': 'Compliance',
        'count': complianceActionCount,
        'icon': Icons.verified_rounded,
        'color': complianceActionCount > 0
            ? const Color(0xFFF59E0B)
            : const Color(0xFF059669),
        'subtitle':
            complianceActionCount > 0 ? '$complianceActionCount need action' : 'All valid',
      },
      {
        'label': 'Calibration',
        'count': calibrationDueCount,
        'icon': Icons.precision_manufacturing_rounded,
        'color': calibrationDueCount > 0
            ? const Color(0xFFF59E0B)
            : Colors.blue,
        'subtitle':
            calibrationDueCount > 0 ? '$calibrationDueCount due/overdue' : 'All current',
      },
      {
        'label': 'Maintenance',
        'count': maintenanceCount,
        'icon': Icons.build_circle_rounded,
        'color': maintenanceCount > 0
            ? const Color(0xFFF59E0B)
            : const Color(0xFF059669),
        'subtitle':
            maintenanceCount > 0 ? '$maintenanceCount need service' : 'All healthy',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (_, i) {
        final card = cards[i];
        final color = card['color'] as Color;
        final icon = card['icon'] as IconData;
        final label = card['label'] as String;
        final count = card['count'] as int;
        final subtitle = card['subtitle'] as String;
        return GestureDetector(
          onTap: () => onCardTap(label),
          child: Container(
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
                        label.toUpperCase(),
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
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color,
                            height: 1.0,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
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
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<ToolHistory>> _loadRecentActivityForTools(Set<String> toolIds) async {
    if (toolIds.isEmpty) return <ToolHistory>[];
    final all = await ToolHistoryService.getAllHistory(limit: 80);
    return all.where((h) => toolIds.contains(h.toolId)).take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<SupabaseToolProvider, AuthProvider,
        SupabaseTechnicianProvider, SupabaseCertificationProvider>(
      builder:
          (context, toolProvider, authProvider, technicianProvider, certProvider, child) {
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

        // Tools assigned to this technician
        final myTools = currentUserId == null
            ? <Tool>[]
            : toolProvider.tools
                .where((tool) =>
                    tool.assignedTo == currentUserId &&
                    (tool.status == 'Assigned' || tool.status == 'In Use'))
                .toList();
        final myToolIds = myTools
            .map((t) => t.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet();
        final myComplianceCerts = certProvider.complianceCerts
            .where((c) => myToolIds.contains(c.toolId))
            .toList();
        final myCalibrationCerts = certProvider.calibrationCerts
            .where((c) => myToolIds.contains(c.toolId))
            .toList();
        final sharedCount = toolProvider.tools
            .where((tool) => tool.toolType == 'shared')
            .length;
        final availableCount = toolProvider.tools
            .where((tool) => tool.status == 'Available')
            .length;
        final complianceActionCount = myComplianceCerts
            .where((c) => c.isExpired || c.isExpiringSoon || c.status == 'Revoked')
            .length;
        final calibratedToolIds = myCalibrationCerts
            .where((c) => c.isValid && !c.isExpiringSoon)
            .map((c) => c.toolId)
            .toSet();
        final calibrationDueCount =
            myToolIds.isEmpty ? 0 : myToolIds.length - calibratedToolIds.length;
        final maintenanceCount = myTools.where((tool) {
          final status = tool.status.toLowerCase();
          final condition = tool.condition.toLowerCase();
          return status.contains('maintenance') ||
              status.contains('repair') ||
              condition.contains('maintenance') ||
              condition.contains('repair');
        }).length;

        if (toolProvider.isLoading) {
          return _buildSkeletonDashboard(context);
        }

        if (toolProvider.tools.isEmpty) {
          final theme = Theme.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                Text('No tools available',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Text(
                    'You have no assigned tools. You can request tool assignment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestNewToolScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.request_page_outlined, size: 18),
                  label: const Text('Request a Tool'),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final issueProvider = context.watch<ToolIssueProvider>();

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          strokeWidth: 2.5,
          onRefresh: () async {
            await toolProvider.loadTools();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: SafeArea(
                    bottom: false,
                    minimum: const EdgeInsets.only(top: 12),
                    child: _buildGreetingCard(context, authProvider),
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                // ── Stat cards ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatCards(
                    context,
                    onCardTap: (label) {
                      switch (label) {
                        case 'Total Tools':
                        case 'Available':
                          widget.onNavigateToTab(1);
                          break;
                        case 'Shared':
                          widget.onNavigateToTab(2);
                          break;
                        case 'Compliance':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ComplianceScreen(filterUserId: currentUserId)));
                          break;
                        case 'Calibration':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => CalibrationScreen(filterUserId: currentUserId)));
                          break;
                        case 'Maintenance':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => MaintenanceScreen(filterUserId: currentUserId)));
                          break;
                      }
                    },
                    totalTools: myTools.length,
                    availableCount: availableCount,
                    sharedCount: sharedCount,
                    complianceActionCount: complianceActionCount,
                    calibrationDueCount: calibrationDueCount,
                    maintenanceCount: maintenanceCount,
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

                // ── Quick Actions ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTechnicianQuickActionsGrid(context),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

                // ── Needs Attention ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Needs Attention',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNeedsAttentionCard(
                        context,
                        issueProvider: issueProvider,
                        myMaintenanceTools: myTools.where((t) {
                          final s = t.status.toLowerCase();
                          final c = t.condition.toLowerCase();
                          return s.contains('maintenance') ||
                              s.contains('repair') ||
                              c.contains('maintenance') ||
                              c.contains('repair');
                        }).take(2).toList(),
                        myToolIds: myToolIds,
                        userId: currentUserId,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

                // ── Recent Activity ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AllToolHistoryScreen()),
                            ),
                            icon: const Icon(Icons.history_rounded, size: 14),
                            label: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<ToolHistory>>(
                        future: _loadRecentActivityForTools(myToolIds),
                        builder: (context, snapshot) {
                          final recent = snapshot.data ?? const <ToolHistory>[];
                          final isDark = theme.brightness == Brightness.dark;
                          return Container(
                            width: double.infinity,
                            decoration: _mobileCardDeco(isDark).copyWith(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (snapshot.connectionState == ConnectionState.waiting)
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (recent.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 24),
                                    child: Text(
                                      'No recent activity',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      for (int i = 0; i < recent.length; i++) ...[
                                        Builder(builder: (context) {
                                          final item = recent[i];
                                          final (actionColor, actionIcon) =
                                              _activityActionStyle(item.action);
                                          final onSurface = theme.colorScheme.onSurface;
                                          final performedByText = (item.performedBy != null &&
                                                  item.performedBy!.isNotEmpty)
                                              ? ' · ${item.performedBy}'
                                              : '';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: actionColor.withValues(
                                                        alpha: isDark ? 0.18 : 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(actionIcon,
                                                      size: 18, color: actionColor),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.toolName,
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
                                                        '${item.actionDisplayName}$performedByText',
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
                                                  item.timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: onSurface.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (i < recent.length - 1)
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            indent: 62,
                                            endIndent: 16,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.08),
                                          ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  // placeholder — original block below (everything until _buildFeaturedCard) is removed

  Widget _buildFeaturedCard(Tool tool, BuildContext context,
      String? currentUserId, List<dynamic> technicians) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 180),
        padding: const EdgeInsets.all(12),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left thumbnail
            Container(
              width: 130,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        : (() {
                            try {
                              final file = File(tool.imagePath!);
                              if (file.existsSync()) {
                                return Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              }
                            } catch (e) {
                              // File doesn't exist or can't be accessed
                            }
                            return _buildPlaceholderImage(true);
                          })())
                    : _buildPlaceholderImage(true),
              ),
            ),
            const SizedBox(width: 12),
            // Right content
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // Tool name with shared badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  tool.name,
                                  style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                          'SHARED',
                                      style: TextStyle(
                            fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.secondaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  const SizedBox(height: 8),
                  // Status chips
                          Wrap(
                    spacing: 6,
                    runSpacing: 4,
                            children: [
                              _buildPillChip(
                                _getStatusIcon(tool.status),
                                _getStatusLabel(tool.status),
                                _getStatusColor(tool.status),
                              ),
                              _buildPillChip(
                                _getConditionIcon(tool.condition),
                                _getConditionLabel(tool.condition),
                                _getConditionColor(tool.condition),
                              ),
                            ],
                          ),
                  const SizedBox(height: 8),
                  // Category row
                              Row(
                                children: [
                                  Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                      const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tool.category.toUpperCase(),
                                      style: TextStyle(
                            fontSize: 11,
                                        color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                  // Brand (if available)
                  if (tool.brand != null && tool.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tool.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Holder line and request button
                  const SizedBox(height: 6),
                  Row(
                                children: [
                      Expanded(
                                    child: _holderLine(context, tool, technicians, currentUserId),
                                  ),
                                  // Show Request button for shared tools that have a holder (badged to someone else)
                                  if (tool.assignedTo != null &&
                                      tool.assignedTo!.isNotEmpty &&
                          (currentUserId == null || currentUserId != tool.assignedTo))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: TextButton(
                            onPressed: () => _sendToolRequest(context, tool),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                            child: const Text(
                                            'Request',
                                            style: TextStyle(
                                fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                            ),
                        ],
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
      AuthErrorHandler.showErrorSnackBar(
        context,
        'You need to be signed in to request a tool.',
      );
      return;
    }
    
    final ownerId = tool.assignedTo;
    if (ownerId == null || ownerId.isEmpty) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'This tool is not assigned to anyone.',
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
      
      // Tool requests from holders (badged tools) only go to the tool holder, not admins
      // Create notification in technician_notifications table for the tool owner
      // This will appear in the technician's notification center
      try {
        // Get requester's first name for better message format
        final requesterFirstName = requesterName.split(' ').first;
        
        await SupabaseService.client.from('technician_notifications').insert({
          'user_id': ownerId, // The technician who has the tool
          'title': 'Tool Request: ${tool.name}',
          'message': '$requesterFirstName has requested the ${tool.name}',
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
        
        // Send push notification to the tool holder
        try {
          final pushSuccess = await PushNotificationService.sendToUser(
            userId: ownerId,
            title: 'Tool Request: ${tool.name}',
            body: '$requesterFirstName has requested the ${tool.name}',
            data: {
              'type': 'tool_request',
              'tool_id': tool.id,
              'requester_id': requesterId,
            },
          );
          if (pushSuccess) {
            debugPrint('✅ Push notification sent successfully to tool holder: $ownerId');
          } else {
            debugPrint('⚠️ Push notification returned false for tool holder: $ownerId');
          }
        } catch (pushError, stackTrace) {
          debugPrint('❌ Exception sending push notification to tool holder: $pushError');
          debugPrint('❌ Stack trace: $stackTrace');
          // Don't fail the whole operation if push fails
        }
        
        // Note: The realtime subscription should automatically pick up the new notification
        // But we can't refresh the provider here because we don't have access to the tool holder's context
        // The realtime subscription in TechnicianNotificationProvider will handle this
        debugPrint('✅ Notification created - realtime subscription should update the UI');
      } catch (e) {
        debugPrint('❌ Failed to create technician notification: $e');
        debugPrint('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Tool request sent to ${tool.assignedTo == requesterId ? 'the owner' : 'the tool holder'}',
        );
      }
    } catch (e) {
      debugPrint('Error sending tool request: $e');
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to send request: $e',
        );
      }
    }
  }

  Widget _buildLatestCard(
      Tool tool, BuildContext context, List<dynamic> technicians, String? currentUserId) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 160),
        padding: const EdgeInsets.all(12),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left thumbnail
            Container(
              width: 120,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                          : (() {
                              try {
                                final file = File(tool.imagePath!);
                                if (file.existsSync()) {
                                  return Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                }
                              } catch (e) {
                                // File doesn't exist or can't be accessed
                              }
                              return _buildPlaceholderImage(false);
                            })())
                    : _buildPlaceholderImage(false),
              ),
            ),
            const SizedBox(width: 12),
            // Right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  // Tool name with optional shared badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tool.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tool.toolType == 'shared')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SHARED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                  const SizedBox(height: 8),
                  // Status chips
                    Wrap(
                    spacing: 6,
                    runSpacing: 4,
                      children: [
                        _buildPillChip(
                          _getStatusIcon(tool.status),
                          _getStatusLabel(tool.status),
                          _getStatusColor(tool.status),
                        ),
                        _buildPillChip(
                          _getConditionIcon(tool.condition),
                          _getConditionLabel(tool.condition),
                          _getConditionColor(tool.condition),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Category row
                        Row(
                          children: [
                            Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                      const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tool.category.toUpperCase(),
                                style: TextStyle(
                            fontSize: 11,
                                  color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                  // Brand (if available)
                  if (tool.brand != null && tool.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tool.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  ],
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
            : context.cardBackground, // ChatGPT-style: #F5F5F5 instead of grey
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

  Widget _buildPillChip(IconData icon, String text, Color color) {
    final tintedBackground = color.withOpacity(
      color.opacity < 1 ? color.opacity : 0.12,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: tintedBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveIconSize(context, 14),
            color: color,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _holderLine(
      BuildContext context, Tool tool, List<dynamic> technicians, String? currentUserId) {
    final theme = Theme.of(context);

    if (tool.assignedTo == null || tool.assignedTo!.isEmpty) {
      return Text(
        'No current holder',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Try in-memory technicians first (assignedTo = auth user ID when badged; match by user_id or id)
    final techProvider = context.read<SupabaseTechnicianProvider>();
    final nameFromProvider = techProvider.getTechnicianNameById(tool.assignedTo!);
    if (nameFromProvider != null && nameFromProvider.isNotEmpty) {
      final displayName = UserNameService.getFirstName(nameFromProvider);
      return Text(
        '$displayName has this tool',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Fallback: fetch from UserNameService (technicians table by user_id, then users table)
    return FutureBuilder<String>(
      future: UserNameService.getUserName(tool.assignedTo!),
      builder: (context, snapshot) {
        String name = 'Unknown';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          final fullName = snapshot.data!;
          if (fullName != 'Unknown') {
            name = UserNameService.getFirstName(fullName);
          }
        }
        return Text(
          '$name has this tool',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
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


  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'in use':
        return Icons.build;
      case 'maintenance':
        return Icons.warning;
      case 'retired':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
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
      case 'in use':
        return AppTheme.secondaryColor;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Icons.check_circle;
      case 'fair':
      case 'maintenance':
        return Icons.warning;
      case 'poor':
      case 'needs repair':
      case 'retired':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getConditionLabel(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return 'Faulty';
    return condition;
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
      case 'needs repair':
        return Colors.red;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _greeting(String? fullName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    if (fullName == null || fullName.trim().isEmpty) {
      return '$salutation!';
    }
    final name = fullName.split(RegExp(r"\s+")).first;
    return '$salutation, $name!';
  }

  // ── Activity action icon/colour ───────────────────────────
  (Color, IconData) _activityActionStyle(String action) {
    return switch (action) {
      'Assigned' || 'Accepted Assignment' =>
        (Colors.blue, Icons.person_add_rounded),
      'Returned' || 'Released to Requester' =>
        (AppTheme.primaryColor, Icons.assignment_return_rounded),
      'Maintenance' => (Colors.orange, Icons.build_rounded),
      'Created' => (AppTheme.primaryColor, Icons.add_circle_rounded),
      'Updated' || 'Edited' => (Colors.blueGrey, Icons.edit_rounded),
      'Status Changed' => (Colors.purple, Icons.swap_horiz_rounded),
      'Deleted' => (Colors.red, Icons.delete_rounded),
      'Transferred' => (Colors.teal, Icons.swap_horizontal_circle_rounded),
      _ => (Colors.blueGrey, Icons.history_rounded),
    };
  }

  // ── Needs Attention card (filtered to technician's tools) ─
  Widget _buildNeedsAttentionCard(
    BuildContext context, {
    required ToolIssueProvider issueProvider,
    required List<Tool> myMaintenanceTools,
    required Set<String> myToolIds,
    String? userId,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    // Only show issues that belong to the technician's own tools
    final urgentIssues = [
      ...issueProvider.criticalIssues.where(
          (i) => (i.isOpen || i.isInProgress) && myToolIds.contains(i.toolId)),
      ...issueProvider.highPriorityIssues.where((i) =>
          (i.isOpen || i.isInProgress) &&
          !i.isCritical &&
          myToolIds.contains(i.toolId)),
    ].take(3).toList();

    final allEmpty = urgentIssues.isEmpty && myMaintenanceTools.isEmpty;

    final cardDeco = _mobileCardDeco(isDark).copyWith(
      borderRadius: BorderRadius.circular(16),
    );
    final dividerColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EAED);

    if (allEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: cardDeco,
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text('All good!',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
            const SizedBox(height: 2),
            Text('No items need attention',
                style: TextStyle(
                    fontSize: 12, color: onSurface.withValues(alpha: 0.45))),
          ],
        ),
      );
    }

    final tiles = <Widget>[];

    for (int i = 0; i < urgentIssues.length; i++) {
      final issue = urgentIssues[i];
      final isCritical = issue.isCritical;
      tiles.add(_buildAttentionTile(
        context,
        icon: Icons.warning_amber_rounded,
        iconColor: isCritical ? Colors.red : Colors.orange,
        title: issue.toolName,
        subtitle:
            '${issue.issueType} · ${issue.description.length > 50 ? '${issue.description.substring(0, 50)}…' : issue.description}',
        badge: isCritical ? 'Critical' : 'High',
        badgeColor: isCritical ? Colors.red : Colors.orange,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ToolIssuesScreen())),
      ));
      if (i < urgentIssues.length - 1 || myMaintenanceTools.isNotEmpty) {
        tiles.add(Divider(
            height: 1, thickness: 1, indent: 56, endIndent: 16, color: dividerColor));
      }
    }

    for (int i = 0; i < myMaintenanceTools.length; i++) {
      final tool = myMaintenanceTools[i];
      tiles.add(_buildAttentionTile(
        context,
        icon: Icons.build_rounded,
        iconColor: Colors.deepOrange,
        title: tool.name,
        subtitle: 'Maintenance required',
        badge: 'Overdue',
        badgeColor: Colors.deepOrange,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => MaintenanceScreen(filterUserId: userId))),
      ));
      if (i < myMaintenanceTools.length - 1) {
        tiles.add(Divider(
            height: 1, thickness: 1, indent: 56, endIndent: 16, color: dividerColor));
      }
    }

    return Container(
      width: double.infinity,
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
              child: Text(badge,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions grid ────────────────────────────────────
  Widget _buildTechnicianQuickActionsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = <({String title, IconData icon, Color color, VoidCallback onTap})>[
      (
        title: 'Add Tool',
        icon: Icons.add_circle_outline_rounded,
        color: Colors.indigo,
        onTap: () => _openAddTool(
          context,
          context.read<AuthProvider>(),
          context.read<SupabaseToolProvider>(),
        ),
      ),
      (
        title: 'Request Tool',
        icon: Icons.request_page_outlined,
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RequestNewToolScreen())),
      ),
      (
        title: 'Report Issue',
        icon: Icons.report_problem_rounded,
        color: Colors.red,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddToolIssueScreen())),
      ),
      (
        title: 'Tool History',
        icon: Icons.history_rounded,
        color: Colors.purple,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllToolHistoryScreen())),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: actions
          .map((a) => _buildQuickActionCard(context, isDark, a.title, a.icon,
              a.color, a.onTap))
          .toList(),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ── Display name resolver ─────────────────────────────────
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

  Widget _buildSkeletonDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode
        ? Colors.grey[800]!.withValues(alpha: 0.3)
        : Colors.grey[300]!;
    final highlightColor = isDarkMode
        ? Colors.grey[700]!.withValues(alpha: 0.5)
        : Colors.grey[400]!;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      color: context.scaffoldBackground,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 260,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 34),
                    borderRadius: BorderRadius.circular(8),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    borderRadius: BorderRadius.circular(6),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

            // Stat cards skeleton (6 cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (_, __) => Container(
                  decoration: _mobileCardDeco(isDarkMode).copyWith(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SkeletonLoader(
                              width: 76,
                              height: 9,
                              borderRadius: BorderRadius.circular(4),
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                            const SizedBox(height: 6),
                            SkeletonLoader(
                              width: 40,
                              height: 20,
                              borderRadius: BorderRadius.circular(4),
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                            const SizedBox(height: 6),
                            SkeletonLoader(
                              width: 88,
                              height: 10,
                              borderRadius: BorderRadius.circular(4),
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                          ],
                        ),
                      ),
                      SkeletonLoader(
                        width: 32,
                        height: 32,
                        borderRadius: BorderRadius.circular(8),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

            // Quick actions skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 110,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3.2,
                    ),
                    itemBuilder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: _mobileCardDeco(isDarkMode),
                      child: Row(
                        children: [
                          Expanded(
                            child: SkeletonLoader(
                              width: 70,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SkeletonLoader(
                            width: 28,
                            height: 28,
                            borderRadius: BorderRadius.circular(8),
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

            // Needs attention skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 118,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: _mobileCardDeco(isDarkMode).copyWith(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < 2; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                SkeletonLoader(
                                  width: 36,
                                  height: 36,
                                  borderRadius: BorderRadius.circular(10),
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SkeletonLoader(
                                        width: 130,
                                        height: 12,
                                        borderRadius: BorderRadius.circular(4),
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                      const SizedBox(height: 6),
                                      SkeletonLoader(
                                        width: 160,
                                        height: 10,
                                        borderRadius: BorderRadius.circular(4),
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SkeletonLoader(
                                  width: 52,
                                  height: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                              ],
                            ),
                          ),
                          if (i < 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 56,
                              endIndent: 16,
                              color: onSurface.withValues(alpha: 0.08),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),

            // Recent activity skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 110,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const Spacer(),
                      SkeletonLoader(
                        width: 72,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: _mobileCardDeco(isDarkMode).copyWith(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                SkeletonLoader(
                                  width: 36,
                                  height: 36,
                                  borderRadius: BorderRadius.circular(10),
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SkeletonLoader(
                                        width: 120,
                                        height: 12,
                                        borderRadius: BorderRadius.circular(4),
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                      const SizedBox(height: 6),
                                      SkeletonLoader(
                                        width: 150,
                                        height: 10,
                                        borderRadius: BorderRadius.circular(4),
                                        baseColor: baseColor,
                                        highlightColor: highlightColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SkeletonLoader(
                                  width: 42,
                                  height: 10,
                                  borderRadius: BorderRadius.circular(4),
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                ),
                              ],
                            ),
                          ),
                          if (i < 2)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 62,
                              endIndent: 16,
                              color: onSurface.withValues(alpha: 0.08),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
          ],
        ),
      ),
    );
  }
}
