import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'auth_error_handler.dart';

class AccountDeletionHelper {
  static Future<void> showDeleteAccountDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'This will permanently delete your account and data. This action cannot be undone.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await authProvider.deleteAccount();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress
      }
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/role-selection', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Could not delete account. Please try again or contact support.',
        );
      }
    }
  }

  static Future<void> showDeletionRequestDialog(BuildContext context) async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'Account Deletion',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Technician accounts can only be deleted by your administrator. '
          'Please contact your admin to remove your account.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
