class Todo {
  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime? notificationTime;
  final String? recurrenceRule; // RRULE format (e.g., "FREQ=DAILY;INTERVAL=1")
  final int? parentRecurringTodoId; // Reference to parent recurring todo
  final int snoozeCount; // Number of times snoozed
  final DateTime? lastSnoozeTime; // Last time the notification was snoozed
  final double? locationLatitude; // Location-based notification latitude
  final double? locationLongitude; // Location-based notification longitude
  final String? locationName; // Human-readable location name (e.g., "Home", "Office")
  final double? locationRadius; // Geofence radius in meters (default: 100m)
  final int position; // Order position for drag and drop sorting (per category)

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
