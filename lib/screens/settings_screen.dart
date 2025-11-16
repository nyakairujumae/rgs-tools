import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

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
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.white,
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
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
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
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 16,
                ),
        children: [
          // General Settings
          _buildSectionHeader('General'),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          _buildLanguageCard(),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          _buildCurrencyCard(),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

          // Notifications
          _buildSectionHeader('Notifications'),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          _buildNotificationCard(),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

          // Data & Backup
          _buildSectionHeader('Data & Backup'),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          _buildBackupCard(),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

          // About
          _buildSectionHeader('About'),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          _buildAboutCard(),
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
        title,
        style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
        fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }




  Widget _buildLanguageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        leading: Container(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          ),
          child: Icon(
            Icons.language,
            color: AppTheme.primaryColor,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        leading: Container(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          ),
          child: Text(
            'د.إ',
            style: TextStyle(
              color: AppTheme.primaryColor,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            secondary: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              child: Icon(
                Icons.backup,
                color: AppTheme.primaryColor,
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _exportData,
          ),
          Divider(
            height: 1, 
            indent: 16, 
            endIndent: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              child: Icon(
                Icons.info,
                color: AppTheme.primaryColor,
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
            leading: Container(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 10)),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
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
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
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
              Icon(Icons.check, color: AppTheme.primaryColor, size: 20),
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
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
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
              Icon(Icons.check, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
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

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & Support coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of Service coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

