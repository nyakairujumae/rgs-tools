import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 28,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 24,
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: January 1st, 2026',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  theme,
                  'Overview',
                  'RGS Tools ("we", "our", "us") respects your privacy. This policy explains what data we collect, why we collect it, and how it is used.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Information We Collect',
                  null,
                  items: [
                    'Account details: name, email, role/position, department.',
                    'App usage data: actions inside the app (tools assigned, approvals, reports).',
                    'Device data: basic device identifiers used for authentication and notifications.',
                    'Images: photos of tools or technician profiles uploaded by admins.',
                  ],
                ),
                _buildSection(
                  context,
                  theme,
                  'How We Use Data',
                  null,
                  items: [
                    'To create and manage user accounts.',
                    'To manage tools, assignments, approvals, and reports.',
                    'To send notifications related to requests and approvals.',
                    'To improve app reliability and security.',
                  ],
                ),
                _buildSection(
                  context,
                  theme,
                  'Data Storage',
                  'Data is stored securely in Supabase infrastructure. Images are stored in secure storage buckets.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Data Sharing',
                  'We do not sell or rent your data. Data is only shared with service providers required to run the app (for example, Supabase and Firebase).',
                ),
                _buildSection(
                  context,
                  theme,
                  'User Rights',
                  'You can request access, correction, or deletion of your account data. You can request export of your data by contacting support.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Security',
                  'We apply standard security measures to protect your data, including authentication, access controls, and encrypted connections.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Children\'s Privacy',
                  'RGS Tools is not intended for children under 13.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Contact us at support@rgstools.app for privacy questions.',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            color: AppTheme.secondaryColor,
                          ),
                        ),
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

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    String title,
    String? content, {
    List<String>? items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
          if (items != null) ...[
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
