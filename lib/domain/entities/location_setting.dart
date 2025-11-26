import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_setting.freezed.dart';
part 'location_setting.g.dart';

@freezed
class LocationSetting with _$LocationSetting {
  const factory LocationSetting({
    required int id,
    required String userId,
    required int todoId,
    required double latitude,
    required double longitude,
    required int radius,
    String? locationName,
    @Default('outside') String geofenceState, // outside/entering/inside/exiting
    DateTime? triggeredAt, // 마지막 알림 시간 (중복 방지)
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LocationSetting;

  factory LocationSetting.fromJson(Map<String, dynamic> json) =>
      _$LocationSettingFromJson(json);
}
