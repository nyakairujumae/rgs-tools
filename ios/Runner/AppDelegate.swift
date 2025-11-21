import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set notification delegate BEFORE requesting permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      // Request notification permissions with all necessary options
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Notification permission granted")
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          } else {
            print("❌ Notification permission denied: \(error?.localizedDescription ?? "unknown")")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - APNs Token Registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs token registered: \(tokenString)")
    
    // Pass token to Flutter Firebase Messaging plugin
    // The Flutter plugin will handle passing it to Firebase
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // MARK: - UNUserNotificationCenterDelegate Methods
  // Handle notification when app is in FOREGROUND
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📱 Notification received in foreground: \(userInfo)")
    
    // Show notification even when app is in foreground
    // This includes badge, sound, and banner/alert
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .badge, .sound]])
    } else {
      completionHandler([[.alert, .badge, .sound]])
    }
  }
  
  // Handle notification tap when app is in BACKGROUND or TERMINATED
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")
    
    // Handle notification tap - navigate to relevant screen
    // The Flutter side will handle this via onMessageOpenedApp
    
    completionHandler()
  }
}
