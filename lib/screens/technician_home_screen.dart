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
import 'request_new_tool_screen.dart';
import 'technician_my_tools_screen.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import 'settings_screen.dart';
import '../services/firebase_messaging_service.dart' if (dart.library.html) '../services/firebase_messaging_service_stub.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_card.dart';
import '../services/badge_service.dart';
import '../providers/admin_notification_provider.dart';
import '../providers/technician_notification_provider.dart';
import '../models/admin_notification.dart';
import '../models/technician_notification.dart';
import '../utils/responsive_helper.dart';
import '../utils/auth_error_handler.dart';
import '../models/user_role.dart';
import '../widgets/common/loading_widget.dart';

// Removed placeholder request/report screens; using detailed screens directly

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

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
      const RequestNewToolScreen(),
      AddToolIssueScreen(
        onNavigateToDashboard: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
      // Load notifications from provider (will set up realtime subscription)
      await context.read<TechnicianNotificationProvider>().loadNotifications();
      // Sync badge with database when screen initializes (like admin section)
      await BadgeService.syncBadgeWithDatabase(context);
      _refreshUnreadCount();
      // Refresh unread count and sync badge every 30 seconds (like admin section)
      _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !_isDisposed) {
          _refreshUnreadCount();
          // Also sync badge periodically to ensure it stays updated
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
      // Sync badge when app comes back to foreground (like admin section)
      BadgeService.syncBadgeWithDatabase(context).catchError((e) {
        debugPrint('⚠️ Error syncing badge on resume: $e');
      });
      _refreshUnreadCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _notificationRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    if (_isDisposed || !mounted) return;
    final count = await _getUnreadNotificationCount(context);
    if (mounted && !_isDisposed) {
      setState(() {
        _unreadNotificationCount = count;
      });
      // Sync badge with database count
      await BadgeService.syncBadgeWithDatabase(context);
    }
  }

  Widget _buildAccountMenuHeader(
      BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fullName = (authProvider.userFullName ?? 'Technician').trim();
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
    final fullName = authProvider.userFullName ?? 'Technician';
    final roleLabel = authProvider.userRole.displayName;
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: parentContext.cardDecoration,
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
      return 'T';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'T';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
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
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
        centerTitle: false,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading || authProvider.isLoggingOut) {
                return IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: null,
                );
              }
              
              return IconButton(
                icon: const Icon(Icons.account_circle, size: 24),
                onPressed: () => _showProfileBottomSheet(context, authProvider),
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
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            // Check In button - navigate to CheckinScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckinScreen(),
              ),
            );
          } else {
            setState(() => _selectedIndex = index.clamp(0, 2));
          }
        },
        type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Request Tool',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Issue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.keyboard_return, color: Colors.green),
            label: 'Check In',
            activeIcon: Icon(Icons.keyboard_return, color: Colors.green),
          ),
        ],
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
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
      return [];
    }
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification, VoidCallback? onNotificationUpdated) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] != null
        ? DateTime.parse(notification['timestamp'].toString())
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
            // Mark as read
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
  List<Tool> _lastFeaturedTools = [];

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

  void _setupAutoSlide(List<Tool> featuredTools) {
    // Only setup if the list actually changed
    final toolsChanged = _lastFeaturedTools.length != featuredTools.length ||
        !_lastFeaturedTools.every((tool) => featuredTools.any((t) => t.id == tool.id));
    
    if (!toolsChanged && _autoSlideTimer != null) {
      return; // List hasn't changed and timer is running, don't reset
    }
    
    _lastFeaturedTools = List.from(featuredTools);
    
    // Cancel existing timer if any
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    
    // Don't setup auto-slide if there's only one or no tools
    if (featuredTools.length <= 1) {
      debugPrint('⏸️ Auto-slide disabled: ${featuredTools.length} tool(s)');
      return;
    }
    
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
      debugPrint('⏸️ PageController not attached, skipping slide');
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
      // Don't cancel, just skip this iteration
    }
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
          return _buildSkeletonDashboard(context);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Initialize auto-slide when data is available
        _setupAutoSlide(featuredTools);

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        
        return Container(
          color: context.scaffoldBackground,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Welcome banner
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                ),
                      child: Container(
                width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(18),
                ),
                  child: Row(
                      children: [
                        Container(
                        width: ResponsiveHelper.getResponsiveIconSize(context, 72),
                        height: ResponsiveHelper.getResponsiveIconSize(context, 72),
                          decoration: BoxDecoration(
                        color: isDarkMode
                            ? theme.colorScheme.surfaceVariant
                            : context.cardBackground, // ChatGPT-style: #F5F5F5 instead of grey
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                          ),
                          ),
                          child: Icon(
                          Icons.inventory_2,
                          color: AppTheme.secondaryColor,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 36),
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
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                              Text(
                                'Manage your tools and access shared resources',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
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

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Shared Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Shared Tools Carousel (auto sliding)
              SizedBox(
                height: ResponsiveHelper.getResponsiveListItemHeight(context, 212),
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

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // My Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

              // Latest Tools Vertical List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                      bottom: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    ),
                                    child: _buildLatestCard(tool, context,
                                        technicianProvider.technicians, authProvider.user?.id),
                                  ))
                              .toList(),
                      ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
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
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
        ),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left thumbnail (wider like Featured)
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(context, 140),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tool.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tool.toolType == 'shared')
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveHelper.getResponsiveSpacing(context, 8),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 6),
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
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
                      ),
                  ],
                ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Wrap(
                      spacing: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 2),
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
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    if (tool.serialNumber != null && tool.serialNumber!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Expanded(
                              child: Text(
                                'SN: ${tool.serialNumber!}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tool.location != null && tool.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 3),
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
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                        if (tool.brand != null && tool.brand!.isNotEmpty || 
                            tool.model != null && tool.model!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: ResponsiveHelper.getResponsiveSpacing(context, 2),
                              left: ResponsiveHelper.getResponsiveIconSize(context, 16) + 
                                    ResponsiveHelper.getResponsiveSpacing(context, 6),
                            ),
                            child: Row(
                              children: [
                                if (tool.brand != null && tool.brand!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      tool.brand!,
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (tool.model != null && tool.model!.isNotEmpty)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: tool.brand != null && tool.brand!.isNotEmpty
                                            ? ResponsiveHelper.getResponsiveSpacing(context, 8)
                                            : 0,
                                      ),
                                      child: Text(
                                        tool.model!,
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Only show holder line and request button for shared tools (not for My Tools)
                    if (tool.toolType == 'shared')
                      Row(
                        children: [
                          Expanded(
                            child: _holderLine(context, tool, technicians, currentUserId),
                          ),
                          // Show Request button for shared tools that have a holder (badged to someone else)
                          if (tool.assignedTo != null &&
                              tool.assignedTo!.isNotEmpty &&
                              (currentUserId == null ||
                                  currentUserId != tool.assignedTo))
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      _sendToolRequest(context, tool),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.secondaryColor,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                      vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
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
      
      // Note: Approval workflows are automatically created by the database function
      // when create_admin_notification is called with type 'tool_request'
      
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
        
        // Send push notification to the tool holder
        try {
          await PushNotificationService.sendToUser(
            userId: ownerId,
            title: 'Tool Request: ${tool.name}',
            body: '$requesterName needs the tool "${tool.name}" that you currently have',
            data: {
              'type': 'tool_request',
              'tool_id': tool.id,
              'requester_id': requesterId,
            },
          );
          debugPrint('✅ Push notification sent to tool holder');
        } catch (pushError) {
          debugPrint('⚠️ Could not send push notification to tool holder: $pushError');
        }
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
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveListItemHeight(context, 172),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 12,
          vertical: 6,
        ),
        decoration: context.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left thumbnail (wider like Featured)
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(context, 140),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tool.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tool.toolType == 'shared')
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveHelper.getResponsiveSpacing(context, 8),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 6),
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
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
                      ),
                  ],
                ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Wrap(
                      spacing: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 2),
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
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    if (tool.serialNumber != null && tool.serialNumber!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Expanded(
                              child: Text(
                                'SN: ${tool.serialNumber!}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tool.location != null && tool.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, 3),
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
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                        if (tool.brand != null && tool.brand!.isNotEmpty || 
                            tool.model != null && tool.model!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: ResponsiveHelper.getResponsiveSpacing(context, 2),
                              left: ResponsiveHelper.getResponsiveIconSize(context, 16) + 
                                    ResponsiveHelper.getResponsiveSpacing(context, 6),
                            ),
                            child: Row(
                              children: [
                                if (tool.brand != null && tool.brand!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      tool.brand!,
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (tool.model != null && tool.model!.isNotEmpty)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: tool.brand != null && tool.brand!.isNotEmpty
                                            ? ResponsiveHelper.getResponsiveSpacing(context, 8)
                                            : 0,
                                      ),
                                      child: Text(
                                        tool.model!,
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tintedBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
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
    
    if (tool.assignedTo == null) {
      return Text(
        'No current holder',
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          );
        }
    
    // Don't show "has this tool" if it's assigned to the current user
    if (currentUserId != null && tool.assignedTo == currentUserId) {
      return const SizedBox.shrink();
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
    final name = (fullName == null || fullName.trim().isEmpty)
        ? 'Technician'
        : fullName.split(RegExp(r"\s+")).first;
    return '$salutation, $name!';
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

    return Container(
      color: context.scaffoldBackground,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner skeleton
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    SkeletonLoader(
                      width: ResponsiveHelper.getResponsiveIconSize(context, 72),
                      height: ResponsiveHelper.getResponsiveIconSize(context, 72),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                      ),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: double.infinity,
                            height: ResponsiveHelper.getResponsiveFontSize(context, 22),
                            borderRadius: BorderRadius.circular(4),
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                          SkeletonLoader(
                            width: double.infinity * 0.7,
                            height: ResponsiveHelper.getResponsiveFontSize(context, 15),
                            borderRadius: BorderRadius.circular(4),
                            baseColor: baseColor,
                            highlightColor: highlightColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // Shared Tools Section skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SkeletonLoader(
                    width: 80,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // Shared Tools Carousel skeleton
            SizedBox(
              height: ResponsiveHelper.getResponsiveListItemHeight(context, 212),
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                ),
                child: _buildFeaturedCardSkeleton(context, baseColor, highlightColor),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // My Tools Section skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SkeletonLoader(
                    width: 80,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),

            // My Tools List skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(2, (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.getResponsiveSpacing(context, 12),
                  ),
                  child: _buildLatestCardSkeleton(context, baseColor, highlightColor),
                )),
              ),
            ),

            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCardSkeleton(BuildContext context, Color baseColor, Color highlightColor) {
    return Container(
      height: ResponsiveHelper.getResponsiveListItemHeight(context, 200),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: ResponsiveHelper.getResponsiveIconSize(context, 140),
            height: double.infinity,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
            ),
            baseColor: baseColor,
            highlightColor: highlightColor,
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
                children: [
                  // Title skeleton
                  SkeletonLoader(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Chips skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      SkeletonLoader(
                        width: 70,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Serial number skeleton
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Location skeleton
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Category skeleton
                  SkeletonLoader(
                    width: 90,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Brand/Model skeleton
                  SkeletonLoader(
                    width: 150,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestCardSkeleton(BuildContext context, Color baseColor, Color highlightColor) {
    return Container(
      height: ResponsiveHelper.getResponsiveListItemHeight(context, 172),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 6,
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: ResponsiveHelper.getResponsiveIconSize(context, 140),
            height: double.infinity,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
            ),
            baseColor: baseColor,
            highlightColor: highlightColor,
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
                children: [
                  // Title skeleton
                  SkeletonLoader(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Chips skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      SkeletonLoader(
                        width: 70,
                        height: 24,
                        borderRadius: BorderRadius.circular(999),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Serial number skeleton
                  SkeletonLoader(
                    width: 120,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Location skeleton
                  SkeletonLoader(
                    width: 100,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  // Category skeleton
                  SkeletonLoader(
                    width: 90,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 3)),
                  // Brand/Model skeleton
                  SkeletonLoader(
                    width: 150,
                    height: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
