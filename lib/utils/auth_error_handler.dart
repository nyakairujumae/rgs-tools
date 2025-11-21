import 'package:flutter/material.dart';

/// Utility class for handling authentication errors and providing user-friendly messages
class AuthErrorHandler {
  
  /// Get user-friendly error message for authentication errors
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    String errorString = error.toString().toLowerCase();
    
    // Network and connectivity errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable') ||
        errorString.contains('no internet') ||
        errorString.contains('network error')) {
      return '🌐 No internet connection. Please check your network and try again.';
    }
    
    // Authentication errors
    if (errorString.contains('invalid login credentials') || 
        errorString.contains('invalid_credentials') ||
        errorString.contains('wrong password') ||
        errorString.contains('incorrect password')) {
      return '🔐 Sorry, your email or password is incorrect. Please try again.';
    }
    
    if (errorString.contains('user not found') ||
        errorString.contains('account not found') ||
        errorString.contains('email not found')) {
      return '👤 Sorry, we couldn\'t find an account with this email. Please check your email or create a new account.';
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
        errorString.contains('already registered')) {
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
        errorString.contains('supabase')) {
      return '🗄️ We\'re having trouble connecting to our database. Please try again in a moment.';
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
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
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3), // Shorter duration - auto-dismiss after 3 seconds
        dismissDirection: DismissDirection.horizontal, // Allow swipe to dismiss
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF047857), // AppTheme.secondaryColor
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        duration: const Duration(seconds: 2), // Shorter duration
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
  
  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
