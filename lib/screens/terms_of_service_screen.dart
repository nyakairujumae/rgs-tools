import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                  'Terms of Service',
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
                  'Agreement to Terms',
                  'By accessing or using RGS Tools, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Use License',
                  'Permission is granted to use RGS Tools for internal business purposes. You may not:',
                  items: [
                    'Modify or copy the software',
                    'Use the software for any commercial purpose without permission',
                    'Attempt to reverse engineer or decompile the software',
                    'Remove any copyright or proprietary notations',
                  ],
                ),
                _buildSection(
                  context,
                  theme,
                  'User Accounts',
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Prohibited Uses',
                  'You may not use RGS Tools:',
                  items: [
                    'In any way that violates applicable laws or regulations',
                    'To transmit harmful, threatening, or abusive content',
                    'To interfere with or disrupt the service',
                    'To gain unauthorized access to any part of the service',
                  ],
                ),
                _buildSection(
                  context,
                  theme,
                  'Intellectual Property',
                  'The service and its original content, features, and functionality are owned by RGS Tools and are protected by international copyright, trademark, and other intellectual property laws.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Limitation of Liability',
                  'RGS Tools shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Termination',
                  'We reserve the right to terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms of Service.',
                ),
                _buildSection(
                  context,
                  theme,
                  'Changes to Terms',
                  'We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the app.',
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
                          'Questions about these terms? Contact us at support@rgstools.app',
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
