// Lightweight stub used when building for web so the codebase can
// reference FirebaseMessaging APIs without pulling in the real plugin.

typedef RemoteMessageHandler = Future<void> Function(RemoteMessage message);

class FirebaseMessaging {
  static void onBackgroundMessage(RemoteMessageHandler handler) {
    // No-op on web builds
  }
}

class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;

  RemoteMessage({
    this.messageId,
    Map<String, dynamic>? data,
  }) : data = data ?? const {};
}
