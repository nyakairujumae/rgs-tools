import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url {
    try {
      final envUrl = dotenv.env['SUPABASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    return const String.fromEnvironment('SUPABASE_URL');
  }

  static String get anonKey {
    try {
      final envKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (_) {}
    return const String.fromEnvironment('SUPABASE_ANON_KEY');
  }

  static const String authCallbackUrl = 'com.rgs.app://auth/callback';
}
