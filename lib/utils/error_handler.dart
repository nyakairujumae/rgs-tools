import 'package:flutter/material.dart';
import 'logger.dart';

/// Centralized error handling for the application
class ErrorHandler {
  /// Handle and display errors to the user
  static void handleError(BuildContext context, dynamic error, {StackTrace? stackTrace}) {
    Logger.error('Error occurred', error: error, stackTrace: stackTrace);
    
    String userMessage = _getUserFriendlyMessage(error);
    
    // Show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
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
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

