// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocationSetting {

 int get id; String get userId; int get todoId; double get latitude; double get longitude; int get radius; String? get locationName; String get geofenceState;// outside/entering/inside/exiting
 DateTime? get triggeredAt;// 마지막 알림 시간 (중복 방지)
 DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of LocationSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationSettingCopyWith<LocationSetting> get copyWith => _$LocationSettingCopyWithImpl<LocationSetting>(this as LocationSetting, _$identity);

  /// Serializes this LocationSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.todoId, todoId) || other.todoId == todoId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.geofenceState, geofenceState) || other.geofenceState == geofenceState)&&(identical(other.triggeredAt, triggeredAt) || other.triggeredAt == triggeredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,todoId,latitude,longitude,radius,locationName,geofenceState,triggeredAt,createdAt,updatedAt);

@override
String toString() {
  return 'LocationSetting(id: $id, userId: $userId, todoId: $todoId, latitude: $latitude, longitude: $longitude, radius: $radius, locationName: $locationName, geofenceState: $geofenceState, triggeredAt: $triggeredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LocationSettingCopyWith<$Res>  {
  factory $LocationSettingCopyWith(LocationSetting value, $Res Function(LocationSetting) _then) = _$LocationSettingCopyWithImpl;
@useResult
$Res call({
 int id, String userId, int todoId, double latitude, double longitude, int radius, String? locationName, String geofenceState, DateTime? triggeredAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$LocationSettingCopyWithImpl<$Res>
    implements $LocationSettingCopyWith<$Res> {
  _$LocationSettingCopyWithImpl(this._self, this._then);

  final LocationSetting _self;
  final $Res Function(LocationSetting) _then;

/// Create a copy of LocationSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? todoId = null,Object? latitude = null,Object? longitude = null,Object? radius = null,Object? locationName = freezed,Object? geofenceState = null,Object? triggeredAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,todoId: null == todoId ? _self.todoId : todoId // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as int,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,geofenceState: null == geofenceState ? _self.geofenceState : geofenceState // ignore: cast_nullable_to_non_nullable
as String,triggeredAt: freezed == triggeredAt ? _self.triggeredAt : triggeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationSetting].
extension LocationSettingPatterns on LocationSetting {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationSetting() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationSetting value)  $default,){
final _that = this;
switch (_that) {
case _LocationSetting():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationSetting value)?  $default,){
final _that = this;
switch (_that) {
case _LocationSetting() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String userId,  int todoId,  double latitude,  double longitude,  int radius,  String? locationName,  String geofenceState,  DateTime? triggeredAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationSetting() when $default != null:
return $default(_that.id,_that.userId,_that.todoId,_that.latitude,_that.longitude,_that.radius,_that.locationName,_that.geofenceState,_that.triggeredAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String userId,  int todoId,  double latitude,  double longitude,  int radius,  String? locationName,  String geofenceState,  DateTime? triggeredAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LocationSetting():
return $default(_that.id,_that.userId,_that.todoId,_that.latitude,_that.longitude,_that.radius,_that.locationName,_that.geofenceState,_that.triggeredAt,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String userId,  int todoId,  double latitude,  double longitude,  int radius,  String? locationName,  String geofenceState,  DateTime? triggeredAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LocationSetting() when $default != null:
return $default(_that.id,_that.userId,_that.todoId,_that.latitude,_that.longitude,_that.radius,_that.locationName,_that.geofenceState,_that.triggeredAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocationSetting implements LocationSetting {
  const _LocationSetting({required this.id, required this.userId, required this.todoId, required this.latitude, required this.longitude, required this.radius, this.locationName, this.geofenceState = 'outside', this.triggeredAt, required this.createdAt, required this.updatedAt});
  factory _LocationSetting.fromJson(Map<String, dynamic> json) => _$LocationSettingFromJson(json);

@override final  int id;
@override final  String userId;
@override final  int todoId;
@override final  double latitude;
@override final  double longitude;
@override final  int radius;
@override final  String? locationName;
@override@JsonKey() final  String geofenceState;
// outside/entering/inside/exiting
@override final  DateTime? triggeredAt;
// 마지막 알림 시간 (중복 방지)
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of LocationSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationSettingCopyWith<_LocationSetting> get copyWith => __$LocationSettingCopyWithImpl<_LocationSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationSettingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationSetting&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.todoId, todoId) || other.todoId == todoId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.geofenceState, geofenceState) || other.geofenceState == geofenceState)&&(identical(other.triggeredAt, triggeredAt) || other.triggeredAt == triggeredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,todoId,latitude,longitude,radius,locationName,geofenceState,triggeredAt,createdAt,updatedAt);

@override
String toString() {
  return 'LocationSetting(id: $id, userId: $userId, todoId: $todoId, latitude: $latitude, longitude: $longitude, radius: $radius, locationName: $locationName, geofenceState: $geofenceState, triggeredAt: $triggeredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LocationSettingCopyWith<$Res> implements $LocationSettingCopyWith<$Res> {
  factory _$LocationSettingCopyWith(_LocationSetting value, $Res Function(_LocationSetting) _then) = __$LocationSettingCopyWithImpl;
@override @useResult
$Res call({
 int id, String userId, int todoId, double latitude, double longitude, int radius, String? locationName, String geofenceState, DateTime? triggeredAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$LocationSettingCopyWithImpl<$Res>
    implements _$LocationSettingCopyWith<$Res> {
  __$LocationSettingCopyWithImpl(this._self, this._then);

  final _LocationSetting _self;
  final $Res Function(_LocationSetting) _then;

/// Create a copy of LocationSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? todoId = null,Object? latitude = null,Object? longitude = null,Object? radius = null,Object? locationName = freezed,Object? geofenceState = null,Object? triggeredAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LocationSetting(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,todoId: null == todoId ? _self.todoId : todoId // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as int,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,geofenceState: null == geofenceState ? _self.geofenceState : geofenceState // ignore: cast_nullable_to_non_nullable
as String,triggeredAt: freezed == triggeredAt ? _self.triggeredAt : triggeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
