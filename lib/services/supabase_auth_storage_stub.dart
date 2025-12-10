import 'package:supabase_flutter/supabase_flutter.dart';

FlutterAuthClientOptions createPlatformAuthOptions({
  required String persistSessionKey,
}) {
  // Web already relies on browser storage, so no special handling required.
  return const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  );
}
