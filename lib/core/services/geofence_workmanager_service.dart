import 'package:drift/drift.dart' hide Table;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/geofence_calculator.dart';
import 'package:todo_app/core/services/location_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/datasources/remote/supabase_location_datasource.dart';
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
  /// NOTE: WorkManager is initialized in WorkManagerNotificationService with unified dispatcher
  /// This method is kept for compatibility but does nothing
  static Future<void> initialize() async {
    // No-op: WorkManager is initialized in WorkManagerNotificationService
    // with the unified callbackDispatcher that handles both notifications and geofence
    AppLogger.info('ℹ️ Geofence service uses unified WorkManager dispatcher');
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

  /// Check geofences immediately (for testing or immediate notification)
  /// This runs the same logic as the background task but in the foreground
  static Future<void> checkNow() async {
    try {
      AppLogger.info('🔍 Manual geofence check triggered');

      final locationService = LocationService();
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Get location permission status
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('⚠️ Location permission denied, cannot check geofences');
        return;
      }

      // Get current location
      final currentPosition = await locationService.getCurrentLocation();
      if (currentPosition == null) {
        AppLogger.warning('⚠️ Unable to get current location');
        return;
      }

      AppLogger.debug(
        '📍 Current location: ${currentPosition.latitude}, ${currentPosition.longitude}',
      );

      // Get all todos with location settings from database
      final database = AppDatabase();
      final todos = await database.getTodosWithLocation();

      if (todos.isEmpty) {
        AppLogger.debug('ℹ️ No location-based todos found');
        await database.close();
        return;
      }

      AppLogger.info('📋 Checking ${todos.length} location-based todos');

      // Check each todo's geofence
      int triggeredCount = 0;
      int skippedCount = 0;

      for (final todo in todos) {
        // Skip if todo is already completed
        if (todo.isCompleted) continue;

        // Skip if no location is set
        if (todo.locationLatitude == null || todo.locationLongitude == null) {
          continue;
        }

        // Calculate accurate distance using Haversine formula
        final distance = GeofenceCalculator.calculateHaversineDistance(
          userLatitude: currentPosition.latitude,
          userLongitude: currentPosition.longitude,
          targetLatitude: todo.locationLatitude!,
          targetLongitude: todo.locationLongitude!,
        );

        final radius = todo.locationRadius ?? 100.0; // Default 100m
        final isWithin = distance <= radius;

        if (isWithin) {
          // Check for duplicate notification prevention (24-hour throttling)
          final lastTriggeredAt = todo.locationTriggeredAt;
          final now = DateTime.now();
          final shouldTrigger = lastTriggeredAt == null ||
              now.difference(lastTriggeredAt).inHours >= 24;

          if (shouldTrigger) {
            triggeredCount++;

            // Trigger notification
            await notificationService.showLocationNotification(
              id: todo.id,
              title: todo.title,
              body: todo.description.isNotEmpty
                  ? todo.description
                  : 'You are near ${todo.locationName ?? "your destination"}',
              distance: distance,
            );

            // Update locationTriggeredAt timestamp
            await database.update(database.todos).replace(
              todo.copyWith(locationTriggeredAt: Value(now)),
            );

            // Sync to Supabase if available
            try {
              if (Supabase.instance.client.auth.currentUser != null) {
                final dataSource = SupabaseLocationDataSource(
                  Supabase.instance.client,
                );
                await dataSource.updateTriggeredAt(todo.id, now);
              }
            } catch (e) {
              AppLogger.warning('⚠️ Failed to sync geofence state to Supabase', error: e);
            }

            AppLogger.info(
              '🔔 Triggered notification for "${todo.title}" (distance: ${distance.toStringAsFixed(0)}m)',
            );
          } else {
            skippedCount++;
            final hoursSinceLastTrigger = now.difference(lastTriggeredAt).inHours;
            AppLogger.debug(
              '⏱️ Skipped duplicate notification for "${todo.title}" (triggered ${hoursSinceLastTrigger}h ago)',
            );
          }
        } else {
          AppLogger.debug(
            '📍 "${todo.title}": ${distance.toStringAsFixed(0)}m away (radius: ${radius}m)',
          );
        }
      }

      if (triggeredCount > 0) {
        AppLogger.info('✅ Triggered $triggeredCount location notifications (skipped: $skippedCount)');
      } else if (skippedCount > 0) {
        AppLogger.debug('ℹ️ No new geofences triggered (skipped $skippedCount duplicates)');
      } else {
        AppLogger.debug('ℹ️ No geofences triggered');
      }

      // Close database
      await database.close();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error in manual geofence check',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// NOTE: The _callbackDispatcher has been moved to workmanager_notification_service.dart
/// as a unified dispatcher that handles both notifications and geofence checks.
/// This avoids WorkManager dispatcher conflicts where only one dispatcher can be registered.
