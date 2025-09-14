import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get the Supabase client
  static SupabaseClient get client => _client;

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await _client.from('tools').select('count').limit(1);
      return true;
    } catch (e) {
      print('Supabase connection test failed: $e');
      return false;
    }
  }

  // Initialize database tables (we'll call this after creating tables in Supabase dashboard)
  static Future<void> initializeTables() async {
    // This method will be used to set up any initial data or configurations
    // after we create the tables in the Supabase dashboard
  }
}
