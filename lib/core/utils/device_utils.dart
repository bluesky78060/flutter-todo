/// Utility class for device detection and information retrieval.
///
/// Provides device information for all platforms (Android, iOS, Web, etc.)
/// using the device_info_plus package.
library;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Data class to hold device information
class DeviceInfo {
  final String manufacturer;
  final String model;
  final String osVersion;
  final String? sdkVersion;
  final bool isPhysicalDevice;
  final String deviceType;
  final String? brand;
  final String? device;
  final String? product;
  final String? hardware;
  final String? fingerprint;
  final String? host;
  final String? bootloader;
  final int? displayWidth;
  final int? displayHeight;

  const DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.osVersion,
    this.sdkVersion,
    required this.isPhysicalDevice,
    required this.deviceType,
    this.brand,
    this.device,
    this.product,
    this.hardware,
    this.fingerprint,
    this.host,
    this.bootloader,
    this.displayWidth,
    this.displayHeight,
  });

  /// Returns a formatted display string for the device
  String get displayName => '$manufacturer $model';

  /// Returns OS info string
  String get osInfo => sdkVersion != null
      ? '$osVersion (SDK $sdkVersion)'
      : osVersion;

  /// Returns display resolution string
  String? get displayResolution => (displayWidth != null && displayHeight != null)
      ? '${displayWidth}x$displayHeight'
      : null;
}

/// Utility class for device detection and optimization
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static DeviceInfo? _cachedDeviceInfo;

  /// Get comprehensive device information
  static Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      _cachedDeviceInfo = DeviceInfo(
        manufacturer: webInfo.browserName.name,
        model: webInfo.platform ?? 'Web Browser',
        osVersion: webInfo.userAgent ?? 'Unknown',
        isPhysicalDevice: true,
        deviceType: 'Web',
      );
      return _cachedDeviceInfo!;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedDeviceInfo = DeviceInfo(
          manufacturer: androidInfo.manufacturer,
          model: androidInfo.model,
          osVersion: 'Android ${androidInfo.version.release}',
          sdkVersion: androidInfo.version.sdkInt.toString(),
          isPhysicalDevice: androidInfo.isPhysicalDevice,
          deviceType: 'Android',
          brand: androidInfo.brand,
          device: androidInfo.device,
          product: androidInfo.product,
          hardware: androidInfo.hardware,
          fingerprint: androidInfo.fingerprint,
          host: androidInfo.host,
          bootloader: androidInfo.bootloader,
        );
        break;

      case TargetPlatform.iOS:
        final iosInfo = await _deviceInfo.iosInfo;
        _cachedDeviceInfo = DeviceInfo(
          manufacturer: 'Apple',
          model: iosInfo.model,
          osVersion: 'iOS ${iosInfo.systemVersion}',
          isPhysicalDevice: iosInfo.isPhysicalDevice,
          deviceType: 'iOS',
        );
        break;

      case TargetPlatform.macOS:
        final macInfo = await _deviceInfo.macOsInfo;
        _cachedDeviceInfo = DeviceInfo(
          manufacturer: 'Apple',
          model: macInfo.model,
          osVersion: 'macOS ${macInfo.osRelease}',
          isPhysicalDevice: true,
          deviceType: 'macOS',
        );
        break;

      case TargetPlatform.windows:
        final windowsInfo = await _deviceInfo.windowsInfo;
        _cachedDeviceInfo = DeviceInfo(
          manufacturer: 'Microsoft',
          model: windowsInfo.productName,
          osVersion: 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          sdkVersion: windowsInfo.buildNumber.toString(),
          isPhysicalDevice: true,
          deviceType: 'Windows',
        );
        break;

      case TargetPlatform.linux:
        final linuxInfo = await _deviceInfo.linuxInfo;
        _cachedDeviceInfo = DeviceInfo(
          manufacturer: linuxInfo.prettyName,
          model: linuxInfo.name,
          osVersion: linuxInfo.version ?? 'Unknown',
          isPhysicalDevice: true,
          deviceType: 'Linux',
        );
        break;

      default:
        _cachedDeviceInfo = const DeviceInfo(
          manufacturer: 'Unknown',
          model: 'Unknown',
          osVersion: 'Unknown',
          isPhysicalDevice: true,
          deviceType: 'Unknown',
        );
    }

    if (kDebugMode) {
      print('📱 Device Info: ${_cachedDeviceInfo!.displayName}');
      print('📱 OS: ${_cachedDeviceInfo!.osInfo}');
    }

    return _cachedDeviceInfo!;
  }

  /// Clear cached device info (for testing or refresh)
  static void clearCache() {
    _cachedDeviceInfo = null;
  }

  /// Check if device is Android
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Check if device is iOS
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Check if the current device is a Samsung device
  static Future<bool> isSamsungDevice() async {
    if (!isAndroid) return false;

    final info = await getDeviceInfo();
    return info.manufacturer.toLowerCase() == 'samsung';
  }

  /// Get device manufacturer
  static Future<String> getManufacturer() async {
    final info = await getDeviceInfo();
    return info.manufacturer;
  }

  /// Get device model
  static Future<String> getModel() async {
    final info = await getDeviceInfo();
    return info.model;
  }

  /// Check if battery optimization is ignored (exempted)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isAndroid) return true;

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

  /// Request battery optimization exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!isAndroid) return true;

    try {
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

  /// Check if device is a foldable (Samsung Fold/Flip, etc.)
  static Future<bool> isFoldableDevice() async {
    if (!isAndroid) return false;

    final info = await getDeviceInfo();
    final modelLower = info.model.toLowerCase();

    // Check for known foldable patterns
    final isFoldable = modelLower.contains('fold') ||
                       modelLower.contains('flip') ||
                       modelLower.contains('z fold') ||
                       modelLower.contains('z flip');

    if (kDebugMode && isFoldable) {
      print('📱 Foldable device detected: ${info.model}');
    }

    return isFoldable;
  }

  /// Check if we should use WorkManager for notifications
  /// (for devices with aggressive battery optimization)
  static Future<bool> shouldUseWorkManager() async {
    if (!isAndroid) return false;

    final info = await getDeviceInfo();
    final manufacturer = info.manufacturer.toLowerCase();

    // List of manufacturers known for aggressive battery optimization
    const aggressiveManufacturers = [
      'samsung',
      'huawei',
      'xiaomi',
      'oppo',
      'vivo',
      'oneplus',
      'realme',
    ];

    if (aggressiveManufacturers.contains(manufacturer)) {
      if (kDebugMode) {
        print('📱 ${info.manufacturer} device detected - using WorkManager for notifications');
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

  /// Apply device-specific workarounds
  static Future<void> applyDeviceWorkarounds() async {
    if (!isAndroid) {
      if (kDebugMode) {
        print('📱 Not an Android device, skipping workarounds');
      }
      return;
    }

    final info = await getDeviceInfo();

    if (kDebugMode) {
      print('🔧 Applying device-specific workarounds for ${info.displayName}...');
    }

    // 1. Request battery optimization exemption
    final batteryOptExempted = await requestBatteryOptimizationExemption();
    if (kDebugMode) {
      print('   Battery optimization exemption: ${batteryOptExempted ? '✅' : '❌'}');
    }

    // 2. Check for foldable device
    final isFoldable = await isFoldableDevice();
    if (isFoldable && kDebugMode) {
      print('   📱 Foldable device detected');
    }

    if (kDebugMode) {
      print('✅ Device workarounds applied');
    }
  }
}
