import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../services/csv_export_service.dart';
import '../utils/auth_error_handler.dart';
import 'terms_of_service_screen.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'AED';

  EdgeInsets _tilePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
      );

  Widget _buildCard(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
      ),
      child: child,
    );
  }

  Widget _iconBadge({
    required BuildContext context,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.getResponsiveSpacing(context, 10),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SingleChildScrollView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel(context, 'Account'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAccountCard(context, authProvider),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        _buildSectionLabel(context, 'Account Details'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAccountDetails(context, authProvider),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, 'Preferences'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildLanguageCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        _buildCurrencyCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, 'Notifications'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildNotificationCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, 'Data & Backup'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildBackupCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, 'About'),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAboutCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      ],
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fullName = authProvider.userFullName ?? 'Technician';
    final roleLabel = authProvider.isAdmin ? 'Administrator' : 'Technician';
    final initials = _getInitials(fullName);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 18),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isDesktop ? 30 : 32,
                backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 18 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 8 : 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 10 : 12,
                        vertical: isDesktop ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontSize: isDesktop ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryColor,
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
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildAccountDetails(BuildContext context, AuthProvider authProvider) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final email = authProvider.user?.email ?? 'Not available';
    final createdAt = authProvider.user?.createdAt;
    final memberSince = _formatMemberSince(createdAt);
    final roleLabel = authProvider.isAdmin ? 'Administrator' : 'Technician';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 10 : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          width: 1,
        ),
      ),
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }




  Widget _buildLanguageCard() {
    return _buildCard(
      context,
      ListTile(
        contentPadding: _tilePadding(context),
        leading: _iconBadge(
          context: context,
          color: AppTheme.secondaryColor,
          child: Icon(
            Icons.language,
            color: AppTheme.secondaryColor,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
        ),
        title: Text(
          'Language',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          _selectedLanguage,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: _showLanguageDialog,
      ),
    );
  }

  Widget _buildCurrencyCard() {
    return _buildCard(
      context,
      ListTile(
        contentPadding: _tilePadding(context),
        leading: _iconBadge(
          context: context,
          color: AppTheme.secondaryColor,
          child: Text(
            'د.إ',
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Currency',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          _selectedCurrency,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: _showCurrencyDialog,
      ),
    );
  }

  Widget _buildNotificationCard() {
    return _buildCard(
      context,
      SwitchListTile(
        contentPadding: _tilePadding(context),
        secondary: _iconBadge(
          context: context,
          color: AppTheme.secondaryColor,
          child: Icon(
            Icons.notifications,
            color: AppTheme.secondaryColor,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
        ),
        title: Text(
          'Push Notifications',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          'Receive maintenance reminders and updates',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        value: _notificationsEnabled,
        onChanged: (value) {
          setState(() {
            _notificationsEnabled = value;
          });
        },
      ),
    );
  }

  Widget _buildBackupCard() {
    return _buildCard(
      context,
      Column(
        children: [
          SwitchListTile(
            contentPadding: _tilePadding(context),
            secondary: _iconBadge(
              context: context,
          color: AppTheme.secondaryColor,
          child: Icon(
            Icons.backup,
            color: AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            title: Text(
              'Auto Backup',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Automatically backup data to cloud',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: _autoBackup,
            onChanged: (value) {
              setState(() {
                _autoBackup = value;
              });
            },
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
              color: AppTheme.secondaryColor,
              child: Icon(
                Icons.download,
                color: AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            title: Text(
              'Export Data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Download your data as CSV',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            onTap: _exportData,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
              color: AppTheme.secondaryColor,
              child: Icon(
                Icons.upload,
                color: AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            title: Text(
              'Import Data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Restore from backup file',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _buildCard(
      context,
      Column(
        children: [
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
          color: AppTheme.secondaryColor,
          child: Icon(
            Icons.info,
            color: AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            title: Text(
              'App Version',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _showVersionInfo,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
              color: AppTheme.secondaryColor,
              child: Icon(Icons.help, color: AppTheme.secondaryColor, size: 20),
            ),
            title: Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Get help and contact support',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _showHelp,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
              color: AppTheme.secondaryColor,
              child: Icon(Icons.privacy_tip, color: AppTheme.secondaryColor, size: 20),
            ),
            title: Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Read our privacy policy',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _showPrivacyPolicy,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: _tilePadding(context),
            leading: _iconBadge(
              context: context,
              color: AppTheme.secondaryColor,
              child: Icon(Icons.description, color: AppTheme.secondaryColor, size: 20),
            ),
            title: Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              'Read our terms of service',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _showTermsOfService,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Select Language',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'English'),
            _buildLanguageOption('العربية', 'Arabic'),
            _buildLanguageOption('Français', 'French'),
            _buildLanguageOption('Español', 'Spanish'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String displayName, String value) {
    final isSelected = _selectedLanguage == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.secondaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Select Currency',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption('USD', 'US Dollar'),
            _buildCurrencyOption('EUR', 'Euro'),
            _buildCurrencyOption('GBP', 'British Pound'),
            _buildCurrencyOption('AED', 'UAE Dirham'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    final isSelected = _selectedCurrency == code;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCurrency = code;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.secondaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get providers
      final toolProvider = context.read<SupabaseToolProvider>();
      final technicianProvider = context.read<SupabaseTechnicianProvider>();
      final authProvider = context.read<AuthProvider>();

      // Refresh data to ensure we have latest
      await toolProvider.loadTools();
      await technicianProvider.loadTechnicians();

      // Export data
      final files = await CsvExportService.exportUserData(
        tools: toolProvider.tools,
        technicians: technicianProvider.technicians,
        userId: authProvider.user?.id,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (context.mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Data exported successfully! ${files.length} file(s) created.',
        );

        // Open the first file
        if (files.isNotEmpty) {
          try {
            await OpenFile.open(files.first.path);
          } catch (e) {
            debugPrint('Could not open file: $e');
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Error exporting data: $e',
        );
      }
    }
  }

  void _importData() {
    // Show information dialog about import
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'To import data, please contact support at support@rgstools.app. '
          'We will help you restore your data from a backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RGS Tools Manager',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Version: 1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Build: 2024.01.15',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 RGS Tools. All rights reserved.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelp() async {
    final url = Uri.parse('https://rgstools.app/support');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open support page'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening support page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPrivacyPolicy() async {
    final url = Uri.parse('https://rgstools.app/privacy');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy page'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening privacy policy page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
