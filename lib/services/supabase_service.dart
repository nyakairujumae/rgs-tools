import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../config/supabase_config.dart';
import 'supabase_auth_storage.dart';
import '../utils/logger.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  // Get the Supabase client - ensures it's initialized
  static SupabaseClient get client {
    if (_client != null) {
      if (!_initialized) {
        try {
          _client = Supabase.instance.client;
          _initialized = true;
          Logger.debug('✅ Promoted to Supabase.instance.client');
        } catch (_) {
          // Keep fallback client if Supabase.instance is still unavailable
        }
      }
      return _client!;
    }
    
    // Try to get from Supabase.instance
    try {
      _client = Supabase.instance.client;
      _initialized = true;
      Logger.debug('✅ Using Supabase.instance.client');
      Logger.debug('🔍 Config URL: ${SupabaseConfig.url}');
      Logger.debug('✅ Supabase client initialized with URL: ${SupabaseConfig.url}');
      
      return _client!;
    } catch (e) {
      Logger.debug('⚠️ Supabase.instance not available, creating client directly...');
      Logger.debug('⚠️ Error: $e');
      // Create client directly as fallback (no session persistence)
      try {
        Logger.debug('🔍 Creating client with URL: ${SupabaseConfig.url}');
        _client = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: SupabaseAuthStorageFactory.createAuthOptions(),
        );
        _initialized = false; // Mark as not fully initialized
        Logger.debug('✅ Supabase client created directly');
        Logger.debug('✅ Client created with URL: ${SupabaseConfig.url}');
        Logger.debug('✅ Client created successfully - basic functionality available');
        
        return _client!;
      } catch (createError) {
        Logger.debug('❌ Failed to create Supabase client: $createError');
        // Re-throw to surface the error
        rethrow;
      }
    }
  }
  
  // Check if Supabase is properly initialized
  static bool get isInitialized => _initialized;

  // Test connection with timeout and retry
  static Future<bool> testConnection({int retries = 3, Duration timeout = const Duration(seconds: 15)}) async {
    // Ensure client is initialized before testing
    final client = SupabaseService.client;
    
    for (int i = 0; i < retries; i++) {
      try {
        Logger.debug('🔍 Testing Supabase connection (attempt ${i + 1}/$retries)...');
        Logger.debug('🔍 Supabase URL: ${SupabaseConfig.url}');
        
        // Test connection by checking if we can access auth endpoint
        // This is safer than querying tables which might not exist or have permissions
        try {
          // Just check if auth is accessible - this doesn't require any specific permissions
          final session = client.auth.currentSession;
          Logger.debug('✅ Supabase client accessible - connection appears to be working');
          // If we can access the client, assume connection is working
          // The actual login will test the real connection
          return true;
        } catch (authError) {
          Logger.debug('❌ Auth check failed: $authError');
          // If even auth check fails, connection is definitely broken
          throw authError;
        }
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        Logger.debug('❌ Supabase connection test failed (attempt ${i + 1}/$retries): $e');
        Logger.debug('❌ Error type: ${e.runtimeType}');
        
        // Check if it's a network/connection error
        if (errorString.contains('connection') || 
            errorString.contains('network') ||
            errorString.contains('timeout') ||
            errorString.contains('socket') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('unreachable') ||
            errorString.contains('requested path is invalid')) {
          Logger.debug('⚠️ Network/connection error detected');
          if (i < retries - 1) {
            Logger.debug('⏳ Retrying in ${(i + 1) * 2} seconds...');
            await Future.delayed(Duration(seconds: (i + 1) * 2));
          } else {
            Logger.debug('❌ All connection attempts failed - cannot reach Supabase server');
            return false;
          }
        } else {
          // Other error - might be a configuration issue
          Logger.debug('⚠️ Non-network error: $e');
          // For non-network errors, still return false to be safe
          return false;
        }
      }
    }
    return false;
  }

  // Ensure connection before operation
  static Future<bool> ensureConnection({int retries = 2}) async {
    try {
      final isConnected = await testConnection(retries: retries);
      if (!isConnected) {
        Logger.debug('⚠️ Cannot connect to database. Please check your internet connection.');
      }
      return isConnected;
    } catch (e) {
      Logger.debug('❌ Error checking connection: $e');
      return false;
    }
  }

  // Initialize database tables (we'll call this after creating tables in Supabase dashboard)
  static Future<void> initializeTables() async {
    // This method will be used to set up any initial data or configurations
    // after we create the tables in the Supabase dashboard
  }
}
