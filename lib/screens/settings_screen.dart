import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import 'org_departments_screen.dart';
import 'org_tool_categories_screen.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../services/csv_export_service.dart';
import '../utils/auth_error_handler.dart';
import '../utils/account_deletion_helper.dart';
import 'terms_of_service_screen.dart';
import 'package:intl/intl.dart';
import '../utils/logger.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  String _selectedCurrency = 'AED';

  EdgeInsets _tilePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
      );

  BoxDecoration _settingsCardDecoration(BuildContext context) {
    final r = ResponsiveHelper.getResponsiveBorderRadius(context, 16);
    return AppTheme.groupedCardDecoration(context, radius: r);
  }

  Widget _buildCard(BuildContext context, Widget child) {
    return Container(
      decoration: _settingsCardDecoration(context),
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
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).settings_title,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                        Text(
                          'Manage your profile and app preferences',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_accountSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAccountCard(context, authProvider),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_accountDetailsSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAccountDetails(context, authProvider),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_accountManagementSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildAccountManagementCard(authProvider),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_preferencesSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildLanguageCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        _buildCurrencyCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_notificationsSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildNotificationCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_dataBackupSection),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        _buildBackupCard(),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        _buildSectionLabel(context, AppLocalizations.of(context).settings_aboutSection),
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
        letterSpacing: 0.35,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    final fullName = authProvider.userFullName ?? 'Account';
    final roleLabel = authProvider.isAdmin
        ? l10n.technicianHome_administrator
        : l10n.technicianHome_technician;
    final initials = _getInitials(fullName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _settingsCardDecoration(context),
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
                Text(
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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildAccountDetails(BuildContext context, AuthProvider authProvider) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    final email = authProvider.user?.email ?? 'Not available';
    final createdAt = authProvider.user?.createdAt;
    final memberSince = _formatMemberSince(createdAt);
    final roleLabel = authProvider.isAdmin
        ? l10n.technicianHome_administrator
        : l10n.technicianHome_technician;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
      decoration: _settingsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountDetailRow(context, l10n.common_email, email),
          SizedBox(height: isDesktop ? 8 : 10),
          _buildAccountDetailRow(
              context, l10n.adminHome_memberSince, memberSince),
          SizedBox(height: isDesktop ? 8 : 10),
          _buildAccountDetailRow(context, l10n.adminHome_role, roleLabel),
        ],
      ),
    );
  }

  Widget _buildAccountManagementCard(AuthProvider authProvider) {
    final isAdmin = authProvider.isAdmin;
    final l10n = AppLocalizations.of(context);
    final title = isAdmin
        ? l10n.settings_deleteAccount
        : l10n.settings_requestAccountDeletion;
    final subtitle = isAdmin
        ? l10n.settings_deleteAccountSubtitle
        : l10n.settings_requestAccountDeletionSubtitle;

    return _buildCard(
      context,
      ListTile(
        contentPadding: _tilePadding(context),
        leading: _iconBadge(
          context: context,
          color: Colors.red,
          child: Icon(
            Icons.delete_forever,
            color: Colors.red,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
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
        onTap: () {
          if (isAdmin) {
            AccountDeletionHelper.showDeleteAccountDialog(context, authProvider);
          } else {
            AccountDeletionHelper.showDeletionRequestDialog(context);
          }
        },
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }




  Widget _buildLanguageCard() {
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.locale?.languageCode ?? 'en';
    final displayName = localeProvider.displayNameFor(currentCode);

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
          AppLocalizations.of(context).settings_languageLabel,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          displayName,
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
          AppLocalizations.of(context).settings_currencyLabel,
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
          AppLocalizations.of(context).settings_pushNotifications,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          AppLocalizations.of(context).settings_pushNotificationsSubtitle,
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
              AppLocalizations.of(context).settings_autoBackup,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_autoBackupSubtitle,
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
              AppLocalizations.of(context).settings_exportData,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_exportDataSubtitle,
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
              AppLocalizations.of(context).settings_importData,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_importDataSubtitle,
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
              AppLocalizations.of(context).settings_appVersion,
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
              AppLocalizations.of(context).settings_helpSupport,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_helpSupportSubtitle,
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
              AppLocalizations.of(context).settings_privacyPolicy,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_privacyPolicySubtitle,
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
              AppLocalizations.of(context).settings_termsOfService,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settings_termsOfServiceSubtitle,
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
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.locale?.languageCode ?? 'en';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.of(context).settings_selectLanguage,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(dialogContext).textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final code = locale.languageCode;
            final displayName = LocaleProvider.localeDisplayNames[code] ?? code;
            final isSelected = currentCode == code;
            return InkWell(
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(dialogContext);
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
                          color: Theme.of(dialogContext).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, color: AppTheme.secondaryColor, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
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
          AppLocalizations.of(context).settings_selectCurrency,
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
            Logger.debug('Could not open file: $e');
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
              AppConfig.appName,
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
              '© 2024 ${AppConfig.appName}. All rights reserved.',
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
