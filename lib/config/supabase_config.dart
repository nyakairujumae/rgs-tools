import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase config: .env (local) or --dart-define, else defaults so Codemagic builds work with no extra config.
class SupabaseConfig {
  static const String _defaultUrl = 'https://talzuhfantkxnwyahzyp.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhbHp1aGZhbnRreG53eWFoenlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDMzOTcsImV4cCI6MjA4NjIxOTM5N30.EYqpEjoe9PCirwGkynN6G8wq-U2LjrYYUg5CfrcfZqg';

  static String get url {
    try {
      final envUrl = dotenv.env['SUPABASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _defaultUrl;
  }

  static String get anonKey {
    try {
      final envKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (_) {}
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _defaultAnonKey;
  }

  static const String authCallbackUrl = 'com.tools.app://auth/callback';
}
