import Flutter
import UIKit
import Firebase
import FirebaseCore
import FirebaseMessaging
import PushKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    requestPushNotificationPermission(application)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Request Push Notification permission
  func requestPushNotificationPermission(_ application: UIApplication) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
          if granted {
              DispatchQueue.main.async {
                  application.registerForRemoteNotifications()
              }
          } else {
              // Handle error or denied permission
          }
      }
  }
  // Implement the required delegate methods here
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
      // Handle the push credentials (e.g., token registration)
  }
  
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
      // Handle incoming VoIP push notification
  }
}