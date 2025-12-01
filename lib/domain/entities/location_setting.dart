/// A location-based reminder setting entity for geofence notifications.
///
/// LocationSetting enables users to receive todo reminders when they
/// enter or exit a specified geographic area. The geofence is defined
/// by coordinates (latitude/longitude) and a radius in meters.
///
/// Geofence states:
/// - `'outside'`: User is outside the geofence area (default)
/// - `'inside'`: User is within the geofence area
/// - `'triggered'`: Notification has been triggered
///
/// Example:
/// ```dart
/// final locationSetting = LocationSetting(
///   id: 1,
///   userId: 'user-uuid',
///   todoId: 42,
///   latitude: 37.5665,
///   longitude: 126.9780,
///   radius: 100,
///   locationName: 'Home',
///   geofenceState: 'outside',
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
///
/// See also:
/// - [Todo] for the associated todo entity
/// - [LocationRepository] for persistence operations
class LocationSetting {
  /// Unique identifier for the location setting.
  final int id;

  /// The UUID of the user who owns this setting.
  final String userId;

  /// The ID of the todo this location setting is associated with.
  final int todoId;

  /// Latitude coordinate of the geofence center.
  final double latitude;

  /// Longitude coordinate of the geofence center.
  final double longitude;

  /// Geofence radius in meters.
  final int radius;

  /// Human-readable name for the location (e.g., "Home", "Office").
  final String? locationName;

  /// Current geofence state: 'outside', 'inside', or 'triggered'.
  final String geofenceState;

  /// When the geofence notification was last triggered.
  final DateTime? triggeredAt;

  /// When this setting was created.
  final DateTime createdAt;

  /// When this setting was last updated.
  final DateTime updatedAt;

  /// Creates a new [LocationSetting] instance.
  const LocationSetting({
    required this.id,
    required this.userId,
    required this.todoId,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.locationName,
    this.geofenceState = 'outside',
    this.triggeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationSetting.fromJson(Map<String, dynamic> json) {
    return LocationSetting(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      todoId: json['todo_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: json['radius'] as int,
      locationName: json['location_name'] as String?,
      geofenceState: json['geofence_state'] as String? ?? 'outside',
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'todo_id': todoId,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'location_name': locationName,
      'geofence_state': geofenceState,
      'triggered_at': triggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LocationSetting copyWith({
    int? id,
    String? userId,
    int? todoId,
    double? latitude,
    double? longitude,
    int? radius,
    String? locationName,
    String? geofenceState,
    DateTime? triggeredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      todoId: todoId ?? this.todoId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      locationName: locationName ?? this.locationName,
      geofenceState: geofenceState ?? this.geofenceState,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSetting &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          todoId == other.todoId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radius == other.radius &&
          locationName == other.locationName &&
          geofenceState == other.geofenceState &&
          triggeredAt == other.triggeredAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      todoId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      radius.hashCode ^
      locationName.hashCode ^
      geofenceState.hashCode ^
      triggeredAt.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'LocationSetting(id: $id, userId: $userId, todoId: $todoId, latitude: $latitude, longitude: $longitude, radius: $radius, locationName: $locationName, geofenceState: $geofenceState, triggeredAt: $triggeredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
