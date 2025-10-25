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
      return '🔐 Invalid email or password. Please check your credentials and try again.';
    }
    
    if (errorString.contains('user not found') ||
        errorString.contains('account not found') ||
        errorString.contains('email not found')) {
      return '👤 Account not found. Please check your email or sign up for a new account.';
    }
    
    if (errorString.contains('email not confirmed') ||
        errorString.contains('unconfirmed email') ||
        errorString.contains('verify your email')) {
      return '📧 Please check your email and verify your account before signing in.';
    }
    
    // Registration errors
    if (errorString.contains('email already registered') || 
        errorString.contains('user already exists') ||
        errorString.contains('email already exists') ||
        errorString.contains('already registered')) {
      return '📧 This email is already registered. Please sign in or use a different email.';
    }
    
    if (errorString.contains('invalid email') ||
        errorString.contains('email format') ||
        errorString.contains('malformed email')) {
      return '📧 Please enter a valid email address.';
    }
    
    if (errorString.contains('password') && errorString.contains('weak') ||
        errorString.contains('password too short') ||
        errorString.contains('password requirements')) {
      return '🔒 Password must be at least 8 characters long and include letters and numbers.';
    }
    
    // Rate limiting errors
    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit') ||
        errorString.contains('too many attempts') ||
        errorString.contains('try again later')) {
      return '⏰ Too many attempts. Please wait a few minutes before trying again.';
    }
    
    // Server errors
    if (errorString.contains('server error') ||
        errorString.contains('internal server error') ||
        errorString.contains('service unavailable') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return '🔧 Server is temporarily unavailable. Please try again in a few minutes.';
    }
    
    // Database errors
    if (errorString.contains('database error') ||
        errorString.contains('database connection') ||
        errorString.contains('postgres') ||
        errorString.contains('supabase')) {
      return '🗄️ Database connection issue. Please try again in a moment.';
    }
    
    // JWT and session errors
    if (errorString.contains('jwt') ||
        errorString.contains('token') ||
        errorString.contains('session') ||
        errorString.contains('expired')) {
      return '🔑 Session expired. Please sign in again.';
    }
    
    // Generic fallback
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
  
  /// Show error snackbar with appropriate styling
  static void showErrorSnackBar(BuildContext context, String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: getErrorColor(errorMessage),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
