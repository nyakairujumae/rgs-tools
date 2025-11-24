import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../config/supabase_config.dart';
import 'supabase_auth_storage.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  // Get the Supabase client - ensures it's initialized
  static SupabaseClient get client {
    if (_client != null) {
      return _client!;
    }
    
    // Try to get from Supabase.instance
    try {
      _client = Supabase.instance.client;
      _initialized = true;
      return _client!;
    } catch (e) {
      print('⚠️ Supabase.instance not available, creating client directly...');
      // Create client directly as fallback (no session persistence)
      _client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
        authOptions: SupabaseAuthStorageFactory.createAuthOptions(),
      );
      _initialized = false; // Mark as not fully initialized
      print('✅ Supabase client created (limited functionality - no session persistence)');
      return _client!;
    }
  }
  
  // Check if Supabase is properly initialized
  static bool get isInitialized => _initialized;

  // Test connection with timeout and retry
  static Future<bool> testConnection({int retries = 3, Duration timeout = const Duration(seconds: 10)}) async {
    // Ensure client is initialized before testing
    final client = SupabaseService.client;
    
    for (int i = 0; i < retries; i++) {
      try {
        print('🔍 Testing Supabase connection (attempt ${i + 1}/$retries)...');
        await client
            .from('tools')
            .select('count')
            .limit(1)
            .timeout(timeout);
        print('✅ Supabase connection successful');
        return true;
      } catch (e) {
        print('❌ Supabase connection test failed (attempt ${i + 1}/$retries): $e');
        if (i < retries - 1) {
          print('⏳ Retrying in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          print('❌ All connection attempts failed');
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
        print('⚠️ Cannot connect to database. Please check your internet connection.');
      }
      return isConnected;
    } catch (e) {
      print('❌ Error checking connection: $e');
      return false;
    }
  }

  // Initialize database tables (we'll call this after creating tables in Supabase dashboard)
  static Future<void> initializeTables() async {
    // This method will be used to set up any initial data or configurations
    // after we create the tables in the Supabase dashboard
  }
}
