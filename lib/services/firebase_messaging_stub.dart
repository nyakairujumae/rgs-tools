// Lightweight stub used when building for web so the codebase can
// reference FirebaseMessaging APIs without pulling in the real plugin.

class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;
  final RemoteNotification? notification;

  RemoteMessage({
    this.messageId,
    Map<String, dynamic>? data,
    this.notification,
  }) : data = data ?? const {};
}

class RemoteNotification {
  final String? title;
  final String? body;

  RemoteNotification({this.title, this.body});
}

class FirebaseMessaging {
  static final FirebaseMessaging _instance = FirebaseMessaging._();
  
  FirebaseMessaging._();
  
  static FirebaseMessaging get instance => _instance;
  
  static void onBackgroundMessage(Future<void> Function(RemoteMessage) handler) {
    // No-op on web builds
  }
  
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return NotificationSettings();
  }
  
  Future<String?> getToken() async => null;
  
  Stream<String> get onTokenRefresh => const Stream.empty();
  
  Future<void> subscribeToTopic(String topic) async {}
  
  Future<void> unsubscribeFromTopic(String topic) async {}
  
  Future<RemoteMessage?> getInitialMessage() async => null;
  
  Stream<RemoteMessage> get onMessage => const Stream.empty();
  
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();
}

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  
  NotificationSettings({
    this.authorizationStatus = AuthorizationStatus.authorized,
  });
}

enum AuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  provisional,
}
