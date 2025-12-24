import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'supabase_auth_storage_io.dart'
    if (dart.library.html) 'supabase_auth_storage_stub.dart';

/// Builds [FlutterAuthClientOptions] instances that don't rely on
/// shared_preferences so Supabase can initialize even when that plugin fails.
class SupabaseAuthStorageFactory {
  static FlutterAuthClientOptions createAuthOptions() {
    if (kIsWeb) {
      return const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      );
    }

    final persistSessionKey = _buildPersistSessionKey();
    return createPlatformAuthOptions(persistSessionKey: persistSessionKey);
  }

  static String _buildPersistSessionKey() {
    try {
      final uri = Uri.parse(SupabaseConfig.url);
      final subdomain = uri.host.split('.').first;
      return 'sb-$subdomain-auth-token';
    } catch (_) {
      return 'sb-auth-token';
    }
  }
}
