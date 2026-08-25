import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for Samsung device detection and optimization
class SamsungDeviceUtils {
  /// Check if the current device is a Samsung device
  static Future<bool> isSamsungDevice() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      // Use platform channel to get device info
      const platform = MethodChannel('kr.bluesky.dodo/device_info');
      final String manufacturer = await platform.invokeMethod('getManufacturer');

      if (kDebugMode) {
        print('📱 Device manufacturer: $manufacturer');
      }

      return manufacturer.toLowerCase() == 'samsung';
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not detect device manufacturer: $e');
      }
      // Fallback: check for Samsung-specific system properties
      return await _checkSamsungProperties();
    }
  }

  /// Fallback method to check for Samsung-specific properties
  static Future<bool> _checkSamsungProperties() async {
    try {
      // Try to detect Samsung through system properties
      const platform = MethodChannel('kr.bluesky.dodo/system_properties');
      final String brand = await platform.invokeMethod('getBrand');

      return brand.toLowerCase() == 'samsung';
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Fallback Samsung detection failed: $e');
      }
      return false;
    }
  }

  /// Get Samsung One UI version
  static Future<String?> getOneUIVersion() async {
    if (!await isSamsungDevice()) {
      return null;
    }

    try {
      const platform = MethodChannel('kr.bluesky.dodo/samsung_info');
      final String version = await platform.invokeMethod('getOneUIVersion');

      if (kDebugMode) {
        print('📱 One UI version: $version');
      }

      return version;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get One UI version: $e');
      }
      return null;
    }
  }

  /// Check if battery optimization is ignored (exempted)
  /// Returns true if the app is exempted from battery optimization
  static Future<bool> isIgnoringBatteryOptimizations() async {
    // DTA-4-5: Android 배터리 최적화 API다. 지금은 applySamsungWorkarounds() 뒤라
    // iOS에서 도달하지 않지만, 직접 호출되면 원래 버그와 같은 부류가 재발한다.
    // 반환값이 true인 이유: 이 술어는 "배터리 최적화에서 자유로운가"를 묻는다.
    // Android 외 플랫폼에는 그 제약 자체가 없으므로 답은 참이다. 저장소의 형제 구현
    // 둘(DeviceUtils, BatteryOptimizationService)도 같은 이유로 true를 돌려준다 —
    // 여기서만 false를 주면 호출자가 iOS 사용자에게 존재하지도 않는 Android 설정
    // 안내를 띄우게 된다. (shouldUseWorkManager()의 false는 "이 우회책을 쓰지 말라"는
    // 다른 질문에 대한 답이라 그대로 둔다.)
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      if (kDebugMode) {
        print('🔋 Battery optimization exempted: ${batteryStatus.isGranted}');
      }

      return batteryStatus.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to check battery optimization status: $e');
      }
      return false;
    }
  }

  /// Request battery optimization exemption for Samsung devices
  static Future<bool> requestBatteryOptimizationExemption() async {
    // DTA-4-5: Android 배터리 최적화 API다. 지금은 applySamsungWorkarounds() 뒤라
    // iOS에서 도달하지 않지만, 직접 호출되면 원래 버그와 같은 부류가 재발한다.
    // 반환값이 true인 이유: 이 술어는 "배터리 최적화에서 자유로운가"를 묻는다.
    // Android 외 플랫폼에는 그 제약 자체가 없으므로 답은 참이다. 저장소의 형제 구현
    // 둘(DeviceUtils, BatteryOptimizationService)도 같은 이유로 true를 돌려준다 —
    // 여기서만 false를 주면 호출자가 iOS 사용자에게 존재하지도 않는 Android 설정
    // 안내를 띄우게 된다. (shouldUseWorkManager()의 false는 "이 우회책을 쓰지 말라"는
    // 다른 질문에 대한 답이라 그대로 둔다.)
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      // Request ignore battery optimization permission
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      if (kDebugMode) {
        print('🔋 Battery optimization status: ${batteryStatus.name}');
      }

      if (!batteryStatus.isGranted) {
        final newStatus = await Permission.ignoreBatteryOptimizations.request();

        if (kDebugMode) {
          print('🔋 Battery optimization permission after request: ${newStatus.name}');
        }

        return newStatus.isGranted;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to request battery optimization exemption: $e');
      }
      return false;
    }
  }

  /// Open Samsung-specific notification settings
  static Future<bool> openSamsungNotificationSettings() async {
    try {
      // First try to open app-specific notification settings
      final opened = await openAppSettings();

      if (opened) {
        if (kDebugMode) {
          print('✅ Opened Samsung notification settings');
        }
      }

      return opened;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to open Samsung notification settings: $e');
      }
      return false;
    }
  }

  /// Check if app is in Samsung's sleeping apps list
  static Future<bool> isInSleepingApps() async {
    if (!await isSamsungDevice()) {
      return false;
    }

    try {
      const platform = MethodChannel('kr.bluesky.dodo/samsung_info');
      final bool isSleeping = await platform.invokeMethod('isInSleepingApps');

      if (kDebugMode) {
        print('😴 App in sleeping apps list: $isSleeping');
      }

      return isSleeping;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check sleeping apps status: $e');
      }
      return false;
    }
  }

  /// Apply Samsung-specific workarounds for notifications
  static Future<void> applySamsungWorkarounds() async {
    if (!await isSamsungDevice()) {
      if (kDebugMode) {
        print('📱 Not a Samsung device, skipping workarounds');
      }
      return;
    }

    if (kDebugMode) {
      print('🔧 Applying Samsung-specific workarounds...');
    }

    // 1. Request battery optimization exemption
    final batteryOptExempted = await requestBatteryOptimizationExemption();
    if (kDebugMode) {
      print('   Battery optimization exemption: ${batteryOptExempted ? '✅' : '❌'}');
    }

    // 2. Check if in sleeping apps
    final inSleepingApps = await isInSleepingApps();
    if (inSleepingApps) {
      if (kDebugMode) {
        print('   ⚠️ App is in sleeping apps list - user needs to remove it manually');
      }
    }

    // 3. Get One UI version for logging
    final oneUIVersion = await getOneUIVersion();
    if (oneUIVersion != null && kDebugMode) {
      print('   One UI version: $oneUIVersion');
    }

    if (kDebugMode) {
      print('✅ Samsung workarounds applied');
    }
  }

  /// Check if we should use WorkManager instead of AlarmManager
  static Future<bool> shouldUseWorkManager() async {
    // DTA-4-5: 이 함수 전체가 **Android 배터리 최적화 우회책**이다.
    // 가드가 없어서 iOS에서 다음이 벌어졌다:
    //   - isSamsungDevice()는 non-Android에서 false (그 함수엔 가드가 있다)
    //   - 그래서 아래 ignoreBatteryOptimizations 검사로 떨어지는데,
    //     그것은 **Android 전용 권한**이라 iOS에서는 절대 granted가 되지 않는다
    //   - 결국 `!isGranted`가 항상 참이 되어 **true를 반환**했다
    //   → iOS 알림이 표준 로컬 알림 대신 WorkManager 경로로 갔고,
    //     Workmanager가 초기화되지 않은 상태에서 registerOneOffTask가 던진
    //     PlatformException이 할일 저장 화면의 빨간 SnackBar로 노출됐다.
    // isSamsungDevice()와 같은 가드를 둔다.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    // Use WorkManager for all Samsung devices
    final isSamsung = await isSamsungDevice();

    if (isSamsung) {
      if (kDebugMode) {
        print('📱 Samsung device detected - using WorkManager for notifications');
      }
      return true;
    }

    // Also use WorkManager if battery optimization is enabled
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        if (kDebugMode) {
          print('🔋 Battery optimization enabled - using WorkManager');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check battery optimization: $e');
      }
    }

    return false;
  }

  /// Check if device is a foldable device (Galaxy Fold/Flip)
  static Future<bool> isFoldableDevice() async {
    if (!await isSamsungDevice()) {
      return false;
    }

    try {
      const platform = MethodChannel('kr.bluesky.dodo/device_info');
      final String model = await platform.invokeMethod('getModel');

      if (kDebugMode) {
        print('📱 Device model: $model');
      }

      // Detect Fold/Flip models
      final modelLower = model.toLowerCase();
      final isFoldable = modelLower.contains('fold') || modelLower.contains('flip');

      if (kDebugMode && isFoldable) {
        print('📱 Foldable device detected: $model');
      }

      return isFoldable;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check foldable device: $e');
      }
      return false;
    }
  }

  /// Get device model name
  static Future<String?> getDeviceModel() async {
    try {
      const platform = MethodChannel('kr.bluesky.dodo/device_info');
      final String model = await platform.invokeMethod('getModel');
      return model;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get device model: $e');
      }
      return null;
    }
  }
}