import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:todo_app/core/services/location_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:workmanager/workmanager.dart';

/// GeofenceWorkManagerService handles background location monitoring
/// for location-based notifications using WorkManager
///
/// This service periodically checks if the user is within any geofence
/// and triggers notifications accordingly.
class GeofenceWorkManagerService {
  static const String _geofenceTaskName = 'geofence_check_task';
  static const String _geofenceTaskId = 'geofence_check_unique_id';

  /// Initialize the geofence monitoring service
  /// This should be called once when the app starts
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      AppLogger.info('✅ Geofence WorkManager initialized');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize Geofence WorkManager', error: e);
    }
  }

  /// Start periodic geofence monitoring
  /// Checks location every 15 minutes by default
  ///
  /// [intervalMinutes]: How often to check (minimum 15 minutes)
  static Future<void> startMonitoring({int intervalMinutes = 15}) async {
    try {
      // Cancel any existing task first
      await stopMonitoring();

      // Register periodic task
      await Workmanager().registerPeriodicTask(
        _geofenceTaskId,
        _geofenceTaskName,
        frequency: Duration(minutes: intervalMinutes < 15 ? 15 : intervalMinutes),
        inputData: {
          'task_type': 'geofence_check',
        },
      );

      AppLogger.info('✅ Geofence monitoring started (interval: ${intervalMinutes}min)');
    } catch (e) {
      AppLogger.error('❌ Failed to start geofence monitoring', error: e);
    }
  }

  /// Stop geofence monitoring
  static Future<void> stopMonitoring() async {
    try {
      await Workmanager().cancelByUniqueName(_geofenceTaskId);
      AppLogger.info('⏹️ Geofence monitoring stopped');
    } catch (e) {
      AppLogger.error('❌ Failed to stop geofence monitoring', error: e);
    }
  }

  /// Check if monitoring is currently active
  /// Note: WorkManager doesn't provide a direct way to check this,
  /// so we rely on the app state or SharedPreferences
  static Future<bool> isMonitoring() async {
    // This is a placeholder - in production, store state in SharedPreferences
    return false;
  }
}

/// Background callback for WorkManager
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      AppLogger.info('🔄 Geofence check task started: $task');

      // Initialize services in background isolate
      final locationService = LocationService();
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Get location permission status
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('⚠️ Location permission denied, skipping geofence check');
        return Future.value(true);
      }

      // Get current location
      final currentPosition = await locationService.getCurrentLocation();
      if (currentPosition == null) {
        AppLogger.warning('⚠️ Unable to get current location');
        return Future.value(true);
      }

      AppLogger.debug(
        '📍 Current location: ${currentPosition.latitude}, ${currentPosition.longitude}',
      );

      // Get all todos with location settings from database
      // IMPORTANT: Use shared AppDatabase instance instead of creating new one
      // Creating new instance in background isolate may fail to find database file
      AppDatabase? database;
      List<Todo> todos = [];
      try {
        database = AppDatabase();
        todos = await database.getTodosWithLocation();
      } catch (dbError) {
        AppLogger.error('❌ Failed to initialize database in background task', error: dbError);
        return Future.value(true); // Skip this check, will try again next time
      }

      if (todos.isEmpty) {
        AppLogger.debug('ℹ️ No location-based todos found');
        return Future.value(true);
      }

      AppLogger.info('📋 Checking ${todos.length} location-based todos');

      // Check each todo's geofence
      int triggeredCount = 0;
      for (final todo in todos) {
        // Skip if todo is already completed
        if (todo.isCompleted) continue;

        // Skip if no location is set
        if (todo.locationLatitude == null || todo.locationLongitude == null) {
          continue;
        }

        // Calculate distance to geofence
        final distance = locationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          todo.locationLatitude!,
          todo.locationLongitude!,
        );

        final radius = todo.locationRadius ?? 100.0; // Default 100m
        final isWithin = distance <= radius;

        if (isWithin) {
          triggeredCount++;

          // Trigger notification
          await notificationService.showLocationNotification(
            id: todo.id,
            title: todo.title,
            body: todo.locationName ??
                  'You are near ${todo.locationName ?? "your destination"}',
            distance: distance,
          );

          AppLogger.info(
            '🔔 Triggered notification for "${todo.title}" (distance: ${distance.toStringAsFixed(0)}m)',
          );
        } else {
          AppLogger.debug(
            '📍 "${todo.title}": ${distance.toStringAsFixed(0)}m away (radius: ${radius}m)',
          );
        }
      }

      if (triggeredCount > 0) {
        AppLogger.info('✅ Triggered $triggeredCount location notifications');
      } else {
        AppLogger.debug('ℹ️ No geofences triggered');
      }

      // Close database
      await database.close();

      return Future.value(true);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error in geofence check task',
        error: e,
        stackTrace: stackTrace,
      );
      return Future.value(false);
    }
  });
}
