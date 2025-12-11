import 'package:flutter/material.dart';
import 'logger.dart';

/// Centralized error handling for the application
class ErrorHandler {
  /// Handle and display errors to the user
  static void handleError(BuildContext context, dynamic error, {StackTrace? stackTrace}) {
    Logger.error('Error occurred', error: error, stackTrace: stackTrace);
    
    String userMessage = _getUserFriendlyMessage(error);
    
    // Show error snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userMessage,
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
        backgroundColor: Colors.red,
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
  
  /// Show error dialog for critical errors
  static void showErrorDialog(BuildContext context, dynamic error, {StackTrace? stackTrace}) {
    Logger.error('Critical error occurred', error: error, stackTrace: stackTrace);
    
    String userMessage = _getUserFriendlyMessage(error);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Error',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          userMessage,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get user-friendly error message
  static String _getUserFriendlyMessage(dynamic error) {
    if (error is String) {
      return error;
    }
    
    final errorString = error.toString().toLowerCase();
    
    // Database errors
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return 'A database error occurred. Please try again.';
    }
    
    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    
    // Validation errors
    if (errorString.contains('validation') || errorString.contains('required')) {
      return 'Please check your input and try again.';
    }
    
    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    }
    
    // File system errors
    if (errorString.contains('file') || errorString.contains('directory')) {
      return 'File system error. Please try again.';
    }
    
    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Handle async operations with error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showError = true,
    BuildContext? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      Logger.error(
        errorMessage ?? 'Async operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      
      if (showError && context != null) {
        handleError(context, error, stackTrace: stackTrace);
      }
      
      return null;
    }
  }
}

/// Error handling mixin for widgets
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handle errors with automatic UI feedback
  void handleError(dynamic error, {StackTrace? stackTrace, bool showDialog = false}) {
    if (showDialog) {
      ErrorHandler.showErrorDialog(context, error, stackTrace: stackTrace);
    } else {
      ErrorHandler.handleError(context, error, stackTrace: stackTrace);
    }
  }
  
  /// Execute async operation with error handling
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showDialog = false,
  }) async {
    return await ErrorHandler.handleAsync(
      operation,
      errorMessage: errorMessage,
      showError: true,
      context: context,
    );
  }
}

