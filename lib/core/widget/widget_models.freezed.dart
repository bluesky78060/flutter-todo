// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'widget_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarData {

 DateTime get month; Map<int, int> get dayTaskCounts; List<int> get daysWithTasks; List<int> get completedDays; DateTime get lastUpdated;
/// Create a copy of CalendarData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarDataCopyWith<CalendarData> get copyWith => _$CalendarDataCopyWithImpl<CalendarData>(this as CalendarData, _$identity);

  /// Serializes this CalendarData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarData&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other.dayTaskCounts, dayTaskCounts)&&const DeepCollectionEquality().equals(other.daysWithTasks, daysWithTasks)&&const DeepCollectionEquality().equals(other.completedDays, completedDays)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(dayTaskCounts),const DeepCollectionEquality().hash(daysWithTasks),const DeepCollectionEquality().hash(completedDays),lastUpdated);

@override
String toString() {
  return 'CalendarData(month: $month, dayTaskCounts: $dayTaskCounts, daysWithTasks: $daysWithTasks, completedDays: $completedDays, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $CalendarDataCopyWith<$Res>  {
  factory $CalendarDataCopyWith(CalendarData value, $Res Function(CalendarData) _then) = _$CalendarDataCopyWithImpl;
@useResult
$Res call({
 DateTime month, Map<int, int> dayTaskCounts, List<int> daysWithTasks, List<int> completedDays, DateTime lastUpdated
});




}
/// @nodoc
class _$CalendarDataCopyWithImpl<$Res>
    implements $CalendarDataCopyWith<$Res> {
  _$CalendarDataCopyWithImpl(this._self, this._then);

  final CalendarData _self;
  final $Res Function(CalendarData) _then;

/// Create a copy of CalendarData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? dayTaskCounts = null,Object? daysWithTasks = null,Object? completedDays = null,Object? lastUpdated = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime,dayTaskCounts: null == dayTaskCounts ? _self.dayTaskCounts : dayTaskCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,daysWithTasks: null == daysWithTasks ? _self.daysWithTasks : daysWithTasks // ignore: cast_nullable_to_non_nullable
as List<int>,completedDays: null == completedDays ? _self.completedDays : completedDays // ignore: cast_nullable_to_non_nullable
as List<int>,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarData].
extension CalendarDataPatterns on CalendarData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarData value)  $default,){
final _that = this;
switch (_that) {
case _CalendarData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarData value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime month,  Map<int, int> dayTaskCounts,  List<int> daysWithTasks,  List<int> completedDays,  DateTime lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarData() when $default != null:
return $default(_that.month,_that.dayTaskCounts,_that.daysWithTasks,_that.completedDays,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime month,  Map<int, int> dayTaskCounts,  List<int> daysWithTasks,  List<int> completedDays,  DateTime lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _CalendarData():
return $default(_that.month,_that.dayTaskCounts,_that.daysWithTasks,_that.completedDays,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime month,  Map<int, int> dayTaskCounts,  List<int> daysWithTasks,  List<int> completedDays,  DateTime lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _CalendarData() when $default != null:
return $default(_that.month,_that.dayTaskCounts,_that.daysWithTasks,_that.completedDays,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarData implements CalendarData {
  const _CalendarData({required this.month, required final  Map<int, int> dayTaskCounts, required final  List<int> daysWithTasks, required final  List<int> completedDays, required this.lastUpdated}): _dayTaskCounts = dayTaskCounts,_daysWithTasks = daysWithTasks,_completedDays = completedDays;
  factory _CalendarData.fromJson(Map<String, dynamic> json) => _$CalendarDataFromJson(json);

@override final  DateTime month;
 final  Map<int, int> _dayTaskCounts;
@override Map<int, int> get dayTaskCounts {
  if (_dayTaskCounts is EqualUnmodifiableMapView) return _dayTaskCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dayTaskCounts);
}

 final  List<int> _daysWithTasks;
@override List<int> get daysWithTasks {
  if (_daysWithTasks is EqualUnmodifiableListView) return _daysWithTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysWithTasks);
}

 final  List<int> _completedDays;
@override List<int> get completedDays {
  if (_completedDays is EqualUnmodifiableListView) return _completedDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completedDays);
}

@override final  DateTime lastUpdated;

/// Create a copy of CalendarData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarDataCopyWith<_CalendarData> get copyWith => __$CalendarDataCopyWithImpl<_CalendarData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarData&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other._dayTaskCounts, _dayTaskCounts)&&const DeepCollectionEquality().equals(other._daysWithTasks, _daysWithTasks)&&const DeepCollectionEquality().equals(other._completedDays, _completedDays)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,const DeepCollectionEquality().hash(_dayTaskCounts),const DeepCollectionEquality().hash(_daysWithTasks),const DeepCollectionEquality().hash(_completedDays),lastUpdated);

@override
String toString() {
  return 'CalendarData(month: $month, dayTaskCounts: $dayTaskCounts, daysWithTasks: $daysWithTasks, completedDays: $completedDays, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$CalendarDataCopyWith<$Res> implements $CalendarDataCopyWith<$Res> {
  factory _$CalendarDataCopyWith(_CalendarData value, $Res Function(_CalendarData) _then) = __$CalendarDataCopyWithImpl;
@override @useResult
$Res call({
 DateTime month, Map<int, int> dayTaskCounts, List<int> daysWithTasks, List<int> completedDays, DateTime lastUpdated
});




}
/// @nodoc
class __$CalendarDataCopyWithImpl<$Res>
    implements _$CalendarDataCopyWith<$Res> {
  __$CalendarDataCopyWithImpl(this._self, this._then);

  final _CalendarData _self;
  final $Res Function(_CalendarData) _then;

/// Create a copy of CalendarData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? dayTaskCounts = null,Object? daysWithTasks = null,Object? completedDays = null,Object? lastUpdated = null,}) {
  return _then(_CalendarData(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime,dayTaskCounts: null == dayTaskCounts ? _self._dayTaskCounts : dayTaskCounts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,daysWithTasks: null == daysWithTasks ? _self._daysWithTasks : daysWithTasks // ignore: cast_nullable_to_non_nullable
as List<int>,completedDays: null == completedDays ? _self._completedDays : completedDays // ignore: cast_nullable_to_non_nullable
as List<int>,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$TodoListData {

 DateTime get date; List<TodoEntity> get todos; int get completedCount; int get pendingCount; DateTime get lastUpdated;
/// Create a copy of TodoListData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodoListDataCopyWith<TodoListData> get copyWith => _$TodoListDataCopyWithImpl<TodoListData>(this as TodoListData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodoListData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.todos, todos)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(todos),completedCount,pendingCount,lastUpdated);

@override
String toString() {
  return 'TodoListData(date: $date, todos: $todos, completedCount: $completedCount, pendingCount: $pendingCount, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $TodoListDataCopyWith<$Res>  {
  factory $TodoListDataCopyWith(TodoListData value, $Res Function(TodoListData) _then) = _$TodoListDataCopyWithImpl;
@useResult
$Res call({
 DateTime date, List<TodoEntity> todos, int completedCount, int pendingCount, DateTime lastUpdated
});




}
/// @nodoc
class _$TodoListDataCopyWithImpl<$Res>
    implements $TodoListDataCopyWith<$Res> {
  _$TodoListDataCopyWithImpl(this._self, this._then);

  final TodoListData _self;
  final $Res Function(TodoListData) _then;

/// Create a copy of TodoListData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? todos = null,Object? completedCount = null,Object? pendingCount = null,Object? lastUpdated = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,todos: null == todos ? _self.todos : todos // ignore: cast_nullable_to_non_nullable
as List<TodoEntity>,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TodoListData].
extension TodoListDataPatterns on TodoListData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodoListData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodoListData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodoListData value)  $default,){
final _that = this;
switch (_that) {
case _TodoListData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodoListData value)?  $default,){
final _that = this;
switch (_that) {
case _TodoListData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  List<TodoEntity> todos,  int completedCount,  int pendingCount,  DateTime lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodoListData() when $default != null:
return $default(_that.date,_that.todos,_that.completedCount,_that.pendingCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  List<TodoEntity> todos,  int completedCount,  int pendingCount,  DateTime lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _TodoListData():
return $default(_that.date,_that.todos,_that.completedCount,_that.pendingCount,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  List<TodoEntity> todos,  int completedCount,  int pendingCount,  DateTime lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _TodoListData() when $default != null:
return $default(_that.date,_that.todos,_that.completedCount,_that.pendingCount,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc


class _TodoListData extends TodoListData {
  const _TodoListData({required this.date, required final  List<TodoEntity> todos, required this.completedCount, required this.pendingCount, required this.lastUpdated}): _todos = todos,super._();
  

@override final  DateTime date;
 final  List<TodoEntity> _todos;
@override List<TodoEntity> get todos {
  if (_todos is EqualUnmodifiableListView) return _todos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_todos);
}

@override final  int completedCount;
@override final  int pendingCount;
@override final  DateTime lastUpdated;

/// Create a copy of TodoListData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodoListDataCopyWith<_TodoListData> get copyWith => __$TodoListDataCopyWithImpl<_TodoListData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodoListData&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._todos, _todos)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_todos),completedCount,pendingCount,lastUpdated);

@override
String toString() {
  return 'TodoListData(date: $date, todos: $todos, completedCount: $completedCount, pendingCount: $pendingCount, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$TodoListDataCopyWith<$Res> implements $TodoListDataCopyWith<$Res> {
  factory _$TodoListDataCopyWith(_TodoListData value, $Res Function(_TodoListData) _then) = __$TodoListDataCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, List<TodoEntity> todos, int completedCount, int pendingCount, DateTime lastUpdated
});




}
/// @nodoc
class __$TodoListDataCopyWithImpl<$Res>
    implements _$TodoListDataCopyWith<$Res> {
  __$TodoListDataCopyWithImpl(this._self, this._then);

  final _TodoListData _self;
  final $Res Function(_TodoListData) _then;

/// Create a copy of TodoListData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? todos = null,Object? completedCount = null,Object? pendingCount = null,Object? lastUpdated = null,}) {
  return _then(_TodoListData(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,todos: null == todos ? _self._todos : todos // ignore: cast_nullable_to_non_nullable
as List<TodoEntity>,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$WidgetConfig {

 WidgetViewType get viewType; bool get isEnabled; DateTime get lastUpdated;
/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetConfigCopyWith<WidgetConfig> get copyWith => _$WidgetConfigCopyWithImpl<WidgetConfig>(this as WidgetConfig, _$identity);

  /// Serializes this WidgetConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetConfig&&(identical(other.viewType, viewType) || other.viewType == viewType)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewType,isEnabled,lastUpdated);

@override
String toString() {
  return 'WidgetConfig(viewType: $viewType, isEnabled: $isEnabled, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $WidgetConfigCopyWith<$Res>  {
  factory $WidgetConfigCopyWith(WidgetConfig value, $Res Function(WidgetConfig) _then) = _$WidgetConfigCopyWithImpl;
@useResult
$Res call({
 WidgetViewType viewType, bool isEnabled, DateTime lastUpdated
});




}
/// @nodoc
class _$WidgetConfigCopyWithImpl<$Res>
    implements $WidgetConfigCopyWith<$Res> {
  _$WidgetConfigCopyWithImpl(this._self, this._then);

  final WidgetConfig _self;
  final $Res Function(WidgetConfig) _then;

/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? viewType = null,Object? isEnabled = null,Object? lastUpdated = null,}) {
  return _then(_self.copyWith(
viewType: null == viewType ? _self.viewType : viewType // ignore: cast_nullable_to_non_nullable
as WidgetViewType,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WidgetConfig].
extension WidgetConfigPatterns on WidgetConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetConfig value)  $default,){
final _that = this;
switch (_that) {
case _WidgetConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WidgetViewType viewType,  bool isEnabled,  DateTime lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
return $default(_that.viewType,_that.isEnabled,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WidgetViewType viewType,  bool isEnabled,  DateTime lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _WidgetConfig():
return $default(_that.viewType,_that.isEnabled,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WidgetViewType viewType,  bool isEnabled,  DateTime lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
return $default(_that.viewType,_that.isEnabled,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetConfig extends WidgetConfig {
  const _WidgetConfig({required this.viewType, required this.isEnabled, required this.lastUpdated}): super._();
  factory _WidgetConfig.fromJson(Map<String, dynamic> json) => _$WidgetConfigFromJson(json);

@override final  WidgetViewType viewType;
@override final  bool isEnabled;
@override final  DateTime lastUpdated;

/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetConfigCopyWith<_WidgetConfig> get copyWith => __$WidgetConfigCopyWithImpl<_WidgetConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetConfig&&(identical(other.viewType, viewType) || other.viewType == viewType)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewType,isEnabled,lastUpdated);

@override
String toString() {
  return 'WidgetConfig(viewType: $viewType, isEnabled: $isEnabled, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$WidgetConfigCopyWith<$Res> implements $WidgetConfigCopyWith<$Res> {
  factory _$WidgetConfigCopyWith(_WidgetConfig value, $Res Function(_WidgetConfig) _then) = __$WidgetConfigCopyWithImpl;
@override @useResult
$Res call({
 WidgetViewType viewType, bool isEnabled, DateTime lastUpdated
});




}
/// @nodoc
class __$WidgetConfigCopyWithImpl<$Res>
    implements _$WidgetConfigCopyWith<$Res> {
  __$WidgetConfigCopyWithImpl(this._self, this._then);

  final _WidgetConfig _self;
  final $Res Function(_WidgetConfig) _then;

/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? viewType = null,Object? isEnabled = null,Object? lastUpdated = null,}) {
  return _then(_WidgetConfig(
viewType: null == viewType ? _self.viewType : viewType // ignore: cast_nullable_to_non_nullable
as WidgetViewType,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
