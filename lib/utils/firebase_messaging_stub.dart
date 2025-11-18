// Stub for Firebase Messaging on web
class FirebaseMessaging {
  static void onBackgroundMessage(Future<void> Function(RemoteMessage) handler) {
    // No-op on web
  }
}

// Stub for RemoteMessage on web
class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;
  
  RemoteMessage({this.messageId, Map<String, dynamic>? data}) : data = data ?? {};
}

