import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const platform = MethodChannel('kr.bluesky.dodo/battery');

  /// Check if battery optimizations are disabled for this app
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb) return true;

    try {
      final bool result = await platform.invokeMethod('isIgnoringBatteryOptimizations');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to check battery optimization status: ${e.message}');
      }
      return false;
    }
  }

  /// Request to disable battery optimizations
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb) return true;

    try {
      final bool result = await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to request battery optimization: ${e.message}');
      }
      return false;
    }
  }
}
