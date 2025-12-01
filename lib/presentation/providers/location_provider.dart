/// Location-based reminder state management providers using Riverpod.
///
/// Provides geofence location settings for location-triggered todo reminders.
/// Users can set up locations (home, office, etc.) to receive reminders
/// when entering or leaving specified areas.
///
/// Key providers:
/// - [locationRepositoryProvider]: Repository for location settings
/// - [locationSettingProvider]: Location setting for a specific todo
/// - [userLocationSettingsProvider]: All location settings for user
/// - [activeLocationSettingsProvider]: Currently triggered locations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/datasources/remote/supabase_location_datasource.dart';
import 'package:todo_app/data/repositories/supabase_location_repository.dart';
import 'package:todo_app/domain/entities/location_setting.dart';
import 'package:todo_app/domain/repositories/location_repository.dart';

/// Provides the Supabase client instance (local to this file).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the location data source for Supabase operations.
final locationDataSourceProvider =
    Provider<SupabaseLocationDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseLocationDataSource(client);
});

/// Provides the location repository for geofence operations.
final locationRepositoryProvider =
    Provider<LocationRepository>((ref) {
  final dataSource = ref.watch(locationDataSourceProvider);
  return SupabaseLocationRepository(dataSource);
});

/// Provides the location setting for a specific todo.
///
/// Returns null if no location setting exists for the todo.
final locationSettingProvider =
    FutureProvider.family<LocationSetting?, int>((ref, todoId) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getLocationSetting(todoId);
  return result.fold((l) => null, (r) => r);
});

/// Provides all location settings for the current user.
final userLocationSettingsProvider =
    FutureProvider<List<LocationSetting>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getUserLocationSettings();
  return result.fold((l) => [], (r) => r);
});

/// Provides active location settings (inside/entering states).
final activeLocationSettingsProvider =
    FutureProvider<List<LocationSetting>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getActiveLocationSettings();
  return result.fold((l) => [], (r) => r);
});

/// Creates a new location setting.
///
/// Returns the new setting's ID on success, null on failure.
final createLocationProvider =
    FutureProvider.family<int?, LocationSettingInput>((ref, input) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.createLocationSetting(
    input.todoId,
    input.latitude,
    input.longitude,
    input.radius,
    locationName: input.locationName,
  );

  // 성공 시 위치 설정 목록 새로고침
  if (result.isRight()) {
    ref.invalidate(userLocationSettingsProvider);
  }

  return result.fold((l) => null, (r) => r);
});

/// Updates an existing location setting.
///
/// Returns true on success, false on failure.
final updateLocationProvider =
    FutureProvider.family<bool, LocationSetting>((ref, setting) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.updateLocationSetting(setting);

  // 성공 시 위치 설정 목록 새로고침
  if (result.isRight()) {
    ref.invalidate(userLocationSettingsProvider);
    ref.invalidate(locationSettingProvider(setting.todoId));
  }

  return result.isRight();
});

/// Deletes a location setting by ID.
///
/// Returns true on success, false on failure.
final deleteLocationProvider =
    FutureProvider.family<bool, int>((ref, id) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.deleteLocationSetting(id);

  // 성공 시 위치 설정 목록 새로고침
  if (result.isRight()) {
    ref.invalidate(userLocationSettingsProvider);
  }

  return result.isRight();
});

/// Updates the geofence state for a location setting.
///
/// States: 'outside', 'entering', 'inside', 'exiting'.
final updateGeofenceStateProvider =
    FutureProvider.family<bool, GeofenceStateUpdate>((ref, update) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.updateGeofenceState(
    update.id,
    update.newState,
  );

  // 성공 시 위치 설정 목록 새로고침
  if (result.isRight()) {
    ref.invalidate(userLocationSettingsProvider);
  }

  return result.isRight();
});

/// Updates the last triggered time for duplicate prevention.
final updateTriggeredAtProvider =
    FutureProvider.family<bool, TriggeredAtUpdate>((ref, update) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.updateTriggeredAt(
    update.id,
    update.triggeredTime,
  );

  // 성공 시 위치 설정 목록 새로고침
  if (result.isRight()) {
    ref.invalidate(userLocationSettingsProvider);
  }

  return result.isRight();
});

// ===== Helper Classes =====

/// Input class for creating a new location setting.
class LocationSettingInput {
  final int todoId;
  final double latitude;
  final double longitude;
  final int radius;
  final String? locationName;

  LocationSettingInput({
    required this.todoId,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.locationName,
  });
}

/// Input class for updating geofence state.
class GeofenceStateUpdate {
  /// The location setting ID.
  final int id;
  /// New state: 'outside', 'entering', 'inside', or 'exiting'.
  final String newState;

  GeofenceStateUpdate({
    required this.id,
    required this.newState,
  });
}

/// Input class for updating the last triggered time.
class TriggeredAtUpdate {
  final int id;
  final DateTime triggeredTime;

  TriggeredAtUpdate({
    required this.id,
    required this.triggeredTime,
  });
}
