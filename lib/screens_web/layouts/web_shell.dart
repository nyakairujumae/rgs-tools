import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/web/web_sidebar.dart';
import '../../widgets/web/web_app_bar.dart';

/// Master layout wrapper for desktop web experience
/// Contains: Sidebar + Top Bar + Content Area
class WebShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final List<WebNavItem> navItems;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;
  final List<String>? breadcrumbs;

  const WebShell({
    Key? key,
    required this.child,
    required this.currentRoute,
    required this.navItems,
    this.sidebarHeader,
    this.sidebarFooter,
    this.breadcrumbs,
  }) : super(key: key);

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppTheme.webDarkScaffoldBackground
        : AppTheme.webLightScaffoldBackground;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Row(
        children: [
          // Sidebar
          WebSidebar(
            collapsed: _sidebarCollapsed,
            onToggle: () {
              setState(() {
                _sidebarCollapsed = !_sidebarCollapsed;
              });
            },
            currentRoute: widget.currentRoute,
            navItems: widget.navItems,
            header: widget.sidebarHeader,
            footer: widget.sidebarFooter,
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top bar
                WebAppBar(
                  currentRoute: widget.currentRoute,
                  customBreadcrumbs: widget.breadcrumbs,
                ),

                // Content
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveHelper.getContentMaxWidth(context),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getWebContentPadding(context),
                        ),
                        child: widget.child,
                      ),
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
}
