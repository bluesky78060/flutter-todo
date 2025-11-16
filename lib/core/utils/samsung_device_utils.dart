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