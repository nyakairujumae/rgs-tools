import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../utils/account_deletion_helper.dart';
import 'settings_screen.dart';
import 'auth/login_screen.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Consumer2<AuthProvider, OrganizationProvider>(
          builder: (context, auth, org, _) {
            final name = auth.userFullName?.trim() ?? '';
            final email = auth.userEmail ?? '';
            final role = auth.isAdmin ? 'Admin' : (org.workerLabel.isNotEmpty ? org.workerLabel : 'Technician');
            final initials = _initials(name.isNotEmpty ? name : email);

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar + identity card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE8E8EC),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Green accent strip
                            Container(width: 4, color: AppTheme.secondaryColor),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar circle
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name.isNotEmpty ? name : email.split('@').first,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        role,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preferences section
                  _sectionLabel(context, 'Preferences'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _groupCard(context, [
                      // Dark mode toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) => _settingsRow(
                          context,
                          icon: Icons.dark_mode_outlined,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Dark Mode',
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (val) => themeProvider.setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            ),
                            activeColor: AppTheme.secondaryColor,
                          ),
                          showDivider: false,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Account section
                  _sectionLabel(context, 'Account'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _groupCard(context, [
                      _settingsRow(
                        context,
                        icon: Icons.settings_outlined,
                        iconColor: const Color(0xFF6B7280),
                        title: 'Settings',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        showDivider: auth.isAdmin,
                      ),
                      if (auth.isAdmin)
                        _settingsRow(
                          context,
                          icon: Icons.switch_account_outlined,
                          iconColor: AppTheme.secondaryColor,
                          title: 'Switch Role',
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                          ),
                          showDivider: false,
                        ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Danger zone
                  _sectionLabel(context, 'Session'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _groupCard(context, [
                      _settingsRow(
                        context,
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Sign Out',
                        titleColor: const Color(0xFFEF4444),
                        onTap: () => _confirmSignOut(context, auth),
                        showDivider: true,
                      ),
                      _settingsRow(
                        context,
                        icon: Icons.delete_outline_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Delete Account',
                        titleColor: const Color(0xFFEF4444),
                        onTap: () => AccountDeletionHelper.showDeleteAccountDialog(context, auth),
                        showDivider: false,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),
                  // App version
                  Center(
                    child: Text(
                      '${AppConfig.appName} · v1.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _groupCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE8E8EC),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
    required bool showDivider,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFEEEEF2),
          ),
      ],
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
