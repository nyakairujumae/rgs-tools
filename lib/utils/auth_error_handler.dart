import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility class for handling authentication errors and providing user-friendly messages
class AuthErrorHandler {
  
  /// Get user-friendly error message for authentication errors
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    String errorString = error.toString().toLowerCase();
    
    // Network and connectivity errors - be more specific
    // Only show connection error for actual network failures, not auth errors
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
      
      // Check for macOS permission error
      if (errorString.contains('operation not permitted') || errorString.contains('errno = 1')) {
        return '🔒 Network Permission Required\n\nThis app needs network access to connect to the database.\n\nOn macOS:\n1. Go to System Settings > Privacy & Security > Network\n2. Find this app and enable network access\n3. Restart the app';
      }
      
      return '🌐 Connection error: Please check your internet connection and try again.';
    }
    
    // Timeout errors - separate from connection errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return '⏱️ Request timed out. Please check your internet connection and try again.';
    }
    
    // Authentication errors
    if (errorString.contains('invalid login credentials') || 
        errorString.contains('invalid_credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('incorrect password')) {
      // Check if the error message indicates email exists
      if (errorString.contains('already registered') || 
          errorString.contains('email is already')) {
        return '📧 This email is already registered. Please check your password or use "Forgot Password" to reset it.';
      }
      return '🔐 Sorry, your email or password is incorrect. Please try again.';
    }
    
    if (errorString.contains('user not found') ||
        errorString.contains('account not found') ||
        errorString.contains('email not found')) {
      return '👤 Sorry, we couldn\'t find an account with this email. Please check your email or create a new account.';
    }
    
    if (errorString.contains('not available') ||
        errorString.contains('not registered') ||
        errorString.contains('please register first')) {
      return '📝 Your account is not available. Please register first by creating a new account.';
    }
    
    if (errorString.contains('email not confirmed') ||
        errorString.contains('unconfirmed email') ||
        errorString.contains('verify your email')) {
      return '📧 Please check your email and click the verification link before signing in.';
    }
    
    // Registration errors
    if (errorString.contains('email already registered') || 
        errorString.contains('user already exists') ||
        errorString.contains('email already exists') ||
        errorString.contains('already registered') ||
        errorString.contains('this email is already registered')) {
      return '📧 This email is already registered. Please sign in or use a different email address.';
    }
    
    if (errorString.contains('invalid email') ||
        errorString.contains('email format') ||
        errorString.contains('malformed email')) {
      return '📧 Please enter a valid email address.';
    }
    
    // Admin domain restrictions
    if (errorString.contains('invalid email domain for admin registration') ||
        errorString.contains('invalid admin credentials') ||
        errorString.contains('access denied')) {
      return '🚫 Sorry, your email cannot sign up as an admin. Please contact support if you believe this is an error.';
    }
    
    if (errorString.contains('password') && errorString.contains('weak') ||
        errorString.contains('password too short') ||
        errorString.contains('password requirements')) {
      return '🔒 Password must be at least 6 characters long.';
    }
    
    // Rate limiting errors
    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit') ||
        errorString.contains('too many attempts') ||
        errorString.contains('try again later')) {
      return '⏰ Too many attempts. Please wait a few minutes before trying again.';
    }
    
    // Email sending errors (when email confirmation is enabled but email service fails)
    if (errorString.contains('error sending confirmation email') ||
        errorString.contains('error sending email') ||
        (errorString.contains('confirmation email') && errorString.contains('error')) ||
        (errorString.contains('unexpected_failure') && errorString.contains('email'))) {
      // Check if this is for an admin (they need email confirmation)
      // For technicians, this shouldn't happen if the auto-confirm trigger is working
      return '📧 Email service error. For admins, email confirmation is required. Please check your email service configuration in Supabase.';
    }
    
    // Server errors - be more specific to avoid false positives
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
      return '🔧 Our servers are temporarily down. Please try again in a few minutes.';
    }
    
    // Database errors
    if (errorString.contains('database error') ||
        errorString.contains('database connection') ||
        errorString.contains('postgres') ||
        errorString.contains('supabase') ||
        errorString.contains('trouble connecting to our database')) {
      // Provide more helpful error message for desktop
      return '🗄️ Cannot connect to database. Please check:\n• Your internet connection\n• Firewall settings (may be blocking Supabase)\n• Try again in a moment';
    }
    
    // JWT and session errors
    if (errorString.contains('jwt') ||
        errorString.contains('token') ||
        errorString.contains('session') ||
        errorString.contains('expired')) {
      return '🔑 Your session has expired. Please sign in again.';
    }
    
    // Supabase-specific errors
    if (errorString.contains('duplicate key') ||
        errorString.contains('unique constraint') ||
        errorString.contains('already exists')) {
      return '📧 This email is already registered. Please sign in or use a different email address.';
    }
    
    if (errorString.contains('foreign key') ||
        errorString.contains('constraint') ||
        errorString.contains('violates')) {
      return '❌ Registration failed due to a data constraint. Please check your information and try again.';
    }
    
    if (errorString.contains('permission denied') ||
        errorString.contains('row-level security') ||
        errorString.contains('rls')) {
      return '🔒 Permission denied. Please contact support if this issue persists.';
    }
    
    // Generic fallback - but log the actual error for debugging
    debugPrint('⚠️ Unhandled error in AuthErrorHandler: $error');
    return '❌ Something went wrong. Please try again.';
  }
  
  /// Get error color based on error type
  static Color getErrorColor(String errorMessage) {
    if (errorMessage.contains('🌐') || errorMessage.contains('No internet')) {
      return Colors.orange; // Network issues
    } else if (errorMessage.contains('🔐') || errorMessage.contains('Invalid')) {
      return Colors.red; // Authentication issues
    } else if (errorMessage.contains('📧') || errorMessage.contains('email')) {
      return Colors.blue; // Email issues
    } else if (errorMessage.contains('⏰') || errorMessage.contains('Too many')) {
      return Colors.purple; // Rate limiting
    } else if (errorMessage.contains('🔧') || errorMessage.contains('Server')) {
      return Colors.red; // Server issues
    } else {
      return Colors.grey; // Generic errors
    }
  }
  
  /// Show error snackbar with appropriate styling - small, beautiful, and auto-dismissing
  static void showErrorSnackBar(BuildContext context, String errorMessage) {
    // First, hide any existing snackbars to prevent stacking
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.clearSnackBars(); // Clear all snackbars to prevent stacking
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: getErrorColor(errorMessage),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4), // Auto-dismiss after 4 seconds
        // Allow the snackbar to be dismissed with a simple horizontal swipe
        dismissDirection: DismissDirection.horizontal,
        elevation: 0,
      ),
    );
  }
  
  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
                maxLines: 2,
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
      ),
    );
  }
  
  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
                maxLines: 2,
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
      ),
    );
  }
}
