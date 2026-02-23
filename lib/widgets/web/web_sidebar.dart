import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/responsive_helper.dart';

/// Navigation item model for sidebar
class WebNavItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badge;
  final List<WebNavItem>? children;

  const WebNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
    this.children,
  });
}

/// Collapsible sidebar navigation component for web desktop
class WebSidebar extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final String currentRoute;
  final List<WebNavItem> navItems;
  final Widget? header;
  final Widget? footer;

  const WebSidebar({
    Key? key,
    required this.collapsed,
    required this.onToggle,
    required this.currentRoute,
    required this.navItems,
    this.header,
    this.footer,
  }) : super(key: key);

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  String? _hoveredRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = AppTheme.getWebSidebarBackground(context);
    final sidebarBorder = AppTheme.getWebSidebarBorder(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: ResponsiveHelper.getSidebarWidth(collapsed: widget.collapsed),
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: sidebarBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header section
          if (widget.header != null) widget.header!,

          // Logo / Brand section
          _buildLogoSection(isDark),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in widget.navItems)
                  _buildNavItem(
                    item,
                    isActive: widget.currentRoute.startsWith(item.route),
                    isDark: isDark,
                  ),
              ],
            ),
          ),

          // Footer section (user profile, settings, etc.)
          if (widget.footer != null) widget.footer!,

          // Collapse toggle button
          _buildCollapseButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getWebSidebarBorder(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.build_circle,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          if (!widget.collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'RGS Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(WebNavItem item, {required bool isActive, required bool isDark}) {
    final isHovered = _hoveredRoute == item.route;

    Color getItemColor() {
      if (isActive) {
        return AppTheme.primaryColor;
      } else if (isHovered) {
        return isDark ? Colors.white70 : Colors.black87;
      } else {
        return isDark ? Colors.white60 : Colors.black54;
      }
    }

    Color? getBackgroundColor() {
      if (isActive) {
        return AppTheme.primaryColor.withOpacity(0.1);
      } else if (isHovered) {
        return isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04);
      }
      return null;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRoute = item.route),
      onExit: (_) => setState(() => _hoveredRoute = null),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, item.route);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.collapsed)
                Center(
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: getItemColor(),
                  ),
                )
              else ...[
                Icon(
                  item.icon,
                  size: 20,
                  color: getItemColor(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: getItemColor(),
                    ),
                  ),
                ),
                // Badge
                if (item.badge != null && item.badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge! > 99 ? '99+' : item.badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.getWebSidebarBorder(context),
            width: 1,
          ),
        ),
      ),
      child: IconButton(
        icon: Icon(
          widget.collapsed ? Icons.chevron_right : Icons.chevron_left,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        onPressed: widget.onToggle,
        tooltip: widget.collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      ),
    );
  }
}

/// User profile section for sidebar footer
class SidebarUserProfile extends StatelessWidget {
  final bool collapsed;

  const SidebarUserProfile({
    Key? key,
    required this.collapsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName = authProvider.user?.userMetadata?['full_name'] as String? ??
        authProvider.user?.email?.split('@').first ??
        'User';
    final userRole = authProvider.isAdmin ? 'Admin' : 'Technician';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.getWebSidebarBorder(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: collapsed ? 16 : 20,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userRole,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Theme indicator widget for sidebar
/// Note: Theme follows system settings and cannot be toggled manually
class SidebarThemeToggle extends StatelessWidget {
  final bool collapsed;

  const SidebarThemeToggle({
    Key? key,
    required this.collapsed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!collapsed)
            Text(
              'Theme: ${isDark ? 'Dark' : 'Light'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            size: 20,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ],
      ),
    );
  }
}
