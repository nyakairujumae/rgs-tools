import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase config: .env (local) or --dart-define, else defaults so Codemagic builds work with no extra config.
class SupabaseConfig {
  static const String _defaultUrl = 'https://npgwikkvtxebzwtpzwgx.supabase.co';
  static const String _defaultAnonKey =
      'YOUR_NPGWIKKVTXEBZWTPZWGX_ANON_KEY_HERE';

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

  static const String authCallbackUrl = 'com.rgs.app://auth/callback';
}
