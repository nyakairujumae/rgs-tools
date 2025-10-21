import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
        leading: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Text(
            'د.إ',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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

