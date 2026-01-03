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

  static Future<String?> readPersistedSession() async {
    if (kIsWeb) {
      return null;
    }

    final options = createPlatformAuthOptions(
      persistSessionKey: _buildPersistSessionKey(),
    );
    final storage = options.localStorage;
    if (storage == null) {
      return null;
    }
    await storage.initialize();
    return storage.accessToken();
  }

  static Future<void> clearPersistedSession() async {
    if (kIsWeb) {
      return;
    }

    final options = createPlatformAuthOptions(
      persistSessionKey: _buildPersistSessionKey(),
    );
    final storage = options.localStorage;
    if (storage == null) {
      return;
    }
    await storage.initialize();
    await storage.removePersistedSession();
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
