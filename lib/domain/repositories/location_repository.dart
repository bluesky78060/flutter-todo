import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/location_setting.dart';

abstract class LocationRepository {
  /// 특정 Todo의 위치 설정 조회
  Future<Either<Failure, LocationSetting?>> getLocationSetting(int todoId);

  /// 사용자의 모든 위치 설정 조회
  Future<Either<Failure, List<LocationSetting>>> getUserLocationSettings();

  /// 활성 위치 설정만 조회 (inside/entering 상태)
  Future<Either<Failure, List<LocationSetting>>> getActiveLocationSettings();

  /// 위치 설정 생성
  Future<Either<Failure, int>> createLocationSetting(
    int todoId,
    double latitude,
    double longitude,
    int radius, {
    String? locationName,
  });

  /// 위치 설정 수정
  Future<Either<Failure, Unit>> updateLocationSetting(LocationSetting setting);

  /// 위치 설정 삭제
  Future<Either<Failure, Unit>> deleteLocationSetting(int id);

  /// Geofence 상태 업데이트 (outside/entering/inside/exiting)
  Future<Either<Failure, Unit>> updateGeofenceState(
    int id,
    String newState, {
    bool shouldTriggerNotification = false,
  });

  /// 마지막 알림 시간 업데이트 (중복 알림 방지)
  Future<Either<Failure, Unit>> updateTriggeredAt(
    int id,
    DateTime triggeredTime,
  );
}
