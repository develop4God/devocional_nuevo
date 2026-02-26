import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Method channel for deep link handling
  private let deepLinkChannel = "com.develop4god.devocional/deeplink"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up method channel for deep link handling
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: deepLinkChannel,
        binaryMessenger: controller.binaryMessenger
      )

      // Store the channel for later use
      self.methodChannel = channel
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle deep links when app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    handleDeepLink(url)
    return true
  }

  // Handle universal links (iOS 9+)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      handleDeepLink(url)
      return true
    }
    return false
  }

  // Handle deep link by sending to Flutter
  private func handleDeepLink(_ url: URL) {
    methodChannel?.invokeMethod("handleDeepLink", arguments: url.absoluteString)
  }

  // Store method channel reference
  private var methodChannel: FlutterMethodChannel?
}
