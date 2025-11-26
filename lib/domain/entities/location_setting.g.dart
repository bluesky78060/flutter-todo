// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocationSetting _$LocationSettingFromJson(Map<String, dynamic> json) =>
    _LocationSetting(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      todoId: (json['todoId'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toInt(),
      locationName: json['locationName'] as String?,
      geofenceState: json['geofenceState'] as String? ?? 'outside',
      triggeredAt: json['triggeredAt'] == null
          ? null
          : DateTime.parse(json['triggeredAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LocationSettingToJson(_LocationSetting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'todoId': instance.todoId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'locationName': instance.locationName,
      'geofenceState': instance.geofenceState,
      'triggeredAt': instance.triggeredAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
