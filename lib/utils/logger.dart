import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Provides different log levels and structured logging
class Logger {
  static const String _tag = 'RGS_TOOLS';
  
  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log info messages
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('WARNING', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log fatal/critical messages
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('FATAL', message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Internal logging method
  static void _log(String level, String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag != null ? '$_tag.$tag' : _tag;
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';
    
    if (error != null) {
      developer.log(
        logMessage,
        name: logTag,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      developer.log(logMessage, name: logTag);
    }
    
    // In production, you might want to send logs to a remote service
    if (kReleaseMode) {
      _sendToRemoteService(level, message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Send logs to remote service (implement based on your needs)
  static void _sendToRemoteService(String level, String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // TODO: Implement remote logging service (e.g., Firebase Crashlytics, Sentry, etc.)
    // This is where you would send critical logs to your monitoring service
  }
}

/// Logging mixin for easy logging in classes
mixin LoggingMixin {
  void logDebug(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.debug(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logInfo(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.info(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.warning(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
  
  void logFatal(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.fatal(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
}

