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
  final int? snoozeCount; // Number of times snoozed
  final DateTime? lastSnoozeTime; // Last time the notification was snoozed

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
    this.snoozeCount,
    this.lastSnoozeTime,
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
    );
  }
}
