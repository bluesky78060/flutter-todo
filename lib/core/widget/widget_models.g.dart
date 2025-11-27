// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarData _$CalendarDataFromJson(Map<String, dynamic> json) =>
    _CalendarData(
      month: DateTime.parse(json['month'] as String),
      dayTaskCounts: (json['dayTaskCounts'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
      daysWithTasks: (json['daysWithTasks'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      completedDays: (json['completedDays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$CalendarDataToJson(_CalendarData instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'dayTaskCounts': instance.dayTaskCounts.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'daysWithTasks': instance.daysWithTasks,
      'completedDays': instance.completedDays,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

_WidgetConfig _$WidgetConfigFromJson(Map<String, dynamic> json) =>
    _WidgetConfig(
      viewType: $enumDecode(_$WidgetViewTypeEnumMap, json['viewType']),
      isEnabled: json['isEnabled'] as bool,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$WidgetConfigToJson(_WidgetConfig instance) =>
    <String, dynamic>{
      'viewType': _$WidgetViewTypeEnumMap[instance.viewType]!,
      'isEnabled': instance.isEnabled,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

const _$WidgetViewTypeEnumMap = {
  WidgetViewType.calendar: 'calendar',
  WidgetViewType.today: 'today',
};
