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

  /// Generate calendar data from todos (filtered to current month)
  static CalendarData fromTodos(
    List<Todo> todos,
    DateTime month,
  ) {
    final Map<int, int> dayTaskCounts = {};
    final Set<int> daysWithTasks = {};
    final Set<int> completedDays = {};

    // Filter todos for the current month only
    final currentYear = month.year;
    final currentMonth = month.month;

    for (final todo in todos) {
      final dueDate = todo.dueDate;
      if (dueDate != null &&
          dueDate.year == currentYear &&
          dueDate.month == currentMonth) {
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

  /// Generate todo data from todos (shows only today's pending todos for widget)
  static TodoListData fromTodos(List<Todo> todos) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // For widget: show only today's pending (not completed) todos
    // Include: 1) todos with dueDate today, 2) todos without dueDate but created today
    final pendingTodos = todos.where((todo) {
      if (todo.isCompleted) return false;

      // Case 1: Has due date - check if it's today
      if (todo.dueDate != null) {
        return todo.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
               todo.dueDate!.isBefore(todayEnd);
      }

      // Case 2: No due date - check if created today
      return todo.createdAt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
             todo.createdAt.isBefore(todayEnd);
    }).toList();

    // Sort by due date (earliest first), then by notification time, then by created date
    pendingTodos.sort((a, b) {
      // First sort by due date (tasks with due date first)
      final aDue = a.dueDate;
      final bDue = b.dueDate;

      if (aDue != null && bDue != null) {
        final cmp = aDue.compareTo(bDue);
        if (cmp != 0) return cmp;
      } else if (aDue != null) {
        return -1; // a has due date, b doesn't -> a first
      } else if (bDue != null) {
        return 1;  // b has due date, a doesn't -> b first
      }

      // Then by notification time
      if (a.notificationTime != null && b.notificationTime != null) {
        final cmp = a.notificationTime!.compareTo(b.notificationTime!);
        if (cmp != 0) return cmp;
      }

      // Finally by created date
      return a.createdAt.compareTo(b.createdAt);
    });

    final completedCount = todos.where((t) => t.isCompleted).length;
    final pendingCount = pendingTodos.length;

    return TodoListData(
      date: today,
      todos: pendingTodos,
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
