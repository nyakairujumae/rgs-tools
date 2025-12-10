import Flutter
import UIKit
import UserNotifications
import shared_preferences_foundation
import sqflite_darwin
import image_picker_ios

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase initialization is handled by Flutter in main.dart
    // Do NOT call FirebaseApp.configure() here - let Flutter handle it completely

    GeneratedPluginRegistrant.register(with: self)

    // Note: connectivity_plus is Swift-only and is automatically registered by GeneratedPluginRegistrant
    // No manual registration needed

    // Manual plugin registration (your custom fixes)
    if let sharedPrefsRegistrar = self.registrar(forPlugin: "SharedPreferencesPlugin") {
      SharedPreferencesPlugin.register(with: sharedPrefsRegistrar)
    }
    if let sqfliteRegistrar = self.registrar(forPlugin: "SqflitePlugin") {
      SqflitePlugin.register(with: sqfliteRegistrar)
    }
    if let imagePickerRegistrar = self.registrar(forPlugin: "FLTImagePickerPlugin") {
      FLTImagePickerPlugin.register(with: imagePickerRegistrar)
    }

    // Notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
      ) { granted, error in
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }


  // MARK: - Registering APNs Token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    // Print token for debugging
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs token registered: \(tokenString)")

    // FirebaseMessaging plugin automatically handles APNs tokens (via method swizzling)
    print("ℹ️ FirebaseMessaging plugin will handle the APNs token")

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }


  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }


  // MARK: - iOS Foreground Notification
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                willPresent notification: UNNotification,
                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

    let userInfo = notification.request.content.userInfo
    print("📱 Notification received in foreground: \(userInfo)")

    completionHandler([.banner, .sound, .badge])
  }


  // MARK: - Notification Tap
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler: @escaping () -> Void) {

    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")

    completionHandler()
  }
}

