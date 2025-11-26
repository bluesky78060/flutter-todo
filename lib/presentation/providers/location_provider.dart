import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/datasources/remote/supabase_location_datasource.dart';
import 'package:todo_app/data/repositories/supabase_location_repository.dart';
import 'package:todo_app/domain/entities/location_setting.dart';
import 'package:todo_app/domain/repositories/location_repository.dart';

/// Supabase 클라이언트 제공
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// LocationDataSource 제공
final locationDataSourceProvider =
    Provider<SupabaseLocationDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseLocationDataSource(client);
});

/// LocationRepository 제공
final locationRepositoryProvider =
    Provider<LocationRepository>((ref) {
  final dataSource = ref.watch(locationDataSourceProvider);
  return SupabaseLocationRepository(dataSource);
});

/// 특정 Todo의 위치 설정 조회
final locationSettingProvider =
    FutureProvider.family<LocationSetting?, int>((ref, todoId) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getLocationSetting(todoId);
  return result.fold((l) => null, (r) => r);
});

/// 사용자의 모든 위치 설정 조회
final userLocationSettingsProvider =
    FutureProvider<List<LocationSetting>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getUserLocationSettings();
  return result.fold((l) => [], (r) => r);
});

/// 활성 위치 설정 조회 (inside/entering)
final activeLocationSettingsProvider =
    FutureProvider<List<LocationSetting>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  final result = await repository.getActiveLocationSettings();
  return result.fold((l) => [], (r) => r);
});

/// 위치 설정 생성 비동기 작업
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

/// 위치 설정 수정 비동기 작업
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

/// 위치 설정 삭제 비동기 작업
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

/// Geofence 상태 업데이트
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

/// 마지막 알림 시간 업데이트
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

// ===== 헬퍼 클래스 =====

/// 위치 설정 생성 입력값
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

/// Geofence 상태 업데이트 입력값
class GeofenceStateUpdate {
  final int id;
  final String newState; // outside/entering/inside/exiting

  GeofenceStateUpdate({
    required this.id,
    required this.newState,
  });
}

/// 마지막 알림 시간 업데이트 입력값
class TriggeredAtUpdate {
  final int id;
  final DateTime triggeredTime;

  TriggeredAtUpdate({
    required this.id,
    required this.triggeredTime,
  });
}
