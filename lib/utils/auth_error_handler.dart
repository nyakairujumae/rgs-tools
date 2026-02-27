import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'logger.dart';

/// Utility class for handling authentication errors and providing user-friendly messages
class AuthErrorHandler {
  
  /// Get user-friendly error message for authentication errors
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    String errorString = error.toString().toLowerCase();
    
    // Network and connectivity errors (not auth failures)
    if ((errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable') ||
        errorString.contains('no internet') ||
        errorString.contains('network error') ||
        errorString.contains('cannot connect to database') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('socket exception')) &&
        !errorString.contains('invalid') &&
        !errorString.contains('credentials') &&
        !errorString.contains('password')) {
      if (errorString.contains('operation not permitted') || errorString.contains('errno = 1')) {
        return 'Network access is required. On macOS: System Settings > Privacy & Security > Network, enable this app, then restart.';
      }
      return 'Connection problem. Check your internet and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Check your connection and try again.';
    }
    
    // Authentication errors (login)
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('incorrect password')) {
      return 'Incorrect email or password. Please try again or use Forgot Password to reset.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('account not found') ||
        errorString.contains('email not found')) {
      return 'No account found with this email. Check the address or create an account.';
    }

    if (errorString.contains('not available') ||
        errorString.contains('not registered') ||
        errorString.contains('please register first')) {
      return 'You need to create an account first. Please register to continue.';
    }

    if (errorString.contains('email not confirmed') ||
        errorString.contains('unconfirmed email') ||
        errorString.contains('verify your email')) {
      return 'Please verify your email using the link we sent you, then sign in again.';
    }

    // Registration errors
    if (errorString.contains('email already registered') ||
        errorString.contains('user already exists') ||
        errorString.contains('email already exists') ||
        errorString.contains('already registered') ||
        errorString.contains('this email is already registered')) {
      return 'This email is already registered. Sign in with it or use a different email.';
    }
    
    if (errorString.contains('invalid email') ||
        errorString.contains('email format') ||
        errorString.contains('malformed email')) {
      return 'Please enter a valid email address.';
    }

    // Admin domain restrictions
    if (errorString.contains('invalid email domain for admin registration') ||
        errorString.contains('invalid admin credentials') ||
        errorString.contains('access denied')) {
      return 'This email cannot be used for admin sign-up. Contact support if you think this is wrong.';
    }

    if (errorString.contains('password') && errorString.contains('weak') ||
        errorString.contains('password too short') ||
        errorString.contains('password requirements')) {
      return 'Password must be at least 6 characters.';
    }

    // Rate limiting errors
    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit') ||
        errorString.contains('too many attempts') ||
        errorString.contains('try again later')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    
    // Email sending errors
    if (errorString.contains('error sending confirmation email') ||
        errorString.contains('error sending email') ||
        (errorString.contains('confirmation email') && errorString.contains('error')) ||
        (errorString.contains('unexpected_failure') && errorString.contains('email'))) {
      return 'We couldn\'t send the email. Try again later or contact support.';
    }

    // Server errors
    if (errorString.contains('server error') ||
        errorString.contains('internal server error') ||
        errorString.contains('service unavailable') ||
        errorString.contains('http 500') ||
        errorString.contains('http 502') ||
        errorString.contains('http 503') ||
        errorString.contains('status code: 500') ||
        errorString.contains('status code: 502') ||
        errorString.contains('status code: 503') ||
        (errorString.contains('500') && (errorString.contains('internal') || errorString.contains('server'))) ||
        (errorString.contains('502') && (errorString.contains('bad gateway') || errorString.contains('server'))) ||
        (errorString.contains('503') && (errorString.contains('service') || errorString.contains('unavailable')))) {
      return 'Servers are temporarily unavailable. Try again in a few minutes.';
    }

    // Database errors
    if (errorString.contains('database error') ||
        errorString.contains('database connection') ||
        errorString.contains('postgres') ||
        errorString.contains('supabase') ||
        errorString.contains('trouble connecting to our database')) {
      return 'Cannot connect to the server. Check your internet and firewall, then try again.';
    }

    // JWT and session errors
    if (errorString.contains('jwt') ||
        errorString.contains('token') ||
        errorString.contains('session') ||
        errorString.contains('expired')) {
      return 'Your session expired. Please sign in again.';
    }

    // Supabase-specific errors
    if (errorString.contains('duplicate key') ||
        errorString.contains('unique constraint') ||
        errorString.contains('already exists')) {
      return 'This email is already registered. Sign in or use a different email.';
    }

    if (errorString.contains('foreign key') ||
        errorString.contains('constraint') ||
        errorString.contains('violates')) {
      return 'Registration failed. Check your details and try again.';
    }

    if (errorString.contains('permission denied') ||
        errorString.contains('row-level security') ||
        errorString.contains('rls')) {
      return 'Permission denied. Contact support if it keeps happening.';
    }

    Logger.debug('⚠️ Unhandled error in AuthErrorHandler: $error');
    return 'Something went wrong. Please try again.';
  }

  /// Get error color based on error type (keyword-based; messages no longer use emoji)
  static Color getErrorColor(String errorMessage) {
    final lower = errorMessage.toLowerCase();
    if (lower.contains('connection') || lower.contains('internet') || lower.contains('network')) {
      return Colors.orange;
    }
    if (lower.contains('incorrect') || lower.contains('password') || lower.contains('invalid')) {
      return Colors.red;
    }
    if (lower.contains('email') || lower.contains('registered')) {
      return Colors.blue;
    }
    if (lower.contains('too many') || lower.contains('wait')) {
      return Colors.purple;
    }
    if (lower.contains('server') || lower.contains('unavailable')) {
      return Colors.red;
    }
    return Colors.grey;
  }
  
  /// Show error snackbar with appropriate styling - small, beautiful, and auto-dismissing.
  /// Schedules show in the next frame so it appears reliably (e.g. after async or navigation).
  static void showErrorSnackBar(BuildContext context, String errorMessage) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final color = getErrorColor(errorMessage);
    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      elevation: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.maybeOf(context);
      if (m == null) return;
      m.hideCurrentSnackBar();
      m.showSnackBar(snackBar);
    });
  }
  
  /// Show success snackbar. Schedules show in the next frame so it appears reliably.
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final snackBar = SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.secondaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      elevation: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.maybeOf(context);
      if (m == null) return;
      m.hideCurrentSnackBar();
      m.showSnackBar(snackBar);
    });
  }
  
  /// Show info snackbar. Schedules show in the next frame so it appears reliably.
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      elevation: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final m = ScaffoldMessenger.maybeOf(context);
      if (m == null) return;
      m.hideCurrentSnackBar();
      m.showSnackBar(snackBar);
    });
  }
}
