import 'package:todo_app/domain/entities/todo.dart';

/// Widget view type enum
enum WidgetViewType {
  calendar,
  today,
}

/// Calendar data model for widget display
class CalendarData {
  final DateTime month;
  final Map<int, int> dayTaskCounts;
  final List<int> daysWithTasks;
  final List<int> completedDays;
  final DateTime lastUpdated;

  const CalendarData({
    required this.month,
    required this.dayTaskCounts,
    required this.daysWithTasks,
    required this.completedDays,
    required this.lastUpdated,
  });

  /// Generate calendar data from todos
  static CalendarData fromTodos(
    List<Todo> todos,
    DateTime month,
  ) {
    final Map<int, int> dayTaskCounts = {};
    final Set<int> daysWithTasks = {};
    final Set<int> completedDays = {};

    for (final todo in todos) {
      final dueDate = todo.dueDate;
      if (dueDate != null) {
        final day = dueDate.day;
        dayTaskCounts[day] = (dayTaskCounts[day] ?? 0) + 1;
        daysWithTasks.add(day);

        if (todo.isCompleted) {
          completedDays.add(day);
        }
      }
    }

    return CalendarData(
      month: month,
      dayTaskCounts: dayTaskCounts,
      daysWithTasks: daysWithTasks.toList(),
      completedDays: completedDays.toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get task count for a specific day
  int getTaskCount(int day) => dayTaskCounts[day] ?? 0;

  /// Check if day has tasks
  bool hasTasksOnDay(int day) => daysWithTasks.contains(day);

  /// Check if day is fully completed
  bool isCompletedDay(int day) => completedDays.contains(day);

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'month': month.toIso8601String(),
        'dayTaskCounts': dayTaskCounts,
        'daysWithTasks': daysWithTasks,
        'completedDays': completedDays,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarData &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          dayTaskCounts == other.dayTaskCounts &&
          daysWithTasks == other.daysWithTasks &&
          completedDays == other.completedDays &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      month.hashCode ^
      dayTaskCounts.hashCode ^
      daysWithTasks.hashCode ^
      completedDays.hashCode ^
      lastUpdated.hashCode;
}

/// Today's todo list data model for widget display
class TodoListData {
  final DateTime date;
  final List<Todo> todos;
  final int completedCount;
  final int pendingCount;
  final DateTime lastUpdated;

  const TodoListData({
    required this.date,
    required this.todos,
    required this.completedCount,
    required this.pendingCount,
    required this.lastUpdated,
  });

  /// Generate today's todo data from todos
  static TodoListData fromTodos(List<Todo> todos) {
    final today = DateTime.now();
    final todaysTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null &&
          dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList();

    final completedCount = todaysTodos.where((t) => t.isCompleted).length;
    final pendingCount = todaysTodos.where((t) => !t.isCompleted).length;

    // Sort: pending first, then completed
    todaysTodos.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        // Both completed or both pending
        if (a.notificationTime != null && b.notificationTime != null) {
          return a.notificationTime!.compareTo(b.notificationTime!);
        }
        return a.createdAt.compareTo(b.createdAt);
      }
      return a.isCompleted ? 1 : -1;
    });

    return TodoListData(
      date: today,
      todos: todaysTodos,
      completedCount: completedCount,
      pendingCount: pendingCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get display todos (max 5 for widget)
  List<Todo> getDisplayTodos({int maxItems = 5}) {
    return todos.take(maxItems).toList();
  }

  /// Get formatted date string
  String getFormattedDate() {
    return '${date.month}/${date.day}';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'todos': todos.map((t) => {'title': t.title}).toList(),
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoListData &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          todos == other.todos &&
          completedCount == other.completedCount &&
          pendingCount == other.pendingCount &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      date.hashCode ^
      todos.hashCode ^
      completedCount.hashCode ^
      pendingCount.hashCode ^
      lastUpdated.hashCode;
}

/// Widget configuration model
class WidgetConfig {
  final WidgetViewType viewType;
  final bool isEnabled;
  final DateTime? lastUpdated;

  const WidgetConfig({
    required this.viewType,
    required this.isEnabled,
    required this.lastUpdated,
  });

  /// Default configuration
  static const WidgetConfig defaultConfig = WidgetConfig(
    viewType: WidgetViewType.today,
    isEnabled: true,
    lastUpdated: null,
  );

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'viewType': viewType.name,
        'isEnabled': isEnabled,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  /// Create from JSON
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      viewType: WidgetViewType.values.byName(json['viewType'] ?? 'today'),
      isEnabled: json['isEnabled'] ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetConfig &&
          runtimeType == other.runtimeType &&
          viewType == other.viewType &&
          isEnabled == other.isEnabled &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      viewType.hashCode ^ isEnabled.hashCode ^ lastUpdated.hashCode;
}
