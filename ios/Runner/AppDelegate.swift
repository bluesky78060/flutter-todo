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

    // DTA-4-5: 백그라운드 아이솔레이트는 새 FlutterEngine에서 뜨므로 플러그인이
    // 하나도 등록돼 있지 않다. workmanager_apple의 BackgroundWorker가 엔진 기동 직후
    // flutterPluginRegistrantCallback을 부르는데, 그 값은 이 호출로만 채워지고
    // 기본값은 nil이다. 빠뜨리면 백그라운드에서 첫 플러그인 호출(geolocator,
    // drift/sqlite3, supabase, flutter_local_notifications)이 MissingPluginException으로
    // 터지고 디스패처의 최상위 catch가 삼켜 조용히 실패한다.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // DTA-4-5: BGTaskScheduler는 앱이 실행을 마치기 **전에** 식별자를 등록해야 한다.
    // 이 호출이 없으면 Dart의 registerPeriodicTask()가 제출하는 시점에
    // BGTaskScheduler.submit이 BGTaskSchedulerErrorCodeNotPermitted로 throw하고,
    // 플러그인이 'Could not schedule BGAppRefreshTask ...' 로만 로그한다.
    // 식별자는 Info.plist의 BGTaskSchedulerPermittedIdentifiers 및
    // GeofenceWorkManagerService._geofenceTaskId와 정확히 일치해야 한다.
    //
    // 주의: iOS는 Dart가 넘긴 frequency와 inputData를 **무시한다**. 재스케줄 주기는
    // 아래 하드코딩 값 하나뿐이므로, BatteryOptimizationService의 배터리 적응형
    // 간격(15/30/60분)은 Android에서만 실제로 반영된다.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "geofence_check_unique_id",
      frequency: NSNumber(value: 15 * 60)  // = GeofenceWorkManagerService.startMonitoring 기본 intervalMinutes
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      // Setup deep link channel for OAuth callbacks
      deepLinkChannel = FlutterMethodChannel(
        name: "kr.bluesky.dodo/deeplink",
        binaryMessenger: controller.binaryMessenger
      )

      // Setup widget channel for WidgetKit refresh
      widgetChannel = FlutterMethodChannel(
        name: "kr.bluesky.dodo/widget",
        binaryMessenger: controller.binaryMessenger
      )
      widgetChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleWidgetMethodCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle widget-related method calls from Flutter
  private func handleWidgetMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "forceUpdateWidgets":
      if #available(iOS 14.0, *) {
        // Force UserDefaults synchronization before reload
        if let defaults = UserDefaults(suiteName: "group.kr.bluesky.dodo") {
          defaults.synchronize()
        }
        WidgetCenter.shared.reloadAllTimelines()
        result(true)
      } else {
        result(false)
      }

    case "reloadWidget":
      if #available(iOS 14.0, *) {
        if let kind = call.arguments as? String {
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

  // Handle URL Scheme deep links (OAuth callback)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("📱 AppDelegate: Received URL: \(url.absoluteString)")

    // Send to Flutter for Supabase OAuth handling
    deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)

    return super.application(app, open: url, options: options)
  }

  // Handle Universal Links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      print("📱 AppDelegate: Received Universal Link: \(url.absoluteString)")
      deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
