import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/location_setting.dart';

/// Abstract repository interface for location-based reminder operations.
///
/// Defines the contract for geofence location setting persistence.
/// Location settings enable users to receive todo reminders based on
/// their geographic location (entering or exiting defined areas).
///
/// Implementations:
/// - [SupabaseLocationRepository] for remote Supabase operations
///
/// Geofence states:
/// - `'outside'`: User is outside the geofence area
/// - `'entering'`: User is entering the geofence area
/// - `'inside'`: User is inside the geofence area
/// - `'exiting'`: User is exiting the geofence area
///
/// See also:
/// - [LocationSetting] for the entity this repository manages
/// - [Todo] for the associated todo entity
abstract class LocationRepository {
  /// Retrieves the location setting for a specific todo.
  ///
  /// [todoId] is the ID of the associated todo.
  /// Returns null if no location setting exists for this todo.
  Future<Either<Failure, LocationSetting?>> getLocationSetting(int todoId);

  /// Retrieves all location settings for the current user.
  ///
  /// Returns all geofence configurations regardless of state.
  Future<Either<Failure, List<LocationSetting>>> getUserLocationSettings();

  /// Retrieves only active location settings.
  ///
  /// Active settings are those with state 'inside' or 'entering',
  /// indicating the user is near or within the geofence area.
  Future<Either<Failure, List<LocationSetting>>> getActiveLocationSettings();

  /// Creates a new location setting for a todo.
  ///
  /// Parameters:
  /// - [todoId]: The ID of the associated todo
  /// - [latitude]: Latitude coordinate of geofence center
  /// - [longitude]: Longitude coordinate of geofence center
  /// - [radius]: Geofence radius in meters
  /// - [locationName]: Optional human-readable name (e.g., "Home")
  ///
  /// Returns [Right] with the new setting's ID on success.
  Future<Either<Failure, int>> createLocationSetting(
    int todoId,
    double latitude,
    double longitude,
    int radius, {
    String? locationName,
  });

  /// Updates an existing location setting.
  ///
  /// [setting] contains the updated location setting entity.
  Future<Either<Failure, Unit>> updateLocationSetting(LocationSetting setting);

  /// Deletes a location setting by its ID.
  Future<Either<Failure, Unit>> deleteLocationSetting(int id);

  /// Updates the geofence state for a location setting.
  ///
  /// Parameters:
  /// - [id]: The location setting ID
  /// - [newState]: New state ('outside', 'entering', 'inside', 'exiting')
  /// - [shouldTriggerNotification]: Whether to send a notification
  Future<Either<Failure, Unit>> updateGeofenceState(
    int id,
    String newState, {
    bool shouldTriggerNotification = false,
  });

  /// Updates the last notification trigger time.
  ///
  /// Used to prevent duplicate notifications by tracking
  /// when the last geofence notification was sent.
  Future<Either<Failure, Unit>> updateTriggeredAt(
    int id,
    DateTime triggeredTime,
  );
}
