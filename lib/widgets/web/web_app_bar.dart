import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/settings_screen.dart';

/// Desktop top app bar with breadcrumbs and user menu
class WebAppBar extends StatelessWidget {
  final String currentRoute;
  final List<String>? customBreadcrumbs;

  const WebAppBar({
    Key? key,
    required this.currentRoute,
    this.customBreadcrumbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.webDarkCardBackground : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getWebSidebarBorder(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(
            child: _buildBreadcrumbs(context, isDark),
          ),

          // Search (future enhancement)
          // IconButton(
          //   icon: Icon(Icons.search),
          //   onPressed: () {},
          //   tooltip: 'Search',
          // ),

          const SizedBox(width: 16),

          // Notifications
          _buildNotificationButton(context, isDark),

          const SizedBox(width: 16),

          // User menu
          _buildUserMenu(context, isDark),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, bool isDark) {
    final breadcrumbs = customBreadcrumbs ?? _generateBreadcrumbs(currentRoute);

    return Row(
      children: [
        for (int i = 0; i < breadcrumbs.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          Text(
            breadcrumbs[i],
            style: TextStyle(
              fontSize: i == breadcrumbs.length - 1 ? 16 : 14,
              fontWeight:
                  i == breadcrumbs.length - 1 ? FontWeight.w600 : FontWeight.w400,
              color: i == breadcrumbs.length - 1
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _generateBreadcrumbs(String route) {
    // Parse route to generate breadcrumbs
    // Example: '/admin/tools' -> ['Admin', 'Tools']
    if (route == '/admin' || route == '/admin/') {
      return ['Admin', 'Dashboard'];
    }

    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return ['Home'];

    final breadcrumbs = <String>[];
    for (final part in parts) {
      // Capitalize first letter and replace dashes with spaces
      final formatted = part
          .split('-')
          .map((word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1))
          .join(' ');
      breadcrumbs.add(formatted);
    }

    return breadcrumbs;
  }

  Widget _buildNotificationButton(BuildContext context, bool isDark) {
    // TODO: Connect to notification provider
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {
            // Navigate to notifications
            Navigator.pushNamed(context, '/admin/notifications');
          },
          tooltip: 'Notifications',
        ),
        // Badge indicator (show when there are unread notifications)
        // Positioned(
        //   right: 8,
        //   top: 8,
        //   child: Container(
        //     width: 8,
        //     height: 8,
        //     decoration: BoxDecoration(
        //       color: AppTheme.errorColor,
        //       shape: BoxShape.circle,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final userName =
        authProvider.user?.userMetadata?['full_name'] as String? ??
            authProvider.user?.email?.split('@').first ??
            'User';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            userName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: const [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: const [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Logout'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            // Navigate to profile
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
          case 'logout':
            await authProvider.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
            break;
        }
      },
    );
  }
}
