import 'package:todo_app/core/utils/date_range_utils.dart';

/// A todo item entity representing a task to be completed.
///
/// This is the core domain entity for todos, containing all the information
/// needed to represent a task including:
/// - Basic info (title, description, completion status)
/// - Time management (due date, notification time, recurrence)
/// - Location-based reminders (geofence support)
/// - Organization (category, position for sorting)
///
/// Example:
/// ```dart
/// final todo = Todo(
///   id: 1,
///   title: 'Buy groceries',
///   description: 'Milk, eggs, bread',
///   isCompleted: false,
///   createdAt: DateTime.now(),
///   dueDate: DateTime.now().add(Duration(days: 1)),
/// );
/// ```
class Todo {
  /// Unique identifier for the todo.
  final int id;

  /// The title/name of the todo task.
  final String title;

  /// Optional detailed description of the task.
  final String description;

  /// Whether the task has been completed.
  final bool isCompleted;

  /// The ID of the category this todo belongs to, if any.
  final int? categoryId;

  /// When the todo was created.
  final DateTime createdAt;

  /// When the todo was marked as completed, if applicable.
  final DateTime? completedAt;

  /// The due date for the task, if set.
  final DateTime? dueDate;

  /// When to send a notification reminder, if set.
  final DateTime? notificationTime;

  /// RRULE format recurrence rule (e.g., "FREQ=DAILY;INTERVAL=1").
  ///
  /// Uses the iCalendar RRULE specification for defining repeating patterns.
  final String? recurrenceRule;

  /// Reference to the parent recurring todo that generated this instance.
  ///
  /// If set, this todo is an instance of a recurring todo series.
  final int? parentRecurringTodoId;

  /// Number of times the notification has been snoozed.
  final int snoozeCount;

  /// When the notification was last snoozed.
  final DateTime? lastSnoozeTime;

  /// Latitude for location-based notification geofence.
  final double? locationLatitude;

  /// Longitude for location-based notification geofence.
  final double? locationLongitude;

  /// Human-readable location name (e.g., "Home", "Office").
  final String? locationName;

  /// Geofence radius in meters for location-based notifications (default: 100m).
  final double? locationRadius;

  /// Order position for drag-and-drop sorting within a category.
  final int position;

  /// Notification priority level: low, medium, high.
  final String priority;

  /// 범위 일정의 시작일. `null` 이면 하루짜리 일정이다.
  ///
  /// `null`  → 하루짜리. [dueDate] 가 그 날이다. **기존 동작과 완전히 동일하다.**
  /// non-null → 범위. [startDate] ~ [dueDate] (양끝 포함).
  ///
  /// 종료일을 따로 두지 않고 [dueDate] 를 재해석한다. `dueDate` 가 25개 파일
  /// 255곳에 퍼져 있어 새 필드를 하나 더 만들면 어느 쪽이 진짜인지 혼란이 생긴다.
  final DateTime? startDate;

  /// Google Calendar 이벤트 ID.
  ///
  /// 이 할 일을 Google Calendar에 등록하면 그 이벤트 ID를 여기에 보관한다.
  /// 다음 동기화 때 값이 있으면 새로 만들지 않고 기존 이벤트를 갱신하므로
  /// 같은 일정이 중복 등록되지 않는다.
  final String? googleEventId;

  /// Creates a new [Todo] instance.
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.categoryId,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
    this.notificationTime,
    this.recurrenceRule,
    this.parentRecurringTodoId,
    this.snoozeCount = 0,
    this.lastSnoozeTime,
    this.locationLatitude,
    this.locationLongitude,
    this.locationName,
    this.locationRadius,
    this.position = 0,
    this.priority = 'medium',
    this.googleEventId,
    this.startDate,
  });

  /// Creates a copy of this todo with the given fields replaced.
  /// 여러 날에 걸친 범위 일정인가.
  ///
  /// [dueDate] 까지 있어야 범위가 성립한다. [startDate] 만 있고 [dueDate] 가 없으면
  /// 끝을 알 수 없으므로 범위로 보지 않는다.
  bool get isRanged => startDate != null && dueDate != null;

  /// 이 할 일이 [day] 에 걸쳐 있는가. **양끝을 포함**하고 로컬 날짜만 비교한다.
  ///
  /// 날짜 매칭을 여기 한 곳에 둔다. 예전에는 캘린더 프로바이더와 캘린더 화면에
  /// 같은 로직이 따로 구현돼 있어 한쪽만 고쳐질 위험이 있었다.
  ///
  /// `Duration` 을 쓰지 않는다. DST 경계에서 하루가 23시간이 되어 비교가 어긋난다.
  bool occursOn(DateTime day) {
    if (dueDate == null) return false;

    final target = DateTime(day.year, day.month, day.day);
    final end = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (startDate == null) {
      return target == end;
    }

    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    if (target.isBefore(start) || target.isAfter(end)) return false;

    // enumerateDays 와 같은 상한을 건다. 걸지 않으면 367일을 넘는 범위에서
    // 이 함수를 쓰는 화면과 enumerateDays 를 쓰는 화면이 서로 다른 날짜를 보여 준다.
    // 상한이 필요한 이유 자체가 폼을 거치지 않는 유입 경로(백업 복원, 대시보드
    // 직접 수정)이므로, 하필 그 상황에서 어긋나면 안 된다.
    final limit = DateTime(start.year, start.month, start.day + kMaxRangeDays);
    return !target.isAfter(limit);
  }

  /// "인자를 주지 않았다" 와 "null 을 주었다" 를 구분하기 위한 표식.
  ///
  /// 일반적인 `x ?? this.x` 패턴으로는 필드를 null 로 되돌릴 수 없다.
  /// 범위 해제(기간 토글 끄기)가 바로 그 경우다.
  static const _unset = Object();

  /// [startDate] 만 sentinel 을 쓴다.
  ///
  /// 다른 필드도 같은 한계가 있지만 기존 결함이므로 건드리지 않는다.
  /// [startDate] 는 해제 흐름을 명시적으로 설계했기 때문에 필요하다.
  ///
  /// 비용: [startDate] 매개변수 타입이 `Object?` 라 컴파일 타임 타입 검사가 없다.
  /// `copyWith(startDate: 'oops')` 가 컴파일되고 런타임에 터진다.
  ///
  /// **호출부는 `startDate:` 를 항상 명시적으로 넘겨야 한다.** 조건부로 생략하면
  /// sentinel 이 전달되어 옛 값이 그대로 살아남는다.
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? categoryId,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
    DateTime? notificationTime,
    String? recurrenceRule,
    int? parentRecurringTodoId,
    int? snoozeCount,
    DateTime? lastSnoozeTime,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    double? locationRadius,
    int? position,
    String? priority,
    String? googleEventId,
    Object? startDate = _unset,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      notificationTime: notificationTime ?? this.notificationTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentRecurringTodoId:
          parentRecurringTodoId ?? this.parentRecurringTodoId,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozeTime: lastSnoozeTime ?? this.lastSnoozeTime,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationName: locationName ?? this.locationName,
      locationRadius: locationRadius ?? this.locationRadius,
      position: position ?? this.position,
      priority: priority ?? this.priority,
      googleEventId: googleEventId ?? this.googleEventId,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
    );
  }
}
