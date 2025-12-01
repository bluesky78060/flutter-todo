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
  });

  /// Creates a copy of this todo with the given fields replaced.
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
      parentRecurringTodoId: parentRecurringTodoId ?? this.parentRecurringTodoId,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozeTime: lastSnoozeTime ?? this.lastSnoozeTime,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationName: locationName ?? this.locationName,
      locationRadius: locationRadius ?? this.locationRadius,
      position: position ?? this.position,
    );
  }
}
