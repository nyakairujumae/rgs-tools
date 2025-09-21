import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackup = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildThemeCard(),
          SizedBox(height: 24),

          // General Settings
          _buildSectionHeader('General'),
          _buildLanguageCard(),
          _buildCurrencyCard(),
          SizedBox(height: 24),

          // Notifications
          _buildSectionHeader('Notifications'),
          _buildNotificationCard(),
          SizedBox(height: 24),

          // Data & Backup
          _buildSectionHeader('Data & Backup'),
          _buildBackupCard(),
          SizedBox(height: 24),

          // About
          _buildSectionHeader('About'),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(themeProvider.themeIcon, color: themeProvider.themeColor),
                    SizedBox(width: 12),
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      themeProvider.themeModeDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.themeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  themeProvider.themeModeDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                _buildThemeModeSelector(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeSelector(ThemeProvider themeProvider) {
    return Column(
      children: ThemeMode.values.map((mode) {
        final isSelected = themeProvider.themeMode == mode;
        String title;
        String subtitle;
        IconData icon;
        Color color;

        switch (mode) {
          case ThemeMode.light:
            title = 'Light';
            subtitle = 'Always use light theme';
            icon = Icons.light_mode;
            color = Colors.orange;
            break;
          case ThemeMode.dark:
            title = 'Dark';
            subtitle = 'Always use dark theme';
            icon = Icons.dark_mode;
            color = Colors.blue;
            break;
          case ThemeMode.system:
            title = 'System';
            subtitle = 'Follow system setting';
            icon = Icons.brightness_auto;
            color = Colors.purple;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => themeProvider.setThemeMode(mode),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? color.withValues(alpha: 0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? color : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? color.withValues(alpha: 0.8) : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: color,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildLanguageCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.language, color: AppTheme.primaryColor),
        title: Text('Language'),
        subtitle: Text(_selectedLanguage),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showLanguageDialog,
      ),
    );
  }

  Widget _buildCurrencyCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.attach_money, color: AppTheme.primaryColor),
        title: Text('Currency'),
        subtitle: Text(_selectedCurrency),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _showCurrencyDialog,
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      child: SwitchListTile(
        secondary: Icon(Icons.notifications, color: AppTheme.primaryColor),
        title: Text('Push Notifications'),
        subtitle: Text('Receive maintenance reminders and updates'),
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
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.backup, color: AppTheme.primaryColor),
            title: Text('Auto Backup'),
            subtitle: Text('Automatically backup data to cloud'),
            value: _autoBackup,
            onChanged: (value) {
              setState(() {
                _autoBackup = value;
              });
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.download, color: AppTheme.primaryColor),
            title: Text('Export Data'),
            subtitle: Text('Download your data as CSV'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _exportData,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.upload, color: AppTheme.primaryColor),
            title: Text('Import Data'),
            subtitle: Text('Restore from backup file'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info, color: AppTheme.primaryColor),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showVersionInfo,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.help, color: AppTheme.primaryColor),
            title: Text('Help & Support'),
            subtitle: Text('Get help and contact support'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showHelp,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            title: Text('Privacy Policy'),
            subtitle: Text('Read our privacy policy'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPrivacyPolicy,
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.description, color: AppTheme.primaryColor),
            title: Text('Terms of Service'),
            subtitle: Text('Read our terms of service'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
        title: Text('Select Language'),
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
    return ListTile(
      title: Text(displayName),
      trailing: _selectedLanguage == value ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Currency'),
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
    return ListTile(
      title: Text(code),
      subtitle: Text(name),
      trailing: _selectedCurrency == code ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _selectedCurrency = code;
        });
        Navigator.pop(context);
      },
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
            Text('RGS Tools Manager'),
            Text('Version: 1.0.0'),
            Text('Build: 2024.01.15'),
            SizedBox(height: 16),
            Text('© 2024 RGS Tools. All rights reserved.'),
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

