import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/core/services/geofence_workmanager_service.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Battery state levels for adaptive geofencing
enum BatteryState {
  critical, // ≤ 10%: Geofencing disabled
  low,      // 10-30%: 30min interval
  medium,   // 30-80%: 15min interval (default)
  high,     // > 80%: 10min interval
}

/// BatteryOptimizationService handles adaptive geofencing intervals
/// based on device battery level to minimize power consumption
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();

  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  final Battery _battery = Battery();
  late BatteryState _currentBatteryState;
  int _currentIntervalMinutes = 15;

  /// Check battery level and return appropriate state
  BatteryState _getBatteryStateFromLevel(int level) {
    if (level <= 10) {
      return BatteryState.critical;
    } else if (level <= 30) {
      return BatteryState.low;
    } else if (level <= 80) {
      return BatteryState.medium;
    } else {
      return BatteryState.high;
    }
  }

  /// Get recommended check interval based on battery state
  int _getIntervalForBatteryState(BatteryState state) {
    return switch (state) {
      BatteryState.critical => 0, // Disabled
      BatteryState.low => 30, // 30 minutes
      BatteryState.medium => 15, // 15 minutes (default)
      BatteryState.high => 10, // 10 minutes
    };
  }

  /// Get battery level (0-100)
  Future<int> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (kDebugMode) {
        print('🔋 Battery level: $level%');
      }
      return level;
    } catch (e) {
      AppLogger.error('❌ Failed to get battery level', error: e);
      return 50; // Default to medium
    }
  }

  /// Initialize battery monitoring
  Future<void> initialize() async {
    try {
      final level = await getBatteryLevel();
      _currentBatteryState = _getBatteryStateFromLevel(level);
      _currentIntervalMinutes =
          _getIntervalForBatteryState(_currentBatteryState);

      AppLogger.info(
        '✅ Battery optimization initialized: ${_currentBatteryState.name} (interval: ${_currentIntervalMinutes}min)',
      );

      // Start listening to battery state changes
      _startBatteryStateListener();
    } catch (e) {
      AppLogger.error('❌ Failed to initialize battery optimization', error: e);
    }
  }

  /// Start listening to battery state changes
  void _startBatteryStateListener() {
    _battery.onBatteryStateChanged.listen((state) async {
      final level = await getBatteryLevel();
      final newBatteryState = _getBatteryStateFromLevel(level);

      if (newBatteryState != _currentBatteryState) {
        _currentBatteryState = newBatteryState;
        await _updateGeofenceInterval();
      }
    });
  }

  /// Update geofence check interval based on current battery state
  Future<void> _updateGeofenceInterval() async {
    try {
      final newInterval = _getIntervalForBatteryState(_currentBatteryState);
      _currentIntervalMinutes = newInterval;

      if (newInterval == 0) {
        // Critical battery: disable geofencing
        await GeofenceWorkManagerService.stopMonitoring();
        AppLogger.warning(
          '⚠️ Geofencing disabled due to critical battery level',
        );
      } else {
        // Update monitoring interval
        await GeofenceWorkManagerService.startMonitoring(
          intervalMinutes: newInterval,
        );
        AppLogger.info(
          '🔄 Geofence interval updated: ${_currentBatteryState.name} → ${newInterval}min',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Failed to update geofence interval', error: e);
    }
  }

  /// Get current battery state
  BatteryState getCurrentBatteryState() => _currentBatteryState;

  /// Get current geofence check interval
  int getCurrentIntervalMinutes() => _currentIntervalMinutes;

  /// Manually trigger battery check and update interval
  Future<void> checkAndOptimize() async {
    try {
      final level = await getBatteryLevel();
      final newState = _getBatteryStateFromLevel(level);

      if (newState != _currentBatteryState) {
        _currentBatteryState = newState;
        await _updateGeofenceInterval();
      }

      AppLogger.debug(
        '✅ Battery optimization check completed: ${_currentBatteryState.name}',
      );
    } catch (e) {
      AppLogger.error('❌ Failed to check and optimize battery', error: e);
    }
  }

  /// Format battery state to human-readable string
  String formatBatteryState(BatteryState state) {
    return switch (state) {
      BatteryState.critical => '🔴 Critical (≤10%)',
      BatteryState.low => '🟠 Low (10-30%)',
      BatteryState.medium => '🟡 Medium (30-80%)',
      BatteryState.high => '🟢 High (>80%)',
    };
  }

  /// Check if app is ignoring battery optimizations (Android only)
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // iOS doesn't have this limitation
    }

    try {
      const methodChannel = MethodChannel('com.example.todo_app/battery');
      final result = await methodChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.debug('Battery optimization check failed: $e');
      return false;
    }
  }

  /// Request battery optimization whitelist (Android only)
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return; // iOS doesn't need this
    }

    try {
      const methodChannel = MethodChannel('com.example.todo_app/battery');
      await methodChannel.invokeMethod<void>(
        'requestIgnoreBatteryOptimizations',
      );
      AppLogger.info('Battery optimization request sent');
    } catch (e) {
      AppLogger.error('Failed to request battery optimization whitelist', error: e);
    }
  }
}
