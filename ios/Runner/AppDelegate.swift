import Flutter
import UIKit
import WidgetKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var deepLinkChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // DTA-4-5: BGTaskScheduler는 앱이 실행을 마치기 **전에** 식별자를 등록해야 한다.
    // 이 호출이 없으면 Dart의 Workmanager().registerPeriodicTask()가 스케줄을 제출해도
    // 실행할 핸들러가 없어 주기 작업이 조용히 돌지 않는다.
    // 식별자는 Info.plist의 BGTaskSchedulerPermittedIdentifiers 및
    // GeofenceWorkManagerService._geofenceTaskId와 정확히 일치해야 한다.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "geofence_check_unique_id",
      frequency: NSNumber(value: 15 * 60)
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      // Setup deep link channel for OAuth callbacks
      deepLinkChannel = FlutterMethodChannel(
        name: "kr.bluesky.dodo/deeplink",
        binaryMessenger: controller.binaryMessenger
      )
      print("🔗 AppDelegate: Deep link channel initialized")

      // Setup widget channel for WidgetKit refresh
      widgetChannel = FlutterMethodChannel(
        name: "kr.bluesky.dodo/widget",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleWidgetMethodCall(call, result: result)
      }
      print("📱 AppDelegate: Widget channel initialized")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle widget-related method calls from Flutter
  private func handleWidgetMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("📱 AppDelegate: Widget method called: \(call.method)")

    switch call.method {
    case "forceUpdateWidgets":
      // Reload all widget timelines to pick up new data
      if #available(iOS 14.0, *) {
        print("📱 AppDelegate: Reloading all widget timelines...")

        // Force UserDefaults synchronization before reload
        if let defaults = UserDefaults(suiteName: "group.kr.bluesky.dodo") {
          defaults.synchronize()
          print("📱 AppDelegate: UserDefaults synchronized")
        }

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        print("📱 AppDelegate: All widget timelines reloaded")
        result(true)
      } else {
        print("📱 AppDelegate: WidgetKit not available (iOS < 14)")
        result(false)
      }

    case "reloadWidget":
      // Reload specific widget by kind
      if #available(iOS 14.0, *) {
        if let kind = call.arguments as? String {
          print("📱 AppDelegate: Reloading widget: \(kind)")
          WidgetCenter.shared.reloadTimelines(ofKind: kind)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Widget kind required", details: nil))
        }
      } else {
        result(false)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Handle deep links for Supabase OAuth (custom URL scheme)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 AppDelegate: Received URL: \(url.absoluteString)")

    // Forward URL to Flutter for OAuth handling
    if url.scheme == "kr.bluesky.dodo" {
      deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      print("🔗 AppDelegate: Forwarded URL to Flutter channel")
    }

    return super.application(app, open: url, options: options)
  }

  // Handle universal links for Supabase OAuth
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      print("🔗 AppDelegate: Received Universal Link: \(url.absoluteString)")
      deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
